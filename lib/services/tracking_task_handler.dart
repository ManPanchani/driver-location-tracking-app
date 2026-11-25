import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../data/database/database_helper.dart';
import '../data/models/location_model.dart';

class TrackingTaskHandler extends TaskHandler {
  final DatabaseHelper _database = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  bool _isCapturing = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _captureLocation();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    unawaited(_captureLocation());
  }

  Future<void> _captureLocation() async {
    if (_isCapturing) return;

    _isCapturing = true;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        FlutterForegroundTask.updateService(
          notificationTitle: 'Driver Tracking Active',
          notificationText: 'Please enable GPS on your phone.',
        );
        return;
      }

      final permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        FlutterForegroundTask.updateService(
          notificationTitle: 'Driver Tracking Paused',
          notificationText: 'Location permission is required.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final location = LocationModel(
        id: _uuid.v4(),
        latitude: position.latitude,
        longitude: position.longitude,
        capturedAt: position.timestamp,
        status: 'pending',
        retryCount: 0,
      );

      final inserted = await _database.insertLocation(location);

      if (inserted) {
        FlutterForegroundTask.updateService(
          notificationTitle: 'Driver Tracking Active',
          notificationText:
              'Location saved: ${position.latitude.toStringAsFixed(5)}, '
              '${position.longitude.toStringAsFixed(5)}',
        );

        FlutterForegroundTask.sendDataToMain({
          'type': 'location_saved',
          'id': location.id,
          'latitude': location.latitude,
          'longitude': location.longitude,
          'capturedAt': location.capturedAt.toIso8601String(),
        });
      }
    } catch (error) {
      FlutterForegroundTask.updateService(
        notificationTitle: 'Driver Tracking Active',
        notificationText: 'Location update failed. Retrying...',
      );

      FlutterForegroundTask.sendDataToMain({
        'type': 'location_error',
        'message': error.toString(),
      });
    } finally {
      _isCapturing = false;
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _isCapturing = false;
  }

  @override
  void onReceiveData(Object data) {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {}
}

@pragma('vm:entry-point')
void startTrackingCallback() {
  FlutterForegroundTask.setTaskHandler(TrackingTaskHandler());
}
