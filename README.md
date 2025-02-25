# Location Tracker App

A Flutter application that tracks device location in foreground, background, and terminated states.

## Overview

This Location Tracker app demonstrates continuous location tracking capabilities in Flutter. The app provides real-time location updates with a simple user interface to control tracking and view location history.

## Features

- **Real-time Location Tracking**: Displays current latitude and longitude with timestamps
- **Background Tracking**: Continues to track location even when the app is in the background
- **Persistent Tracking**: Maintains location updates even after app termination
- **Location History**: Stores and displays recent location data
- **Notification Updates**: Shows current location in a persistent notification
- **User Controls**: Simple interface to start/stop location tracking

## Technical Implementation

### Location Permissions

- Requests and handles appropriate location permissions on both iOS and Android
- Implements specific permission handling for background location access

### Background Service

- Uses `flutter_background_service` to maintain tracking when the app is not in focus
- Implements platform-specific configurations for iOS and Android

### Data Management

- Records location data at regular intervals (every 30 seconds)
- Stores location history using `SharedPreferences`
- Limits storage to prevent excessive memory usage

### User Interface

- Clean, simple UI to display current location information
- Toggle button to start/stop location tracking
- History screen to view recent location data
- Status indicators showing whether tracking is active

## How It Works

1. The app requests location permissions when tracking is first enabled
2. When tracking is activated, a background service starts collecting location data
3. Location updates are stored locally and displayed in the UI
4. A persistent notification shows the current location
5. The user can view location history and toggle tracking on/off

## Libraries Used

- `geolocator` - For accessing device location
- `flutter_background_service` - For background execution
- `flutter_local_notifications` - For persistent notifications
- `shared_preferences` - For data storage
- `permission_handler` - For managing permissions

## Project Structure

- **models/** - Contains data models
- **screens/** - UI screens for home and history views
- **services/** - Background location service implementation
- **utils/** - Utility classes for formatting
- **widgets/** - Reusable UI components

## Requirements Fulfilled

✅ **Obtain Device Location**
  - Implements permission handling for location access
  - Uses Geolocator for accurate location acquisition

✅ **Background & Terminated State Tracking**
  - Configured for background execution on both platforms
  - Maintains tracking after app termination

✅ **Data Handling**
  - Records location at 30-second intervals
  - Displays information in a persistent notification

✅ **User Interface**
  - Shows current/last known location
  - Provides toggle for enabling/disabling tracking
  - Displays location history

✅ **Code Organization**
  - Well-structured with separation of concerns
  - Implements Flutter best practices
