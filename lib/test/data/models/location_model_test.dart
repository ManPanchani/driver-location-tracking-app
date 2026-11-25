import 'package:flutter_test/flutter_test.dart';

import '../../../data/models/location_model.dart';

void main() {
  group('LocationModel Tests', () {
    final capturedAt = DateTime.utc(2026, 11, 24, 10, 30);

    final location = LocationModel(
      id: 'test-location-001',
      latitude: 21.1702,
      longitude: 72.8311,
      capturedAt: capturedAt,
    );

    test('Creates location with correct values', () {
      expect(location.id, 'test-location-001');
      expect(location.latitude, 21.1702);
      expect(location.longitude, 72.8311);
      expect(location.status, 'pending');
      expect(location.retryCount, 0);
      expect(location.lastError, isNull);
    });

    test('Converts location to Map', () {
      final map = location.toMap();

      expect(map['id'], location.id);
      expect(map['latitude'], location.latitude);
      expect(map['longitude'], location.longitude);
      expect(map['status'], 'pending');
      expect(map['retry_count'], 0);
    });

    test('Converts Map back to LocationModel', () {
      final result = LocationModel.fromMap(location.toMap());

      expect(result.id, location.id);
      expect(result.latitude, location.latitude);
      expect(result.longitude, location.longitude);
      expect(result.capturedAt.isAtSameMomentAs(capturedAt), isTrue);
    });

    test('Updates status using copyWith', () {
      final updated = location.copyWith(status: 'synced');

      expect(updated.status, 'synced');
      expect(updated.id, location.id);
    });

    test('Clears last error using copyWith', () {
      final failed = location.copyWith(
        status: 'failed',
        retryCount: 1,
        lastError: 'Network error',
      );

      final updated = failed.copyWith(status: 'synced', clearLastError: true);

      expect(updated.status, 'synced');
      expect(updated.lastError, isNull);
      expect(updated.retryCount, 1);
    });
  });
}
