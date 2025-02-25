import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterBackgroundService _backgroundService = FlutterBackgroundService();
  bool _isServiceRunning = false;
  String _currentLocation = 'Unknown';
  Timer? _refreshTimer;
  bool _showHistory = false;
  List<LocationData> _locationHistory = [];
  bool _isHistoryLoading = false;

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
    _loadLastLocation();
    _setupLocationListener();

    // Refresh the UI every 10 seconds with the last known location.
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadLastLocation();
      if (_showHistory) {
        _loadLocationHistory();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkServiceStatus() async {
    final isRunning = await _backgroundService.isRunning();
    setState(() {
      _isServiceRunning = isRunning;
    });
  }

  Future<void> _loadLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('last_latitude');
    final lng = prefs.getDouble('last_longitude');
    final lastUpdate = prefs.getString('last_update');

    if (lat != null && lng != null && lastUpdate != null) {
      setState(() {
        final dateTime = DateTime.parse(lastUpdate);
        final formattedTime = '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
        
        _currentLocation = 'Lat: ${lat.toStringAsFixed(4)}, '
            'Long: ${lng.toStringAsFixed(4)}\n'
            'Last Update: $formattedTime';
      });
    }
  }

  void _setupLocationListener() {
    _backgroundService.on('location').listen((event) {
      if (event != null && mounted) {
        String formattedTime = 'Unknown';
        if (event['timestamp'] != null) {
          final dateTime = DateTime.parse(event['timestamp'].toString());
          formattedTime = '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
        }
        
        setState(() {
          _currentLocation = 'Lat: ${event['latitude']?.toStringAsFixed(4)}, '
              'Long: ${event['longitude']?.toStringAsFixed(4)}\n'
              'Last Update: $formattedTime';
        });
        
        if (_showHistory) {
          _loadLocationHistory();
        }
      }
    });
  }

  Future<void> _loadLocationHistory() async {
    if (_isHistoryLoading) return;
    
    setState(() {
      _isHistoryLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? historyList = prefs.getStringList('location_history');
      
      if (historyList != null && historyList.isNotEmpty) {
        final List<LocationData> parsedLocations = [];
        
        for (String entry in historyList) {
          final parts = entry.split(',');
          if (parts.length >= 3) {
            parsedLocations.add(
              LocationData(
                timestamp: parts[0],
                latitude: double.parse(parts[1]),
                longitude: double.parse(parts[2]),
              ),
            );
          }
        }
        
        // Take only the recent locations to display
        final recentLocations = parsedLocations.take(10).toList();
        
        setState(() {
          _locationHistory = recentLocations;
          _isHistoryLoading = false;
        });
      } else {
        setState(() {
          _locationHistory = [];
          _isHistoryLoading = false;
        });
      }
    } catch (e) {
      print('Error loading location history: $e');
      setState(() {
        _isHistoryLoading = false;
      });
    }
  }

  Future<bool> _handlePermissions() async {
    bool locationGranted = false;
    bool backgroundLocationGranted = false;

    final locationStatus = await Permission.location.request();
    locationGranted = locationStatus.isGranted;

    if (Platform.isAndroid) {
      final backgroundStatus = await Permission.locationAlways.request();
      backgroundLocationGranted = backgroundStatus.isGranted;
    } else {
      backgroundLocationGranted = true; 
    }

    final notificationStatus = await Permission.notification.request();

    return locationGranted &&
        backgroundLocationGranted &&
        notificationStatus.isGranted;
  }

  Future<void> _toggleService() async {
    if (!_isServiceRunning) {
      final permissionsGranted = await _handlePermissions();
      if (!permissionsGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Required permissions not granted')),
        );
        return;
      }
      await _backgroundService.startService();
    } else {
      // Stop tracking when service is running.
      _backgroundService.invoke('stopService');
    }
    // After toggling, update service status and refresh the location.
    Future.delayed(const Duration(seconds: 1), () async {
      await _checkServiceStatus();
      _loadLastLocation();
    });
  }

  String _formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _toggleHistoryView() {
    setState(() {
      _showHistory = !_showHistory;
    });
    
    if (_showHistory) {
      _loadLocationHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_showHistory ? Icons.location_on : Icons.history),
            onPressed: _toggleHistoryView,
            tooltip: _showHistory ? 'Show Current Location' : 'Show History',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _showHistory 
            ? _buildHistoryView()
            : _buildCurrentLocationView(),
      ),
    );
  }

  Widget _buildCurrentLocationView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Current Location',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _currentLocation,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _toggleService,
            icon: Icon(_isServiceRunning ? Icons.stop : Icons.play_arrow),
            label: Text(_isServiceRunning ? 'Stop Tracking' : 'Start Tracking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isServiceRunning ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              _isServiceRunning
                  ? 'Location tracking is active in background'
                  : 'Tracking stopped. Last known location displayed above.',
              style: TextStyle(
                  color: _isServiceRunning ? Colors.green : Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    return Column(
      children: [
        Text(
          'Location History',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _isHistoryLoading
              ? const Center(child: CircularProgressIndicator())
              : _locationHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('No location history available'),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: _loadLocationHistory,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadLocationHistory,
                      child: ListView.builder(
                        itemCount: _locationHistory.length,
                        itemBuilder: (context, index) {
                          final item = _locationHistory[index];
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text('Lat: ${item.latitude.toStringAsFixed(4)}, Long: ${item.longitude.toStringAsFixed(4)}'),
                              subtitle: Text(_formatTimestamp(item.timestamp)),
                              leading: const Icon(Icons.location_on),
                            ),
                          );
                        },
                      ),
                    ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ElevatedButton.icon(
            onPressed: _toggleService,
            icon: Icon(_isServiceRunning ? Icons.stop : Icons.play_arrow),
            label: Text(_isServiceRunning ? 'Stop Tracking' : 'Start Tracking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isServiceRunning ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class LocationData {
  final String timestamp;
  final double latitude;
  final double longitude;
  
  LocationData({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
  });
}