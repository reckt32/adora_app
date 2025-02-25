import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
        AndroidNotificationChannel(
          'location_tracker',
          'Location Tracker',
          importance: Importance.high,
        ),
      );

  await service.configure(
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'location_tracker',
      foregroundServiceNotificationId: 888,
      initialNotificationTitle: 'Location Tracker',
      initialNotificationContent: 'Tracking your location...',
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

Future<void> logLocation(Position position) async {
  final prefs = await SharedPreferences.getInstance();

  // Get existing location history
  List<String> locationHistory = prefs.getStringList('location_history') ?? [];

  // Create new location entry
  final timestamp = DateTime.now().toIso8601String();
  final locationEntry = '$timestamp,${position.latitude},${position.longitude}';

  // Add new location to history (prepend to keep newest first)
  locationHistory.insert(0, locationEntry);

  // Limit history to 100 entries to prevent SharedPreferences from getting too large
  if (locationHistory.length > 100) {
    locationHistory = locationHistory.sublist(0, 100);
  }

  // Save updated history back to SharedPreferences
  await prefs.setStringList('location_history', locationHistory);
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  print('Background service started');

  // Create notification plugin instance for updates
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Start a periodic timer to log and update location every 30 seconds.
  Timer? timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Log the location information to SharedPreferences
      await logLocation(position);

      // Save current location in SharedPreferences for UI display
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_latitude', position.latitude);
      await prefs.setDouble('last_longitude', position.longitude);
      await prefs.setString('last_update', DateTime.now().toIso8601String());

      // Send location update to the UI
      service.invoke('location', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Update the notification with current location
      final locationText =
          'Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}';
      flutterLocalNotificationsPlugin.show(
        888, // Same ID as in service configuration
        'Current Location', // Changed title as requested
        locationText,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'location_tracker',
            'Location Tracker',
            importance: Importance.high,
            icon: 'ic_notification',
          ),
        ),
      );
    } catch (e) {
      print('Error getting location: $e');
      flutterLocalNotificationsPlugin.show(
        888,
        'Location Tracker',
        'Error getting location',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'location_tracker',
            'Location Tracker',
            importance: Importance.high,
          ),
        ),
      );
    }
  });

  // Listen for the 'stopService' command from the UI.
  service.on('stopService').listen((event) {
    timer.cancel(); // Cancel periodic updates.
    service.stopSelf(); // Stop the background service.
  });
}
