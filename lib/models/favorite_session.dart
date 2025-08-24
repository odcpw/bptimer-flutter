/// FavoriteSession - Model for saved session configurations
/// 
/// Represents a user-saved session template that can be loaded
/// into the session planner. Includes practices, posture, and metadata.

library;

import 'package:flutter/foundation.dart';
import 'practice.dart';

@immutable
class FavoriteSession {
  final String id;
  final String name;
  final List<Practice> practices;
  final String posture;
  final DateTime createdAt;
  final DateTime lastUsed;

  const FavoriteSession({
    required this.id,
    required this.name,
    required this.practices,
    required this.posture,
    required this.createdAt,
    required this.lastUsed,
  });

  /// Create FavoriteSession from JSON
  factory FavoriteSession.fromJson(Map<String, dynamic> json) {
    return FavoriteSession(
      id: json['id'] as String,
      name: json['name'] as String,
      practices: (json['practices'] as List<dynamic>)
          .map((p) => Practice.fromJson(p as Map<String, dynamic>))
          .toList(),
      posture: json['posture'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsed: DateTime.parse(json['lastUsed'] as String),
    );
  }

  /// Convert FavoriteSession to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'practices': practices.map((p) => p.toJson()).toList(),
      'posture': posture,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed.toIso8601String(),
    };
  }

  /// Create a copy with some fields updated
  FavoriteSession copyWith({
    String? id,
    String? name,
    List<Practice>? practices,
    String? posture,
    DateTime? createdAt,
    DateTime? lastUsed,
  }) {
    return FavoriteSession(
      id: id ?? this.id,
      name: name ?? this.name,
      practices: practices ?? this.practices,
      posture: posture ?? this.posture,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  /// Update last used timestamp
  FavoriteSession markAsUsed() {
    return copyWith(lastUsed: DateTime.now());
  }

  /// Get practices summary for display
  String get practicesSummary {
    if (practices.isEmpty) return 'No practices';
    if (practices.length == 1) return practices.first.name;
    return '${practices.first.name} +${practices.length - 1} more';
  }

  /// Get display duration (estimated based on practice count)
  String get estimatedDuration {
    if (practices.isEmpty) return '5 min';
    final estimatedMinutes = practices.length * 5; // 5 min per practice estimate
    return '$estimatedMinutes min';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoriteSession &&
        other.id == id &&
        other.name == name &&
        listEquals(other.practices, practices) &&
        other.posture == posture &&
        other.createdAt == createdAt &&
        other.lastUsed == lastUsed;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      practices,
      posture,
      createdAt,
      lastUsed,
    );
  }

  @override
  String toString() {
    return 'FavoriteSession(id: $id, name: $name, practices: ${practices.length}, posture: $posture)';
  }
}