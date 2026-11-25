import 'dart:async';
import 'package:uuid/uuid.dart';

import '../data/models/location_model.dart';

class SimulatedGpsService {
  SimulatedGpsService();

  final Uuid _uuid = const Uuid();
  Timer? _timer;

  double _latitude = 21.1702;
  double _longitude = 72.8311;

  bool get isRunning => _timer?.isActive ?? false;

  void start({
    required Future<void> Function(LocationModel location) onLocation,
    Duration interval = const Duration(seconds: 5),
  }) {
    if (isRunning) return;

    // Generate the first location immediately.
    _generateAndSend(onLocation);

    _timer = Timer.periodic(interval, (_) {
      _generateAndSend(onLocation);
    });
  }

  Future<void> _generateAndSend(
    Future<void> Function(LocationModel location) onLocation,
  ) async {
    // Simulate movement in Surat.
    _latitude += 0.0005;
    _longitude += 0.0004;

    final location = LocationModel(
      id: _uuid.v4(),
      latitude: double.parse(_latitude.toStringAsFixed(6)),
      longitude: double.parse(_longitude.toStringAsFixed(6)),
      capturedAt: DateTime.now(),
      status: 'pending',
      retryCount: 0,
    );

    await onLocation(location);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
  }
}
