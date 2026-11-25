import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'services/background_tracking_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/tracking_controller.dart';
import 'screens/tracking/tracking_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterForegroundTask.initCommunicationPort();

  BackgroundTrackingService.instance.initialize();

  runApp(const DriverTrackingApp());
}

class DriverTrackingApp extends StatelessWidget {
  const DriverTrackingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Driver Location Tracking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F8B83)),
        scaffoldBackgroundColor: const Color(0xFFF4F7FA),
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      ),
      initialBinding: BindingsBuilder(() {
        Get.put(TrackingController(), permanent: true);
      }),
      home: const TrackingScreen(),
    );
  }
}
