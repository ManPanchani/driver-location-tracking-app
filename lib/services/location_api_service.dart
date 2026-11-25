import 'package:dio/dio.dart';

import '../data/models/location_model.dart';

class LocationApiService {
  LocationApiService._();

  static final LocationApiService instance = LocationApiService._();

  // Your computer's IPv4 address
  static const String baseUrl = 'http://192.168.1.2:3000';

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  Future<bool> checkHealth() async {
    final response = await _dio.get('/api/v1/health');

    return response.statusCode == 200 &&
        response.data['success'] == true &&
        response.data['database'] == 'connected';
  }

  Future<Map<String, dynamic>> syncLocations(
    List<LocationModel> locations,
  ) async {
    if (locations.isEmpty) {
      return {'received': 0, 'inserted': 0, 'duplicates': 0};
    }

    final response = await _dio.post(
      '/api/v1/locations/bulk',
      data: {
        'locations': locations.map((location) {
          return {
            'id': location.id,
            'latitude': location.latitude,
            'longitude': location.longitude,
            'captured_at': location.capturedAt.toUtc().toIso8601String(),
          };
        }).toList(),
      },
    );

    if (response.statusCode != 201 || response.data['success'] != true) {
      throw Exception('Location synchronization failed.');
    }

    return Map<String, dynamic>.from(response.data);
  }
}
