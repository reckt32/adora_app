import 'dart:async';
import 'package:flutter/material.dart';
import '../models/location_data.dart';
import '../services/location_service.dart';
import '../screens/location_history_screen.dart';
import '../widgets/current_location_widget.dart';
import '../widgets/tracking_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  bool _isServiceRunning = false;
  LocationData? _currentLocationData;
  Timer? _refreshTimer;
  late StreamSubscription _locationSubscription;

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
    _loadLastLocation();
    _setupLocationListener();

    // refresh the UI every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadLastLocation();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _locationSubscription.cancel();
    super.dispose();
  }

  // check if service is running to show correct UI
  Future<void> _checkServiceStatus() async {
    final isRunning = await _locationService.isRunning();
    setState(() {
      _isServiceRunning = isRunning;
    });
  }

  // load the most recently saved location
  Future<void> _loadLastLocation() async {
    final lastLocation = await _locationService.getLastLocation();
    if (lastLocation != null) {
      setState(() {
        _currentLocationData = lastLocation;
      });
    }
  }

  // listen for new location updates from service
  void _setupLocationListener() {
    _locationSubscription = _locationService.locationUpdates.listen((event) {
      if (event != null && mounted) {
        setState(() {
          _currentLocationData = LocationData(
            timestamp: event['timestamp'] ?? DateTime.now().toIso8601String(),
            latitude: event['latitude'] ?? 0.0,
            longitude: event['longitude'] ?? 0.0,
          );
        });
      }
    });
  }

  // toggle tracking on/off
  Future<void> _toggleService() async {
    if (!_isServiceRunning) {
      await _locationService.startTracking();
    } else {
      _locationService.stopTracking();
    }
    
    // give it a sec to update
    Future.delayed(const Duration(seconds: 1), () async {
      await _checkServiceStatus();
      _loadLastLocation();
    });
  }

  // open the history screen
  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationHistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _navigateToHistory,
            tooltip: 'View History',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: CurrentLocationWidget(
                locationData: _currentLocationData,
                isServiceRunning: _isServiceRunning,
              ),
            ),
            TrackingButton(
              isRunning: _isServiceRunning,
              onToggle: _toggleService,
            ),
          ],
        ),
      ),
    );
  }
}