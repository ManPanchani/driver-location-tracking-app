import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';

import '../data/database/database_helper.dart';
import '../data/models/location_model.dart';
import '../services/background_tracking_service.dart';
import '../services/location_sync_service.dart';

class TrackingController extends GetxController {
  final DatabaseHelper _database = DatabaseHelper.instance;

  final BackgroundTrackingService _backgroundService =
      BackgroundTrackingService.instance;

  final LocationSyncService _syncService = LocationSyncService.instance;

  final Connectivity _connectivity = Connectivity();

  Timer? _retryTimer;

  StreamSubscription<dynamic>? _connectivitySubscription;

  final RxBool isTracking = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isSyncing = false.obs;
  final RxBool isOnline = false.obs;

  final RxList<LocationModel> locations = <LocationModel>[].obs;

  final RxMap<String, int> statistics = <String, int>{
    'total': 0,
    'synced': 0,
    'pending': 0,
    'failed': 0,
  }.obs;

  final Rx<LocationModel?> currentLocation = Rx<LocationModel?>(null);

  final RxString errorMessage = ''.obs;
  final RxString syncMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();

    FlutterForegroundTask.addTaskDataCallback(_onBackgroundTaskData);

    loadDashboard();
    _restoreTrackingState();
    _startConnectivityMonitoring();

    _retryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final pending = statistics['pending'] ?? 0;
      final failed = statistics['failed'] ?? 0;

      if (isOnline.value && !isSyncing.value && (pending > 0 || failed > 0)) {
        syncPendingLocations();
      }
    });
  }

  Future<void> _restoreTrackingState() async {
    try {
      isTracking.value = await _backgroundService.isRunning;
    } catch (error) {
      errorMessage.value = 'Tracking status check failed: $error';
    }
  }

  void _onBackgroundTaskData(Object data) {
    if (data is! Map) return;

    final message = Map<String, dynamic>.from(data);

    if (message['type'] == 'location_saved') {
      unawaited(_handleBackgroundLocationSaved(message));
    } else if (message['type'] == 'location_error') {
      errorMessage.value = 'Background GPS error: ${message['message']}';
    }
  }

  Future<void> _handleBackgroundLocationSaved(
    Map<String, dynamic> message,
  ) async {
    try {
      final id = message['id'] as String?;

      if (id != null) {
        final location = await _database.getLocationById(id);

        if (location != null) {
          currentLocation.value = location;
        }
      }

      await loadDashboard();

      if (isOnline.value) {
        await syncPendingLocations();
      }
    } catch (error) {
      errorMessage.value = 'Background location update failed: $error';
    }
  }

  bool _hasNetwork(dynamic result) {
    final results = result is List ? result : [result];

    return results.any((item) => item != ConnectivityResult.none);
  }

  void _startConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (dynamic result) async {
        final connected = _hasNetwork(result);

        isOnline.value = connected;

        if (connected) {
          await syncPendingLocations();
        }
      },
      onError: (error) {
        errorMessage.value = 'Connectivity error: $error';
      },
    );

    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();

      isOnline.value = _hasNetwork(result);

      if (isOnline.value) {
        await syncPendingLocations();
      }
    } catch (error) {
      errorMessage.value = 'Network check failed: $error';
    }
  }

  Future<void> loadDashboard() async {
    isLoading.value = true;

    try {
      final records = await _database.getAllLocations();
      final stats = await _database.getStatistics();

      locations.assignAll(records);
      statistics.assignAll(stats);
    } catch (error) {
      errorMessage.value = 'Database error: $error';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> startTracking() async {
    if (isTracking.value) return;

    errorMessage.value = '';
    syncMessage.value = '';

    try {
      await _backgroundService.start();

      isTracking.value = true;

      await loadDashboard();
    } catch (error) {
      isTracking.value = false;

      errorMessage.value = 'Unable to start tracking: $error';
    }
  }

  Future<void> stopTracking() async {
    try {
      await _backgroundService.stop();

      isTracking.value = false;

      await loadDashboard();
    } catch (error) {
      errorMessage.value = 'Unable to stop tracking: $error';
    }
  }

  Future<void> syncPendingLocations() async {
    if (isSyncing.value) return;

    if (!isOnline.value) {
      syncMessage.value = 'Offline: locations saved locally.';
      return;
    }

    isSyncing.value = true;

    try {
      final syncedCount = await _syncService.syncPendingLocations();

      if (syncedCount > 0) {
        syncMessage.value = '$syncedCount locations synchronized successfully.';
      } else {
        syncMessage.value = 'All locations are synchronized.';
      }

      await loadDashboard();
    } catch (error) {
      syncMessage.value =
          'Synchronization failed. Will retry when connection is available.';

      errorMessage.value = 'Sync error: $error';

      await loadDashboard();
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> refreshDashboard() async {
    await loadDashboard();
  }

  @override
  void onClose() {
    FlutterForegroundTask.removeTaskDataCallback(_onBackgroundTaskData);

    _connectivitySubscription?.cancel();
    _retryTimer?.cancel();

    // Do not stop the foreground service here.
    // It must be able to continue when the app UI closes.

    super.onClose();
  }
}
