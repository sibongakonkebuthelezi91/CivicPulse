import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'geofence_manager.dart';

const String foregroundChannelId = 'civicpulse_foreground_channel';
const String alertChannelId = 'civicpulse_alert_channel';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // Ensure notification channel is created on Android before starting the service
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    foregroundChannelId,
    'CivicPulse Service',
    description: 'Runs in the background to monitor location and geofence alerts.',
    importance: Importance.low,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: foregroundChannelId,
      initialNotificationTitle: 'CivicPulse Geofencing Active',
      initialNotificationContent: 'Monitoring location for road hazards...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  await service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available on iOS and Android respectively
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Create alert channel for geofences
  const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
    alertChannelId,
    'Road Safety Alerts',
    description: 'High-priority alerts for potholes and traffic light issues.',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(alertChannel);

  // Initialize notifications settings
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Background GPS loop
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    if (service is AndroidServiceInstance) {
      if (!await service.isForegroundService()) {
        return;
      }
    }

    try {
      // Check permissions first
      final LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );

      // Broadcast update to the main UI
      service.invoke(
        'update_location',
        {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'speed': position.speed,
          'timestamp': position.timestamp.toIso8601String(),
        },
      );

      // Evaluate geofences using singleton GeofenceManager
      final newlyTriggered = GeofenceManager().evaluatePosition(
        position.latitude,
        position.longitude,
      );

      for (var point in newlyTriggered) {
        String alertTitle = '';
        String alertMsg = '';
        
        switch (point.type) {
          case GeofenceType.pothole:
            alertTitle = '⚠️ Severe Pothole Ahead!';
            alertMsg = 'Slow down! ${point.title} detected within 100 meters.';
            break;
          case GeofenceType.trafficLight:
            alertTitle = '🚦 Faulty Traffic Light!';
            alertMsg = 'Be cautious! ${point.title} ahead.';
            break;
          case GeofenceType.animalCrossing:
            alertTitle = '🐕 Animal Crossing Danger!';
            alertMsg = 'Watch the road! ${point.title} ahead.';
            break;
        }

        // Show a local high-importance notification
        await flutterLocalNotificationsPlugin.show(
          id: point.id.hashCode,
          title: alertTitle,
          body: alertMsg,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              alertChannelId,
              alertChannel.name,
              channelDescription: alertChannel.description,
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );

        // Also broadcast event to the UI so it can show in-app dialogs/toasts
        service.invoke(
          'geofence_triggered',
          point.toJson(),
        );
      }
    } catch (e) {
      // Handle potential timeout or exception
      debugPrint('Background Location Service Error: $e');
    }
  });
}

/// Helper to request foreground & background permissions on the UI side
Future<bool> requestLocationPermissions() async {
  final locationStatus = await Permission.location.request();
  if (locationStatus.isGranted) {
    // Background location permission is required for background updates on Android 10+
    final backgroundStatus = await Permission.locationAlways.request();
    final notificationStatus = await Permission.notification.request();
    return backgroundStatus.isGranted && notificationStatus.isGranted;
  }
  return false;
}
