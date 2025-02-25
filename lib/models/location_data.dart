

class LocationData {
  final String timestamp;
  final double latitude;
  final double longitude;
  
  LocationData({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
  });

  factory LocationData.fromString(String data) {
    final parts = data.split(',');
    if (parts.length >= 3) {
      return LocationData(
        timestamp: parts[0],
        latitude: double.parse(parts[1]),
        longitude: double.parse(parts[2]),
      );
    }
    // return dummy data if something's wrong
    // probably not the best way to handle this
    return LocationData(
      timestamp: DateTime.now().toIso8601String(),
      latitude: 0.0,
      longitude: 0.0,
    );
  }

  String toStorageString() {
    return '$timestamp,$latitude,$longitude';
  }
}