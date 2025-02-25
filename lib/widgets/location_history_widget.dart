import 'package:flutter/material.dart';
import '../models/location_data.dart';
import '../utils/date_formatter.dart';

// the widget that shows the location history as a scrollable list
class LocationHistoryWidget extends StatelessWidget {
  final List<LocationData> locationHistory;
  final bool isLoading;
  final VoidCallback onRefresh;
  
  const LocationHistoryWidget({
    Key? key,
    required this.locationHistory,
    required this.isLoading,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Location History',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Expanded(
          // show different UI based on loading state and if we have data
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : locationHistory.isEmpty
                  ? _buildEmptyState(context)
                  : _buildHistoryList(),
        ),
      ],
    );
  }

  // shows when we don't have any history data
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('No location history available'),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  // builds the list of location history entries
  Widget _buildHistoryList() {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: ListView.builder(
        itemCount: locationHistory.length,
        itemBuilder: (context, index) {
          final item = locationHistory[index];
          
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text('Lat: ${item.latitude.toStringAsFixed(4)}, Long: ${item.longitude.toStringAsFixed(4)}'),
              subtitle: Text(DateFormatter.formatTimestamp(item.timestamp)),
              leading: const Icon(Icons.location_on),
            ),
          );
        },
      ),
    );
  }
}