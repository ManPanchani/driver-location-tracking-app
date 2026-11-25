import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import 'tracking_task_handler.dart';

class BackgroundTrackingService {
  BackgroundTrackingService._();

  static final BackgroundTrackingService instance =
      BackgroundTrackingService._();

  static bool _initialized = false;

  void initialize() {
    if (_initialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'driver_tracking_channel',
        channelName: 'Driver Location Tracking',
        channelDescription:
            'Notification shown while driver tracking is active.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    if (!Platform.isAndroid) {
      throw UnsupportedError(
        'This background tracking setup is currently for Android only.',
      );
    }

    final notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();

    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission was denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. '
        'Please enable it in App Settings.',
      );
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Please enable Location/GPS on your phone.');
    }
  }

  Future<void> start() async {
    initialize();

    await requestPermissions();

    if (await FlutterForegroundTask.isRunningService) {
      return;
    }

    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'Driver Tracking Active',
      notificationText: 'Getting your current GPS location...',
      callback: startTrackingCallback,
    );
  }

  Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  Future<bool> get isRunning async {
    return FlutterForegroundTask.isRunningService;
  }
}
