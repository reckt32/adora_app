import 'package:flutter/material.dart';
import '../models/location_data.dart';
import '../utils/date_formatter.dart';

// shows the current location with some nice formatting
class CurrentLocationWidget extends StatelessWidget {
  final LocationData? locationData;
  final bool isServiceRunning;
  
  const CurrentLocationWidget({
    Key? key,
    required this.locationData,
    required this.isServiceRunning,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // show different text based on whether we have location data
    String locationText = 'Unknown';
    
    if (locationData != null) {
      locationText = 'Lat: ${locationData!.latitude.toStringAsFixed(4)}, '
          'Long: ${locationData!.longitude.toStringAsFixed(4)}\n'
          'Last Update: ${DateFormatter.formatTimestamp(locationData!.timestamp)}';
    }
    
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
              locationText,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              isServiceRunning
                  ? 'Location tracking is active in background'
                  : 'Tracking stopped. Last known location displayed above.',
              style: TextStyle(
                  color: isServiceRunning ? Colors.green : Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}