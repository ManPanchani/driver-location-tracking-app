class LocationModel {
  final String id;
  final double latitude;
  final double longitude;
  final DateTime capturedAt;
  final String status;
  final int retryCount;
  final String? lastError;

  const LocationModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    this.status = 'pending',
    this.retryCount = 0,
    this.lastError,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'captured_at': capturedAt.toUtc().toIso8601String(),
      'status': status,
      'retry_count': retryCount,
      'last_error': lastError,
    };
  }

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      id: map['id'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      capturedAt: DateTime.parse(map['captured_at'] as String).toLocal(),
      status: map['status'] as String? ?? 'pending',
      retryCount: (map['retry_count'] as int?) ?? 0,
      lastError: map['last_error'] as String?,
    );
  }

  LocationModel copyWith({
    String? status,
    int? retryCount,
    String? lastError,
    bool clearLastError = false,
  }) {
    return LocationModel(
      id: id,
      latitude: latitude,
      longitude: longitude,
      capturedAt: capturedAt,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }
}
