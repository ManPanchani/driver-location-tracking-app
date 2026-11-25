import 'dart:async';
import 'package:dio/dio.dart';
import '../data/database/database_helper.dart';
import '../data/models/location_model.dart';
import 'location_api_service.dart';

class LocationSyncService {
  LocationSyncService._();

  static final LocationSyncService instance = LocationSyncService._();

  final DatabaseHelper _database = DatabaseHelper.instance;
  final LocationApiService _api = LocationApiService.instance;

  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  static const int _maxAttempts = 3;

  Future<int> syncPendingLocations() async {
    if (_isSyncing) return 0;

    _isSyncing = true;

    try {
      final List<LocationModel> pendingLocations = await _database
          .getPendingLocations(limit: 100);

      if (pendingLocations.isEmpty) return 0;

      Object? lastError;

      for (int attempt = 1; attempt <= _maxAttempts; attempt++) {
        try {
          await _api.syncLocations(pendingLocations);

          // Mark records synced only after successful server response.
          for (final location in pendingLocations) {
            await _database.markSynced(location.id);
          }

          return pendingLocations.length;
        } catch (error) {
          lastError = error;

          // Do not retry permanent client errors (HTTP 4xx).
          if (!_shouldRetry(error)) {
            break;
          }

          if (attempt < _maxAttempts) {
            final delaySeconds = attempt;
            await Future.delayed(Duration(seconds: delaySeconds));
          }
        }
      }

      // All attempts failed. Keep records locally for later retry.
      for (final location in pendingLocations) {
        await _database.markFailed(location.id, lastError.toString());
      }

      throw Exception('Sync failed after $_maxAttempts attempts: $lastError');
    } finally {
      _isSyncing = false;
    }
  }

  bool _shouldRetry(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;

      // Retry network errors, timeouts and server errors.
      if (statusCode == null) return true;

      return statusCode >= 500;
    }

    // Retry unexpected/transient errors as well.
    return true;
  }
}
