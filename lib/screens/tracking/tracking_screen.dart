import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/tracking_controller.dart';
import '../../data/models/location_model.dart';

class TrackingScreen extends GetView<TrackingController> {
  const TrackingScreen({super.key});

  static const Color navy = Color(0xFF102B42);
  static const Color teal = Color(0xFF0F8B83);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text(
          'Driver Tracking',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: controller.refreshDashboard,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        final current = controller.currentLocation.value;
        final stats = controller.statistics;

        return RefreshIndicator(
          onRefresh: controller.refreshDashboard,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatusCard(),

              const SizedBox(height: 16),

              _buildLocationCard(current),

              const SizedBox(height: 18),

              const Text(
                'Tracking Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      'Total',
                      stats['total'] ?? 0,
                      Icons.location_on,
                      navy,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard(
                      'Synced',
                      stats['synced'] ?? 0,
                      Icons.cloud_done,
                      Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      'Pending',
                      stats['pending'] ?? 0,
                      Icons.cloud_upload,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard(
                      'Failed',
                      stats['failed'] ?? 0,
                      Icons.error_outline,
                      Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              _buildTrackingButtons(),

              const SizedBox(height: 20),

              if (controller.errorMessage.value.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    controller.errorMessage.value,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),

              const Text(
                'Recent Location History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),

              const SizedBox(height: 10),

              if (controller.isLoading.value && controller.locations.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (controller.locations.isEmpty)
                _emptyHistory()
              else
                ...controller.locations.take(20).map(_locationTile),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatusCard() {
    return Obx(() {
      final active = controller.isTracking.value;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: navy,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(
              active ? Icons.gps_fixed : Icons.gps_not_fixed,
              color: active ? Colors.greenAccent : Colors.white70,
              size: 38,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GPS Tracking Status',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    active ? 'Tracking Active' : 'Tracking Stopped',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: active ? Colors.greenAccent : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLocationCard(LocationModel? location) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Simulated Location',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: navy,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          _coordinate(
            'Latitude',
            location?.latitude.toStringAsFixed(6) ?? '--',
          ),
          const Divider(height: 22),
          _coordinate(
            'Longitude',
            location?.longitude.toStringAsFixed(6) ?? '--',
          ),
          const Divider(height: 22),
          _coordinate(
            'Captured At',
            location == null ? '--' : _formatDate(location.capturedAt),
          ),
          const SizedBox(height: 8),
          const Text(
            'Demo coordinates are simulated, not actual GPS.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _coordinate(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600, color: navy),
          ),
        ),
      ],
    );
  }

  Widget _statCard(String title, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 12),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTrackingButtons() {
    return Obx(() {
      final active = controller.isTracking.value;

      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: active ? null : controller.startTracking,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Tracking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: active ? controller.stopTracking : null,
              icon: const Icon(Icons.stop),
              label: const Text('Stop Tracking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _locationTile(LocationModel location) {
    final statusColor = location.status == 'synced'
        ? Colors.green
        : location.status == 'failed'
        ? Colors.red
        : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withAlpha(25),
          child: Icon(Icons.location_on, color: statusColor),
        ),
        title: Text(
          '${location.latitude.toStringAsFixed(6)}, '
          '${location.longitude.toStringAsFixed(6)}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Text(_formatDate(location.capturedAt)),
        trailing: Text(
          location.status.toUpperCase(),
          style: TextStyle(
            color: statusColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _emptyHistory() {
    return Container(
      padding: const EdgeInsets.all(25),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.location_searching, size: 45, color: Colors.grey),
          SizedBox(height: 10),
          Text('No location records yet'),
          Text(
            'Press Start Tracking to begin.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');

    return '${local.day}/${local.month}/${local.year} '
        '$hour:$minute:$second';
  }
}
