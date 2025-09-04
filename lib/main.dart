/// BPtimer Flutter App Entry Point
/// 
/// Main application setup with dark theme, state management providers,
/// timezone initialization for notifications, and navigation to the core 
/// meditation timer interface.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:workmanager/workmanager.dart';
import 'services/timer_service.dart';
import 'services/notification_service.dart';
import 'services/notification_background_service.dart';
import 'screens/splash_screen.dart';
import 'utils/constants.dart';
import 'ui/theme.dart';

void main() async {
  debugPrint('[App] Initializing BPtimer...');
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone data for notifications
  tz.initializeTimeZones();
  debugPrint('[App] Timezone data initialized');
  
  // Auto-detect device timezone
  try {
    final String deviceTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(deviceTimezone));
    debugPrint('[App] Device timezone detected: $deviceTimezone');
  } catch (e) {
    // Fallback to UTC if detection fails
    tz.setLocalLocation(tz.UTC);
    debugPrint('[ERROR][App] Timezone detection failed, using UTC: $e');
  }
  
  // Initialize notification service early and await it
  final notificationService = NotificationService();
  final notificationResult = await notificationService.initialize();
  debugPrint('[App] Notification service: ${notificationResult ? "ready" : "failed"}');
  
  // Initialize WorkManager for background notification refresh
  await Workmanager().initialize(
    notificationBackgroundDispatcher,
    isInDebugMode: kDebugMode,
  );
  debugPrint('[App] WorkManager initialized');
  
  // Start periodic notification refresh (24-hour cycle)
  await Workmanager().registerPeriodicTask(
    "sma-notification-refresh",
    "refreshNotifications",
    frequency: const Duration(hours: 24),
  );
  debugPrint('[App] Periodic notification refresh registered');
  
  debugPrint('[App] Platform: ${Platform.operatingSystem}');
  debugPrint('[App] Launching app...');
  runApp(const BPTimerApp());
}

class BPTimerApp extends StatelessWidget {
  const BPTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Timer service for meditation sessions
        ChangeNotifierProvider(create: (_) => TimerService()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: buildDarkTheme(),
        home: const SplashScreen(),
      ),
    );
  }
}
