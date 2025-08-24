/// Constants - Centralized configuration values for the meditation timer
/// 
/// Eliminates magic numbers and provides single source of truth for
/// timing constraints, UI dimensions, and other configuration values.

library;

import 'package:flutter/material.dart';

class TimerConstants {
  // Timer duration constraints
  static const int minDurationSeconds = 300;         // 5 minutes
  static const int maxDurationSeconds = 7200;        // 2 hours
  static const int defaultDurationSeconds = 1200;    // 20 minutes
  static const int durationIncrementSeconds = 300;   // 5 minutes
  
  // Timer behavior
  static const int timerTickIntervalMs = 1000;       // 1 second
  static const int minSessionSaveSeconds = 60;       // Minimum time to save session
  
  // Wake lock
  static const int wakeLockTimeoutMs = 15000;        // 15 seconds timeout
}

class NotificationConstants {
  // Notification scheduling
  static const int maxPendingNotifications = 64;     // iOS limit
  static const int notificationRetryDelayMs = 120000; // 2 minutes
  static const int scheduleAheadDays = 14;           // Schedule 2 weeks ahead
  
  // Time windows for SMA notifications (24-hour format)
  static const Map<String, Map<String, int>> timeWindows = {
    'morning': {'start': 6, 'end': 10},     // 6am-10am
    'midday': {'start': 10, 'end': 14},     // 10am-2pm  
    'afternoon': {'start': 14, 'end': 18},  // 2pm-6pm
    'evening': {'start': 18, 'end': 22},    // 6pm-10pm
  };
  
  // Default reminder windows
  static const List<String> defaultReminderWindows = [
    'morning', 'midday', 'afternoon', 'evening'
  ];
}

class DatabaseConstants {
  static const String dbName = 'meditation_timer.db';
  static const int dbVersion = 1;
  
  // Table names
  static const String sessionsTable = 'sessions';
  static const String smasTable = 'smas';
  static const String settingsTable = 'settings';
  
  // Batch sizes
  static const int maxBatchSize = 100;
  static const int exportBatchSize = 50;
}

class UIConstants {
  // Animation durations
  static const int shortAnimationMs = 200;
  static const int mediumAnimationMs = 300;
  static const int longAnimationMs = 500;
  
  // Splash screen duration (2s instead of PWA's 3s)
  static const int splashScreenDurationMs = 2000;
  
  // Timer display
  static const double timerCircleSize = 250.0;
  static const double timerStrokeWidth = 8.0;
  static const double timerTextSize = 48.0;
  
  // List items
  static const double listItemHeight = 72.0;
  static const double listItemPadding = 16.0;
  
  // Bottom margins for FABs
  static const double fabBottomMargin = 16.0;
  
  // Modal heights
  static const double modalMaxHeight = 0.8;  // 80% of screen
  static const double modalMinHeight = 0.3;  // 30% of screen
  
  // Button dimensions
  static const double buttonHeight = 56.0;
  static const double buttonWidth = 140.0;
  static const double buttonSpacing = 16.0;
  static const double buttonIconSize = 20.0;
  static const double buttonBorderRadius = 8.0;
  
  // Period button dimensions
  static const double periodButtonHeight = 40.0;
  static const double periodButtonPadding = 8.0;
}

class TypographyConstants {
  // Golden ratio (φ) for harmonious font sizing
  static const double goldenRatio = 1.618;
  static const double inverseGoldenRatio = 0.618;
  
  // Base font size (16px = 1rem)
  static const double baseFontSize = 16.0;
  
  // Golden ratio scale font sizes
  static const double fontSizeXSmall = 10.0;   // base * inverse golden ratio
  static const double fontSizeSmall = 13.0;    // base * 0.8
  static const double fontSizeBase = 16.0;     // 1rem base
  static const double fontSizeMedium = 20.0;   // base * 1.25
  static const double fontSizeLarge = 26.0;    // base * golden ratio
  static const double fontSizeXLarge = 32.0;   // base * 2
  static const double fontSizeXXLarge = 42.0;  // base * 2.618
  static const double fontSizeHuge = 68.0;     // base * 4.236
  
  // Timer display - responsive with golden ratio
  // Mimics PWA: clamp(5rem, 15vw, 9rem) = clamp(80px, 15vw, 144px)
  static const double timerFontSizeMin = 80.0;  // 5rem
  static const double timerFontSizeMax = 144.0; // 9rem
  static const double timerFontSizeViewport = 0.15; // 15vw
  
  // Control buttons and labels
  static const double durationControlSize = 24.0;  // Golden ratio * base + 50%
  static const double buttonTextSize = baseFontSize;
  static const double captionTextSize = fontSizeSmall;
  
  // Font weights following design system
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
}

class StatisticsConstants {
  // Default periods
  static const int defaultPeriodDays = 30;        // 1 month
  static const int weekDays = 7;
  static const int fortnightDays = 14;
  static const int monthDays = 30;
  static const int quarterDays = 90;
  
  // Chart display
  static const int maxChartEntries = 30;          // Max data points on charts
  static const int minSessionsForChart = 3;       // Min sessions needed for meaningful charts
  
  // Calendar view
  static const int calendarDaysToShow = 42;       // 6 weeks
}

class AppConstants {
  // App info
  static const String appName = 'BPtimer';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Balanced Practice Timer for Meditation';
  
  // File formats
  static const String exportFileExtension = '.json';
  static const String exportMimeType = 'application/json';
  
  // URLs
  static const String githubUrl = 'https://github.com/odcpw/bptimer';
  static const String webUrl = 'https://odcpw.github.io/bptimer/';
  
  // Storage keys
  static const String recentSessionsKey = 'recent_sessions';
  static const String favoritePracticesKey = 'favorite_practices';
  static const String appSettingsKey = 'app_settings';
  static const String firstLaunchKey = 'first_launch';
  static const String dataVersionKey = 'data_version';
}

class ValidationConstants {
  // String lengths
  static const int minSMANameLength = 3;
  static const int maxSMANameLength = 100;
  static const int maxSessionNotesLength = 500;
  static const int maxPracticeNameLength = 100;
  
  // Numeric ranges
  static const int minTimesPerDay = 1;
  static const int maxTimesPerDay = 10;
  static const int minDayOfWeek = 1;  // Monday
  static const int maxDayOfWeek = 7;  // Sunday
  
  // Favorites limits
  static const int maxFavorites = 20;
}

class PlatformConstants {
  // Android specific
  static const String androidChannelId = 'meditation_reminders';
  static const String androidChannelName = 'Meditation Reminders';
  static const String androidChannelDescription = 'Notifications for Special Mindfulness Activities';
  
  // iOS specific
  static const int iosMaxPendingNotifications = 64;
  static const String iosNotificationSound = 'meditation_bell.caf';
  
  // Permission request messages
  static const String notificationPermissionRationale = 
      'This app needs notification permission to remind you of your mindfulness practices';
  static const String exactAlarmPermissionRationale = 
      'This app needs exact alarm permission for precise meditation reminders';
}

class ErrorConstants {
  // Error messages
  static const String genericError = 'An unexpected error occurred';
  static const String networkError = 'Network connection error';
  static const String storageError = 'Data storage error';
  static const String permissionError = 'Permission denied';
  
  // Database errors
  static const String dbConnectionError = 'Database connection failed';
  static const String dbQueryError = 'Database query failed';
  static const String dbMigrationError = 'Database migration failed';
  
  // Notification errors
  static const String notificationScheduleError = 'Failed to schedule notification';
  static const String notificationPermissionError = 'Notification permission required';
  static const String notificationLimitError = 'Too many pending notifications';
}
