/// Practice model - represents a meditation practice
/// 
/// Defines individual meditation practices with their metadata including
/// category classification, duration, and descriptive information.
/// Supports hierarchical practices with subcategories and options.
class Practice {
  final String name;
  final String category;
  final int? duration; // in seconds, null for flexible duration
  final String? info;
  final String? posture;
  final Map<String, dynamic>? subcategories; // For hierarchical practices

  const Practice({
    required this.name,
    required this.category,
    this.duration,
    this.info,
    this.posture,
    this.subcategories,
  });

  /// Create Practice from JSON map (for import/export)
  factory Practice.fromJson(Map<String, dynamic> json) {
    return Practice(
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      duration: json['duration'],
      info: json['info'],
      posture: json['posture'],
      subcategories: json['subcategories'],
    );
  }

  /// Convert Practice to JSON map (for storage/export)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'duration': duration,
      'info': info,
      'posture': posture,
      'subcategories': subcategories,
    };
  }

  /// Create copy of Practice with modified fields
  Practice copyWith({
    String? name,
    String? category,
    int? duration,
    String? info,
    String? posture,
    Map<String, dynamic>? subcategories,
  }) {
    return Practice(
      name: name ?? this.name,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      info: info ?? this.info,
      posture: posture ?? this.posture,
      subcategories: subcategories ?? this.subcategories,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Practice &&
        other.name == name &&
        other.category == category &&
        other.duration == duration &&
        other.info == info &&
        other.posture == posture;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        category.hashCode ^
        duration.hashCode ^
        info.hashCode ^
        posture.hashCode;
  }

  @override
  String toString() {
    return 'Practice(name: $name, category: $category, duration: $duration)';
  }
}

/// Information about a practice including description
class PracticeInfo {
  final String? info;
  final Map<String, List<String>>? subcategories;

  const PracticeInfo({
    this.info,
    this.subcategories,
  });

  factory PracticeInfo.fromJson(Map<String, dynamic> json) {
    return PracticeInfo(
      info: json['info'],
      subcategories: json['subcategories']?.cast<String, List<String>>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'info': info,
      'subcategories': subcategories,
    };
  }
}

/// Category containing multiple related practices
class PracticeCategory {
  final String name;
  final Map<String, dynamic> practices; // Can be PracticeInfo or nested structure

  const PracticeCategory({
    required this.name,
    required this.practices,
  });

  factory PracticeCategory.fromJson(Map<String, dynamic> json) {
    return PracticeCategory(
      name: json['name'] ?? '',
      practices: json['practices'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'practices': practices,
    };
  }
}