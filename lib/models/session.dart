/// Session model - represents a completed meditation session
/// 
/// Stores all data about meditation sessions including timing, practices,
/// notes, and posture information. Provides serialization for database
/// storage and data export functionality.

library;

import 'practice.dart';
import 'practice_config.dart';

class Session {
  final String id;
  final DateTime date;
  final int duration; // in seconds
  final List<Practice> practices;
  final String? notes;
  final String? posture;
  final DateTime? completedAt;

  const Session({
    required this.id,
    required this.date,
    required this.duration,
    required this.practices,
    this.notes,
    this.posture,
    this.completedAt,
  });

  /// Create Session from database row
  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'] ?? '',
      date: DateTime.parse(map['date']),
      duration: map['duration'] ?? 0,
      practices: _parsePractices(map['practices']),
      notes: map['notes'],
      posture: map['posture'],
      completedAt: map['completed_at'] != null 
          ? DateTime.parse(map['completed_at'])
          : null,
    );
  }

  /// Create Session from JSON (for import/export)
  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] ?? '',
      date: DateTime.parse(json['date']),
      duration: json['duration'] ?? 0,
      practices: (json['practices'] as List?)
          ?.map((p) => Practice.fromJson(p))
          .toList() ?? [],
      notes: json['notes'],
      posture: json['posture'],
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  /// Convert Session to database row
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'duration': duration,
      'practices': _serializePractices(practices),
      'notes': notes,
      'posture': posture,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// Convert Session to JSON (for export)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'duration': duration,
      'practices': practices.map((p) => p.toJson()).toList(),
      'notes': notes,
      'posture': posture,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  /// Create copy of Session with modified fields
  Session copyWith({
    String? id,
    DateTime? date,
    int? duration,
    List<Practice>? practices,
    String? notes,
    String? posture,
    DateTime? completedAt,
  }) {
    return Session(
      id: id ?? this.id,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      practices: practices ?? this.practices,
      notes: notes ?? this.notes,
      posture: posture ?? this.posture,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Get formatted duration string (e.g., "10:30")
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get primary practice category
  String get primaryCategory {
    if (practices.isEmpty) return 'Unknown';
    return practices.first.category;
  }

  /// Get all unique categories in this session
  Set<String> get categories {
    return practices.map((p) => p.category).toSet();
  }

  /// Check if session contains a specific practice
  bool containsPractice(String practiceName) {
    return practices.any((p) => p.name == practiceName);
  }

  /// Check if session is from today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  /// Parse practices from JSON string stored in database
  static List<Practice> _parsePractices(String? practicesJson) {
    if (practicesJson == null || practicesJson.isEmpty) return [];
    try {
      final List<dynamic> practicesList = 
          practicesJson.split(',').map((s) => s.trim()).toList();
      
      return practicesList.map((name) {
        final practiceName = name.toString();
        return Practice(
          name: practiceName,
          category: PracticeConfig.getCategoryForPractice(practiceName),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Serialize practices to JSON string for database storage
  static String _serializePractices(List<Practice> practices) {
    return practices.map((p) => p.name).join(',');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Session &&
        other.id == id &&
        other.date == date &&
        other.duration == duration;
  }

  @override
  int get hashCode {
    return id.hashCode ^ date.hashCode ^ duration.hashCode;
  }

  @override
  String toString() {
    return 'Session(id: $id, date: $date, duration: $formattedDuration, practices: ${practices.length})';
  }
}