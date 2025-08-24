/// SMA (Special Mindfulness Activity) model
/// 
/// Represents user-defined mindfulness reminders for daily activities like
/// "opening doors mindfully" or "breathing awareness at traffic lights".
/// Handles scheduling configuration and notification settings.
class SMA {
  final String id;
  final String name;
  final String frequency; // 'monthly', 'weekly', 'daily', 'multiple'
  final int timesPerDay; // For 'multiple' frequency
  final List<String> reminderWindows; // 'morning', 'midday', 'afternoon', 'evening'
  final bool notificationsEnabled;
  final int dayOfWeek; // 1-7 for weekly frequency (1 = Monday)
  final DateTime createdAt;
  final DateTime? lastReminderAt;

  const SMA({
    required this.id,
    required this.name,
    required this.frequency,
    this.timesPerDay = 1,
    this.reminderWindows = const ['morning', 'midday', 'afternoon', 'evening'],
    this.notificationsEnabled = true,
    this.dayOfWeek = 1, // Default to Monday
    required this.createdAt,
    this.lastReminderAt,
  });

  /// Create SMA from database row
  factory SMA.fromMap(Map<String, dynamic> map) {
    return SMA(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      frequency: map['frequency'] ?? 'daily',
      timesPerDay: map['times_per_day'] ?? 1,
      reminderWindows: _parseReminderWindows(map['reminder_windows']),
      notificationsEnabled: (map['notifications_enabled'] ?? 1) == 1,
      dayOfWeek: map['day_of_week'] ?? 1,
      createdAt: DateTime.parse(map['created_at']),
      lastReminderAt: map['last_reminder_at'] != null
          ? DateTime.parse(map['last_reminder_at'])
          : null,
    );
  }

  /// Create SMA from JSON (for import/export)
  factory SMA.fromJson(Map<String, dynamic> json) {
    return SMA(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      frequency: json['frequency'] ?? 'daily',
      timesPerDay: json['timesPerDay'] ?? 1,
      reminderWindows: List<String>.from(json['reminderWindows'] ?? 
          ['morning', 'midday', 'afternoon', 'evening']),
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      dayOfWeek: json['dayOfWeek'] ?? 1,
      createdAt: DateTime.parse(json['createdAt']),
      lastReminderAt: json['lastReminderAt'] != null
          ? DateTime.parse(json['lastReminderAt'])
          : null,
    );
  }

  /// Convert SMA to database row
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'frequency': frequency,
      'times_per_day': timesPerDay,
      'reminder_windows': _serializeReminderWindows(reminderWindows),
      'notifications_enabled': notificationsEnabled ? 1 : 0,
      'day_of_week': dayOfWeek,
      'created_at': createdAt.toIso8601String(),
      'last_reminder_at': lastReminderAt?.toIso8601String(),
    };
  }

  /// Convert SMA to JSON (for export)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'frequency': frequency,
      'timesPerDay': timesPerDay,
      'reminderWindows': reminderWindows,
      'notificationsEnabled': notificationsEnabled,
      'dayOfWeek': dayOfWeek,
      'createdAt': createdAt.toIso8601String(),
      'lastReminderAt': lastReminderAt?.toIso8601String(),
    };
  }

  /// Create copy of SMA with modified fields
  SMA copyWith({
    String? id,
    String? name,
    String? frequency,
    int? timesPerDay,
    List<String>? reminderWindows,
    bool? notificationsEnabled,
    int? dayOfWeek,
    DateTime? createdAt,
    DateTime? lastReminderAt,
  }) {
    return SMA(
      id: id ?? this.id,
      name: name ?? this.name,
      frequency: frequency ?? this.frequency,
      timesPerDay: timesPerDay ?? this.timesPerDay,
      reminderWindows: reminderWindows ?? this.reminderWindows,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      createdAt: createdAt ?? this.createdAt,
      lastReminderAt: lastReminderAt ?? this.lastReminderAt,
    );
  }

  /// Get human-readable frequency description
  String get frequencyDescription {
    switch (frequency) {
      case 'monthly':
        return 'Monthly';
      case 'weekly':
        return 'Weekly (${_getDayName(dayOfWeek)})';
      case 'daily':
        return 'Daily';
      case 'multiple':
        return '${reminderWindows.length} times per day';
      default:
        return frequency;
    }
  }

  /// Get reminder windows as human-readable string
  String get reminderWindowsDescription {
    if (reminderWindows.isEmpty) return 'No specific times';
    return reminderWindows.map(_capitalizeFirst).join(', ');
  }

  /// Check if SMA is due for a reminder (basic check)
  bool get isDue {
    if (!notificationsEnabled) return false;
    if (lastReminderAt == null) return true;

    final now = DateTime.now();
    final timeSinceLastReminder = now.difference(lastReminderAt!);

    switch (frequency) {
      case 'monthly':
        return timeSinceLastReminder.inDays >= 30;
      case 'weekly':
        return timeSinceLastReminder.inDays >= 7;
      case 'daily':
        return timeSinceLastReminder.inDays >= 1;
      case 'multiple':
        // For multiple daily, check if we've had any reminders today
        return !_isSameDay(lastReminderAt!, now);
      default:
        return false;
    }
  }

  /// Mark as reminded now
  SMA markAsReminded() {
    return copyWith(lastReminderAt: DateTime.now());
  }

  /// Parse reminder windows from comma-separated string
  static List<String> _parseReminderWindows(String? windowsStr) {
    if (windowsStr == null || windowsStr.isEmpty) {
      return ['morning', 'midday', 'afternoon', 'evening'];
    }
    return windowsStr.split(',').map((s) => s.trim()).toList();
  }

  /// Serialize reminder windows to comma-separated string
  static String _serializeReminderWindows(List<String> windows) {
    return windows.join(',');
  }

  /// Get day name from day number (1-7)
  static String _getDayName(int dayOfWeek) {
    const days = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday', 
      'Thursday', 'Friday', 'Saturday'
    ];
    return days[dayOfWeek % 7];
  }

  /// Capitalize first letter of string
  static String _capitalizeFirst(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }

  /// Check if two dates are on the same day
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SMA &&
        other.id == id &&
        other.name == name &&
        other.frequency == frequency;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ frequency.hashCode;
  }

  @override
  String toString() {
    return 'SMA(id: $id, name: $name, frequency: $frequency, enabled: $notificationsEnabled)';
  }
}