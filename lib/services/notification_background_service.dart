/// NotificationBackgroundService - WorkManager background task dispatcher
/// 
/// Handles background notification refresh every 24 hours to maintain
/// persistent SMA notifications without overwhelming the system.
/// Uses WorkManager for reliable background execution across all devices.

library;

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'notification_service.dart';
import 'database_service.dart';
import 'notification_persistence.dart';

/// Background dispatcher for WorkManager tasks
/// Must be a top-level function for WorkManager compatibility
@pragma('vm:entry-point')
void notificationBackgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('[WorkManager] Executing task: $task');
      
      switch (task) {
        case 'refreshNotifications':
          return await _refreshNotifications();
        default:
          debugPrint('[WorkManager] Unknown task: $task');
          return false;
      }
    } catch (e) {
      debugPrint('[WorkManager] Task failed: $e');
      return false;
    }
  });
}

/// Background notification refresh task
Future<bool> _refreshNotifications() async {
  try {
    debugPrint('[WorkManager] Starting notification refresh...');
    
    // Initialize timezone data (required for background execution)
    tz.initializeTimeZones();
    
    // Initialize services
    final notificationService = NotificationService();
    final databaseService = DatabaseService();
    final persistenceService = NotificationPersistence();
    
    await notificationService.initialize();
    
    // Get all enabled SMAs from database
    final smasResult = await databaseService.getAllSMAs();
    if (smasResult.isFailure) {
      debugPrint('[WorkManager] Failed to load SMAs: ${smasResult.error}');
      return false;
    }
    
    final enabledSMAs = smasResult.getOrElse([])
        .where((sma) => sma.notificationsEnabled)
        .toList();
    
    debugPrint('[WorkManager] Found ${enabledSMAs.length} enabled SMAs');
    
    if (enabledSMAs.isEmpty) {
      debugPrint('[WorkManager] No enabled SMAs, clearing notifications');
      await notificationService.cancelAllNotifications();
      await persistenceService.clearAll();
      return true;
    }
    
    // Cancel existing notifications
    await notificationService.cancelAllNotifications();
    
    // Schedule fresh notifications for next 24 hours
    await notificationService.scheduleAllSMAs(enabledSMAs);
    
    // Update persistence data
    await persistenceService.saveScheduledSMAs(enabledSMAs);
    await persistenceService.setLastRefresh(DateTime.now());
    
    final count = await notificationService.getPendingNotificationCount();
    debugPrint('[WorkManager] Notification refresh complete: $count notifications scheduled');
    
    return true;
  } catch (e) {
    debugPrint('[WorkManager] Notification refresh failed: $e');
    return false;
  }
}