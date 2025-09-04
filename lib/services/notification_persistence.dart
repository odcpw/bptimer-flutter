/// NotificationPersistence - Boot recovery system for SMA notifications
/// 
/// Persists notification scheduling data using SharedPreferences to restore
/// notifications after device reboots or app crashes. Stores minimal data
/// needed to recreate the notification schedule.

library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sma.dart';
import 'notification_service.dart';

class NotificationPersistence {
  static const String _keyScheduledSMAs = 'scheduled_smas';
  static const String _keyLastRefresh = 'last_notification_refresh';
  
  /// Save currently scheduled SMAs for boot recovery
  Future<void> saveScheduledSMAs(List<SMA> smas) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final smaDataList = smas.map((sma) => sma.toJson()).toList();
      final jsonString = jsonEncode(smaDataList);
      
      await prefs.setString(_keyScheduledSMAs, jsonString);
      debugPrint('[Persistence] Saved ${smas.length} SMAs for boot recovery');
    } catch (e) {
      debugPrint('[Persistence] Failed to save SMAs: $e');
    }
  }
  
  /// Load SMAs that need to be rescheduled after boot
  Future<List<SMA>> loadScheduledSMAs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyScheduledSMAs);
      
      if (jsonString == null || jsonString.isEmpty) {
        debugPrint('[Persistence] No scheduled SMAs found');
        return [];
      }
      
      final List<dynamic> smaDataList = jsonDecode(jsonString);
      final smas = smaDataList
          .map((data) => SMA.fromJson(data as Map<String, dynamic>))
          .toList();
      
      debugPrint('[Persistence] Loaded ${smas.length} SMAs for recovery');
      return smas;
    } catch (e) {
      debugPrint('[Persistence] Failed to load SMAs: $e');
      return [];
    }
  }
  
  /// Save timestamp of last notification refresh
  Future<void> setLastRefresh(DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastRefresh, timestamp.toIso8601String());
      debugPrint('[Persistence] Last refresh time saved: $timestamp');
    } catch (e) {
      debugPrint('[Persistence] Failed to save refresh time: $e');
    }
  }
  
  /// Get timestamp of last notification refresh
  Future<DateTime?> getLastRefresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampString = prefs.getString(_keyLastRefresh);
      
      if (timestampString == null) {
        return null;
      }
      
      return DateTime.parse(timestampString);
    } catch (e) {
      debugPrint('[Persistence] Failed to load refresh time: $e');
      return null;
    }
  }
  
  /// Check if notifications need refreshing (more than 25 hours since last refresh)
  Future<bool> needsRefresh() async {
    final lastRefresh = await getLastRefresh();
    if (lastRefresh == null) {
      return true; // First time, definitely needs refresh
    }
    
    final hoursSinceRefresh = DateTime.now().difference(lastRefresh).inHours;
    final needsRefresh = hoursSinceRefresh > 25; // 1 hour buffer
    
    debugPrint('[Persistence] Hours since refresh: $hoursSinceRefresh, needs refresh: $needsRefresh');
    return needsRefresh;
  }
  
  /// Clear all persistence data
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyScheduledSMAs);
      await prefs.remove(_keyLastRefresh);
      debugPrint('[Persistence] All data cleared');
    } catch (e) {
      debugPrint('[Persistence] Failed to clear data: $e');
    }
  }
  
  /// Restore notifications after app startup (boot recovery)
  Future<bool> restoreNotificationsIfNeeded() async {
    try {
      // Check if we need to restore (app was killed/rebooted)
      if (!await needsRefresh()) {
        debugPrint('[Persistence] Notifications are current, no restore needed');
        return false;
      }
      
      // Load SMAs that need restoration
      final smas = await loadScheduledSMAs();
      if (smas.isEmpty) {
        debugPrint('[Persistence] No SMAs to restore');
        return false;
      }
      
      debugPrint('[Persistence] Restoring notifications for ${smas.length} SMAs');
      
      // Import services locally to avoid circular dependencies  
      final notificationService = NotificationService();
      await notificationService.initialize();
      
      // Reschedule notifications
      await notificationService.scheduleAllSMAs(smas);
      
      // Update refresh timestamp
      await setLastRefresh(DateTime.now());
      
      final count = await notificationService.getPendingNotificationCount();
      debugPrint('[Persistence] Restored $count notifications');
      
      return true;
    } catch (e) {
      debugPrint('[Persistence] Failed to restore notifications: $e');
      return false;
    }
  }
}