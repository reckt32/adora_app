import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../models/location_data.dart';

class LocationService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();
  static const int MAX_HISTORY_ENTRIES = 100;  // let's not fill up the storage too much
  
  static final LocationService _instance = LocationService._internal();
  
  factory LocationService() {
    return _instance;
  }
  
  LocationService._internal();

  // initialize the service when the app starts
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
        
    // android needs this channel thing for notifications
    // took me forever to figure this out tbh
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

    // configure the service for both platforms
    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'location_tracker',
        foregroundServiceNotificationId: 888,
        initialNotificationTitle: 'Location Tracker',
        initialNotificationContent: 'Tracking your location...',
      ),
    );
  }

  Future<bool> isRunning() async {
    return await _service.isRunning();
  }

  // start tracking
  Future<void> startTracking() async {
    final permissionsGranted = await _requestPermissions();
    if (!permissionsGranted) {
      return;
    }
    
    await _service.startService();
  }

  // stop tracking
  void stopTracking() {
    _service.invoke('stopService');
  }

  // handle permissions
  Future<bool> _requestPermissions() async {
    bool locationGranted = false;
    bool backgroundLocationGranted = false;

    // basic location permission
    final locationStatus = await Permission.location.request();
    locationGranted = locationStatus.isGranted;

    // android needs special "always" permission for background
    if (Platform.isAndroid) {
      final backgroundStatus = await Permission.locationAlways.request();
      backgroundLocationGranted = backgroundStatus.isGranted;
    } else {
      // iOS is less strict about this particular thing
      backgroundLocationGranted = true; 
    }

    // need notification permission too for updates
    final notificationStatus = await Permission.notification.request();

    return locationGranted &&
        backgroundLocationGranted &&
        notificationStatus.isGranted;
  }

  //  listen for location updates in the UI
  Stream<dynamic> get locationUpdates {
    return _service.on('location');
  }

  // get most recent location from storage
  Future<LocationData?> getLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('last_latitude');
    final lng = prefs.getDouble('last_longitude');
    final lastUpdate = prefs.getString('last_update');

    if (lat != null && lng != null && lastUpdate != null) {
      return LocationData(
        timestamp: lastUpdate,
        latitude: lat,
        longitude: lng,
      );
    }
    return null;  // no location saved yet
  }

  // grab the location history from storage
  Future<List<LocationData>> getLocationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? historyList = prefs.getStringList('location_history');
    
    if (historyList != null && historyList.isNotEmpty) {
      try {
        // convert strings back to LocationData objects
        return historyList.map((entry) => LocationData.fromString(entry)).toList();
      } catch (e) {
        // something went wrong parsing the data
        print('error loading history: $e');
        return [];
      }
    }
    return [];  // empty list if no history
  }

  // iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    return true;
  }

  // main service handler that runs in the background
  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    print('Background service started - time to stalk your movements!');

    final FlutterLocalNotificationsPlugin notificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // track location every 30 seconds
  
    Timer? timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        // get current location with high accuracy
        // this might drain battery but we want precision!
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // save location to history
        await _logLocation(position);

        // save current location for quick access
        await _saveCurrentLocation(position);

        // send update to the UI if it's running
        service.invoke('location', {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        });

        // update notification with current location
        await _updateNotification(notificationsPlugin, position);
        
      } catch (e) {
        print('location error: $e');
        // show error in notification
        notificationsPlugin.show(
          888,
          'Location Tracker',
          'Error getting location - did you turn off GPS?',
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

    // listen for stop command from the UI
    service.on('stopService').listen((event) {
      timer.cancel();  // stop periodic updates
      service.stopSelf();  // stop the service
      print('Service stopped');
    });
  }

  // saves the current location to SharedPreferences
  static Future<void> _saveCurrentLocation(Position position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_latitude', position.latitude);
    await prefs.setDouble('last_longitude', position.longitude);
    await prefs.setString('last_update', DateTime.now().toIso8601String());
  }

  // add new location to history
  static Future<void> _logLocation(Position position) async {
    final prefs = await SharedPreferences.getInstance();

    // grab existing history
    List<String> locationHistory = prefs.getStringList('location_history') ?? [];

    // create new location and convert to string
    final newLocation = LocationData(
      timestamp: DateTime.now().toIso8601String(),
      latitude: position.latitude,
      longitude: position.longitude,
    );

    // add to history (newer entries first)
    locationHistory.insert(0, newLocation.toStorageString());

    // keep history from getting too big
    // don't want to blow up the storage lol
    if (locationHistory.length > MAX_HISTORY_ENTRIES) {
      locationHistory = locationHistory.sublist(0, MAX_HISTORY_ENTRIES);
    }

    // save updated history
    await prefs.setStringList('location_history', locationHistory);
  }

  // update the notification with current location
  static Future<void> _updateNotification(
    FlutterLocalNotificationsPlugin plugin,
    Position position,
  ) async {
    final locationText =
        'Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}';
        
    await plugin.show(
      888,
      'Current Location',
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
  }
}