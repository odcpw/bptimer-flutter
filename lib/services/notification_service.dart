/// NotificationService - Local notification management for SMAs
/// 
/// Handles local notifications for Special Mindfulness Activities without
/// requiring internet connectivity. Uses flutter_local_notifications v19+
/// for Android 14/15 compatibility with proper permission handling.
///
/// CRITICAL REQUIREMENTS:
/// - AndroidManifest.xml must include ScheduledNotificationReceiver
/// - flutter_local_notifications: ^19.4.0+ required
/// - compileSdk: 36+ for latest Android compatibility
/// - Proper runtime permission handling for Android 13+ POST_NOTIFICATIONS

library;

import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../models/sma.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Debug mode toggle for enhanced logging
  static const bool _debugMode = true; // Enabled for debugging SMA scheduling

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _permissionGranted = false;
  bool _exactAlarmPermissionGranted = false;
  String? _permissionDenialReason;

  /// Initialize notification service
  Future<bool> initialize() async {
    if (_initialized) return _permissionGranted;

    try {
      // Android initialization - simplified without icon
      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('@mipmap/ic_launcher');  // Keep this one for init

      // iOS initialization  
      const DarwinInitializationSettings iosSettings = 
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        linux: LinuxInitializationSettings(
          defaultActionName: 'Open notification',
        ),
      );

      final bool? initialized = await _flutterLocalNotificationsPlugin
          .initialize(settings, onDidReceiveNotificationResponse: _onNotificationTapped);

      if (initialized == true) {
        _permissionGranted = await _requestPermissions();
        _initialized = true;
      }

      debugPrint('NotificationService initialized: $_permissionGranted');
      return _permissionGranted;
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
      return false;
    }
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 13+ POST_NOTIFICATIONS permission - use flutter_local_notifications method
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        debugPrint('POST_NOTIFICATIONS permission (flutter_local_notifications): $granted');
        
        if (granted == true) {
          _permissionGranted = true;
          return true;
        }
      }
      
      // Fallback to permission_handler method
      try {
        if (await Permission.notification.isDenied) {
          final status = await Permission.notification.request();
          if (status != PermissionStatus.granted) {
            _permissionDenialReason = 'Android notification permission denied. SMAs will work without notifications.';
            debugPrint(_permissionDenialReason);
            return false;
          }
        }
      } catch (e) {
        debugPrint('Permission request failed: $e');
        return false;
      }

      // Android 12+ exact alarm permission (for precise SMA timing) - critical for proper scheduling
      try {
        final bool? exactAlarmPermission = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.canScheduleExactNotifications();

        _exactAlarmPermissionGranted = exactAlarmPermission == true;
        
        if (!_exactAlarmPermissionGranted) {
          debugPrint('Exact alarm permission not granted - notifications will use inexact scheduling');
          _permissionDenialReason = 'Exact alarm permission not granted. Notifications may not fire at precise times.';
        } else {
          debugPrint('Exact alarm permission granted - using precise scheduling');
        }
      } catch (e) {
        debugPrint('Exact alarm permission check failed: $e');
        _exactAlarmPermissionGranted = false;
      }
    } else if (Platform.isIOS) {
      final bool? granted = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      if (granted != true) {
        _permissionDenialReason = 'iOS notification permission denied. Please enable in Settings > Notifications.';
        debugPrint(_permissionDenialReason);
        return false;
      }
    }

    return true;
  }
  
  /// Check if notifications are available and enabled
  bool get areNotificationsEnabled => _initialized && _permissionGranted;
  
  /// Check if exact alarm permission is granted
  bool get hasExactAlarmPermission => _exactAlarmPermissionGranted;
  
  /// Get human-readable status of notification permissions
  String getPermissionStatus() {
    if (!_initialized) return 'Notification service not initialized';
    if (!_permissionGranted) {
      return _permissionDenialReason ?? 'Notification permissions not granted';
    }
    
    if (_exactAlarmPermissionGranted) {
      return 'Notifications enabled with exact timing';
    } else {
      return 'Notifications enabled (approximate timing only)';
    }
  }
  
  /// Request permissions again (for settings page)
  Future<bool> requestPermissionsAgain() async {
    _permissionGranted = await _requestPermissions();
    return _permissionGranted;
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle notification tap - could navigate to SMA details
    // For now, just log it
  }

  /// Schedule notifications for all enabled SMAs
  Future<void> scheduleAllSMAs(List<SMA> smas) async {
    if (!_permissionGranted) {
      debugPrint('No notification permission - skipping SMA scheduling');
      return;
    }

    try {
      // Cancel existing notifications
      await cancelAllNotifications();

      // Schedule new notifications
      for (final sma in smas) {
        if (sma.notificationsEnabled) {
          await _scheduleSMANotifications(sma);
        }
      }

      debugPrint('Scheduled notifications for ${smas.where((s) => s.notificationsEnabled).length} SMAs');
    } catch (e) {
      debugPrint('Failed to schedule SMA notifications: $e');
    }
  }

  /// Schedule notifications for a single SMA
  Future<void> _scheduleSMANotifications(SMA sma) async {
    try {
      final notifications = _generateSMANotifications(sma);
      
      if (_debugMode) {
        debugPrint('=== Scheduling ${notifications.length} notifications for SMA: ${sma.name} ===');
      }
      
      for (final notification in notifications) {
        try {
          await _flutterLocalNotificationsPlugin.zonedSchedule(
            notification['id'] as int,
            notification['title'] as String,
            notification['body'] as String,
            notification['scheduledDate'] as tz.TZDateTime,
            _getNotificationDetails(),
            androidScheduleMode: _exactAlarmPermissionGranted 
                ? AndroidScheduleMode.exactAllowWhileIdle 
                : AndroidScheduleMode.inexact,
            payload: sma.id,
          );
        } catch (e) {
          debugPrint('ERROR: Failed to schedule notification ID ${notification['id']}: $e');
          continue; // Skip this notification and continue with others
        }
        
        if (_debugMode) {
          final scheduledDate = notification['scheduledDate'] as tz.TZDateTime;
          final now = tz.TZDateTime.now(tz.local);
          final difference = scheduledDate.difference(now);
          debugPrint('  ✓ ID ${notification['id']}: ${scheduledDate.toString()} (in ${difference.inMinutes} minutes)');
        }
      }
    } catch (e) {
      debugPrint('ERROR scheduling SMA ${sma.name}: $e');
    }
  }

  /// Generate notification schedule for SMA
  List<Map<String, dynamic>> _generateSMANotifications(SMA sma) {
    final List<Map<String, dynamic>> notifications = [];
    final now = tz.TZDateTime.now(tz.local);

    // Platform-specific notification limits
    final int maxNotifications = Platform.isIOS ? 60 : 500; // iOS has 64 notification limit
    int scheduledCount = 0;

    switch (sma.frequency) {
      case 'daily':
        scheduledCount = _generateDailyNotifications(sma, notifications, now, maxNotifications);
        break;
      case 'weekly':
        scheduledCount = _generateWeeklyNotifications(sma, notifications, now, maxNotifications);
        break;
      case 'monthly':
        scheduledCount = _generateMonthlyNotifications(sma, notifications, now, maxNotifications);
        break;
      case 'multiple':
        scheduledCount = _generateMultipleNotifications(sma, notifications, now, maxNotifications);
        break;
    }

    debugPrint('Generated $scheduledCount notifications for SMA: ${sma.name}');
    return notifications;
  }

  /// Generate daily notifications
  int _generateDailyNotifications(SMA sma, List<Map<String, dynamic>> notifications, tz.TZDateTime now, int maxNotifications) {
    int count = 0;
    final random = Random();

    // Check if any window is still available today
    final availableWindowsToday = sma.reminderWindows.where((window) => 
        _canScheduleInWindowToday(window, now)).toList();
    
    int startDay = availableWindowsToday.isNotEmpty ? 0 : 1; // Start from today if possible
    int totalDays = startDay == 0 ? 7 : 7; // Always schedule 7 days total

    // Schedule notifications
    for (int day = startDay; day < startDay + totalDays && count < maxNotifications; day++) {
      final targetDate = now.add(Duration(days: day));
      final isToday = day == 0;
      
      // For daily SMAs, only use one reminder window per day (randomly selected)
      List<String> candidateWindows;
      if (isToday) {
        // Use only available windows for today
        candidateWindows = availableWindowsToday;
      } else {
        // Use all windows for future days
        candidateWindows = sma.reminderWindows;
      }
      
      if (candidateWindows.isNotEmpty) {
        final window = candidateWindows[random.nextInt(candidateWindows.length)];
        final notificationTime = _getTimeInWindow(
          targetDate, 
          window, 
          random, 
          isToday: isToday, 
          currentTime: isToday ? now : null
        );
        final id = _generateNotificationId(sma.id, day + 1, window);

        notifications.add({
          'id': id,
          'title': 'Mindfulness Reminder',
          'body': sma.name,
          'scheduledDate': notificationTime,
        });
        count++;
      }
    }
    return count;
  }

  /// Generate weekly notifications
  int _generateWeeklyNotifications(SMA sma, List<Map<String, dynamic>> notifications, tz.TZDateTime now, int maxNotifications) {
    int count = 0;
    final random = Random();

    // Find next occurrence
    final daysUntilTarget = (sma.dayOfWeek - now.weekday + 7) % 7;
    final isToday = daysUntilTarget == 0;
    final targetDate = now.add(Duration(days: daysUntilTarget == 0 ? 0 : daysUntilTarget));
    
    // For weekly SMAs, only use one reminder window per week (randomly selected)
    if (sma.reminderWindows.isNotEmpty) {
      List<String> candidateWindows;
      
      if (isToday) {
        // Check which windows are still available today
        candidateWindows = sma.reminderWindows.where((window) => 
            _canScheduleInWindowToday(window, now)).toList();
        
        // If no windows available today, schedule for next week
        if (candidateWindows.isEmpty) {
          final nextWeekDate = now.add(const Duration(days: 7));
          candidateWindows = sma.reminderWindows;
          final window = candidateWindows[random.nextInt(candidateWindows.length)];
          final notificationTime = _getTimeInWindow(nextWeekDate, window, random);
          final id = _generateNotificationId(sma.id, 1, window);

          notifications.add({
            'id': id,
            'title': 'Weekly Mindfulness',
            'body': sma.name,
            'scheduledDate': notificationTime,
          });
          count++;
          return count;
        }
      } else {
        candidateWindows = sma.reminderWindows;
      }
      
      if (candidateWindows.isNotEmpty) {
        final window = candidateWindows[random.nextInt(candidateWindows.length)];
        final notificationTime = _getTimeInWindow(
          targetDate, 
          window, 
          random, 
          isToday: isToday, 
          currentTime: isToday ? now : null
        );
        final id = _generateNotificationId(sma.id, 1, window);

        notifications.add({
          'id': id,
          'title': 'Weekly Mindfulness',
          'body': sma.name,
          'scheduledDate': notificationTime,
        });
        count++;
      }
    }
    return count;
  }

  /// Generate monthly notifications
  int _generateMonthlyNotifications(SMA sma, List<Map<String, dynamic>> notifications, tz.TZDateTime now, int maxNotifications) {
    int count = 0;
    final random = Random();

    // Schedule for next 30 days
    var targetDate = tz.TZDateTime(tz.local, now.year, now.month + 1, now.day);
    
    // Handle month overflow and leap years
    if (targetDate.month != (now.month + 1) % 12) {
      targetDate = tz.TZDateTime(tz.local, targetDate.year, targetDate.month, 0)
          .add(const Duration(days: 1));
    }
    
    // Only schedule if the target date is within 30 days
    if (targetDate.difference(now).inDays <= 30) {
      // For monthly SMAs, only use one reminder window per month (randomly selected)
      if (sma.reminderWindows.isNotEmpty) {
        final window = sma.reminderWindows[random.nextInt(sma.reminderWindows.length)];
        final notificationTime = _getTimeInWindow(targetDate, window, random);
        final id = _generateNotificationId(sma.id, 1, window);

        notifications.add({
          'id': id,
          'title': 'Monthly Mindfulness',
          'body': sma.name,
          'scheduledDate': notificationTime,
        });
        count++;
      }
    }
    return count;
  }

  /// Generate multiple daily notifications
  int _generateMultipleNotifications(SMA sma, List<Map<String, dynamic>> notifications, tz.TZDateTime now, int maxNotifications) {
    int count = 0;
    final random = Random();

    // Check which windows are still available today
    final availableWindowsToday = sma.reminderWindows.where((window) => 
        _canScheduleInWindowToday(window, now)).toList();
    
    debugPrint('[SMA] Scheduling MULTIPLE notifications for "${sma.name}" at ${now.hour}:${now.minute.toString().padLeft(2, '0')}');
    debugPrint('[SMA] Available windows today: ${availableWindowsToday.join(", ")}');
    debugPrint('[SMA] All reminder windows: ${sma.reminderWindows.join(", ")}');
    debugPrint('[SMA] Expected notifications per day: ${sma.reminderWindows.length}');
    
    int startDay = availableWindowsToday.isNotEmpty ? 0 : 1; // Start from today if possible
    int totalDays = 7; // Always schedule 7 days total
    debugPrint('[SMA] Starting from day $startDay, scheduling $totalDays days total');

    // Schedule notifications - one per selected window per day
    for (int day = startDay; day < startDay + totalDays && count < maxNotifications; day++) {
      final targetDate = now.add(Duration(days: day));
      final isToday = day == 0;
      
      // Determine which windows to use for this day
      List<String> windowsToSchedule;
      if (isToday) {
        // For today, only use available windows
        windowsToSchedule = availableWindowsToday;
      } else {
        // For future days, use all selected windows
        windowsToSchedule = sma.reminderWindows;
      }
      
      debugPrint('[SMA] Day $day (${isToday ? 'today' : 'future'}): Scheduling ${windowsToSchedule.length} windows: ${windowsToSchedule.join(", ")}');
      
      // Use each selected reminder window (max 4 windows = max 4 notifications per day)
      for (final window in windowsToSchedule) {
        if (count >= maxNotifications) break;
        
        final notificationTime = _getTimeInWindow(
          targetDate, 
          window, 
          random, 
          isToday: isToday, 
          currentTime: isToday ? now : null
        );
        final id = _generateNotificationId(sma.id, day + 1, window);

        debugPrint('[SMA] Day $day: Scheduled $window notification (ID: $id) for ${notificationTime.month}/${notificationTime.day} at ${notificationTime.hour}:${notificationTime.minute.toString().padLeft(2, '0')}');

        notifications.add({
          'id': id,
          'title': 'Mindfulness Moment',
          'body': sma.name,
          'scheduledDate': notificationTime,
        });
        count++;
      }
    }
    debugPrint('[SMA] MULTIPLE scheduling complete: ${count} total notifications scheduled for "${sma.name}"');
    return count;
  }

  /// Check if a time window is still available today for scheduling
  bool _canScheduleInWindowToday(String window, tz.TZDateTime now) {
    final currentHour = now.hour;
    
    switch (window) {
      case 'morning':
        return currentHour < 10; // Can schedule if before 10 AM
      case 'midday':
        return currentHour < 14; // Can schedule if before 2 PM
      case 'afternoon':
        return currentHour < 18; // Can schedule if before 6 PM
      case 'evening':
        return currentHour < 22; // Can schedule if before 10 PM
      default:
        return false;
    }
  }

  /// Get window boundaries as TZDateTime objects
  ({tz.TZDateTime start, tz.TZDateTime end}) _getWindowBoundaries(tz.TZDateTime date, String window) {
    final (startHour, endHour) = switch (window) {
      'morning' => (6, 10),
      'midday' => (10, 14), 
      'afternoon' => (14, 18),
      'evening' => (18, 22),
      _ => (9, 17),
    };
    
    return (
      start: tz.TZDateTime(tz.local, date.year, date.month, date.day, startHour, 0),
      end: tz.TZDateTime(tz.local, date.year, date.month, date.day, endHour, 0),
    );
  }

  /// Get random time within reminder window using elegant DateTime arithmetic
  tz.TZDateTime _getTimeInWindow(tz.TZDateTime date, String window, Random random, {bool isToday = false, tz.TZDateTime? currentTime}) {
    // Get window boundaries as proper DateTime objects
    final boundaries = _getWindowBoundaries(date, window);
    final windowStart = boundaries.start;
    final windowEnd = boundaries.end;
    
    // Calculate minimum acceptable time (1 minute buffer for safety)
    final minimumTime = isToday && currentTime != null 
        ? currentTime.add(const Duration(minutes: 1))
        : windowStart;
    
    // Determine valid scheduling range
    final effectiveStart = minimumTime.isAfter(windowStart) ? minimumTime : windowStart;
    final effectiveEnd = windowEnd;
    
    // Check if window is still valid
    if (effectiveStart.isAfter(effectiveEnd) || effectiveStart.isAtSameMomentAs(effectiveEnd)) {
      if (_debugMode) {
        debugPrint('WARNING: Window $window has passed or is too narrow. Effective start: $effectiveStart, End: $effectiveEnd');
      }
      // Return minimum time as fallback (may cause scheduling to fail gracefully)
      return effectiveStart;
    }
    
    // Generate random time within valid range
    final rangeMinutes = effectiveEnd.difference(effectiveStart).inMinutes;
    if (rangeMinutes <= 0) {
      if (_debugMode) {
        debugPrint('WARNING: No valid time range in window $window, returning minimum time');
      }
      return effectiveStart;
    }
    
    final randomMinutes = random.nextInt(rangeMinutes);
    final scheduledTime = effectiveStart.add(Duration(minutes: randomMinutes));
    
    // Final validation - ensure time is actually in the future
    final now = tz.TZDateTime.now(tz.local);
    if (scheduledTime.isBefore(now) || scheduledTime.isAtSameMomentAs(now)) {
      if (_debugMode) {
        debugPrint('WARNING: Generated time $scheduledTime is not in future (now: $now). Using 1-minute buffer.');
      }
      return now.add(const Duration(minutes: 1));
    }
    
    if (_debugMode && isToday) {
      final minutesFromNow = scheduledTime.difference(now).inMinutes;
      debugPrint('✓ Scheduled $window notification $minutesFromNow minutes from now at $scheduledTime');
    }
    
    return scheduledTime;
  }

  /// Get window index for consistent ID generation
  int _getWindowIndex(String window) {
    switch (window) {
      case 'morning':
        return 0;
      case 'midday':
        return 1;
      case 'afternoon':
        return 2;
      case 'evening':
        return 3;
      default:
        return 0; // Default to morning
    }
  }

  /// Generate unique notification ID
  int _generateNotificationId(String smaId, int dayNumber, String window) {
    // Create unique ID from SMA ID hash, day number, and window index
    final smaHash = smaId.hashCode.abs();
    final windowIndex = _getWindowIndex(window);
    return (smaHash % 10000) * 1000 + (dayNumber % 100) * 10 + windowIndex;
  }

  /// Get platform-specific notification details
  NotificationDetails _getNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'sma_reminders',
        'Mindfulness Reminders',
        channelDescription: 'Special Mindfulness Activity reminders',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF20b2aa),
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: 'sma_reminder',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      linux: LinuxNotificationDetails(),
    );
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('All notifications cancelled');
    } catch (e) {
      debugPrint('Failed to cancel notifications: $e');
    }
  }

  /// Cancel notifications for specific SMA
  Future<void> cancelSMANotifications(String smaId) async {
    try {
      final List<PendingNotificationRequest> pendingNotifications = 
          await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      
      for (final notification in pendingNotifications) {
        // Check if notification ID matches SMA (rough match due to ID generation)
        final smaHash = smaId.hashCode.abs();
        final expectedPrefix = smaHash % 10000;
        final actualPrefix = notification.id ~/ 1000;
        
        if (actualPrefix == expectedPrefix) {
          await _flutterLocalNotificationsPlugin.cancel(notification.id);
        }
      }
      
      debugPrint('Cancelled notifications for SMA: $smaId');
    } catch (e) {
      debugPrint('Failed to cancel SMA notifications: $e');
    }
  }

  /// Get permission status
  bool get hasPermission => _permissionGranted;

  /// Check if notifications are supported on this platform
  bool get isSupported => 
      Platform.isAndroid || Platform.isIOS || Platform.isLinux || Platform.isMacOS;

  /// Get number of pending notifications
  Future<int> getPendingNotificationCount() async {
    try {
      final List<PendingNotificationRequest> pending = 
          await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      return pending.length;
    } catch (e) {
      debugPrint('Failed to get pending notification count: $e');
      return 0;
    }
  }

  /// Request exact alarm permission using plugin's built-in API
  /// 
  /// Required for precise notification scheduling on Android 14+.
  /// Uses flutter_local_notifications' canScheduleExactNotifications() and
  /// requestExactAlarmsPermission() methods instead of custom platform channels.
  Future<void> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return;
    
    try {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        final canExact = await androidPlugin.canScheduleExactNotifications() ?? false;
        _exactAlarmPermissionGranted = canExact;
        
        if (!canExact) {
          debugPrint('Requesting exact alarm permission from user...');
          await androidPlugin.requestExactAlarmsPermission();
          // Check again after request
          _exactAlarmPermissionGranted = await androidPlugin.canScheduleExactNotifications() ?? false;
        }
        
        debugPrint('Exact alarm permission: $_exactAlarmPermissionGranted');
      }
    } catch (e) {
      debugPrint('Error requesting exact alarm permission: $e');
      _exactAlarmPermissionGranted = false;
    }
  }
  


}