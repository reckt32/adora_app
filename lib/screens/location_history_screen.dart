import 'dart:async';
import 'package:flutter/material.dart';
import '../models/location_data.dart';
import '../services/location_service.dart';
import '../widgets/location_history_widget.dart';
import '../widgets/tracking_button.dart';

// separate screen for viewing location history
class LocationHistoryScreen extends StatefulWidget {
  const LocationHistoryScreen({Key? key}) : super(key: key);

  @override
  State<LocationHistoryScreen> createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends State<LocationHistoryScreen> {
  final LocationService _locationService = LocationService();
  bool _isServiceRunning = false;
  List<LocationData> _locationHistory = [];
  bool _isHistoryLoading = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
    _loadLocationHistory();
    
    // set up refresh timer
    // probably don't need this but it's nice to have auto-refresh
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadLocationHistory();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // check if service is running
  Future<void> _checkServiceStatus() async {
    final isRunning = await _locationService.isRunning();
    setState(() {
      _isServiceRunning = isRunning;
    });
  }

  // load location history from storage
  Future<void> _loadLocationHistory() async {
    if (_isHistoryLoading) return;
    
    setState(() {
      _isHistoryLoading = true;
    });
    
    try {
      final history = await _locationService.getLocationHistory();
      
      setState(() {
        // limit to showing just 10 most recent for performance
        _locationHistory = history.take(10).toList();
        _isHistoryLoading = false;
      });
    } catch (e) {
      print('Oops, error loading history: $e');
      setState(() {
        _isHistoryLoading = false;
      });
    }
  }

  // toggle tracking on/off
  Future<void> _toggleService() async {
    if (!_isServiceRunning) {
      await _locationService.startTracking();
    } else {
      _locationService.stopTracking();
    }
    
    // short delay to allow service status to update
    Future.delayed(const Duration(seconds: 1), () async {
      await _checkServiceStatus();
      _loadLocationHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location History'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: LocationHistoryWidget(
                locationHistory: _locationHistory,
                isLoading: _isHistoryLoading,
                onRefresh: _loadLocationHistory,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: TrackingButton(
                isRunning: _isServiceRunning,
                onToggle: _toggleService,
              ),
            ),
          ],
        ),
      ),
    );
  }
}