/// PracticeConfig - Central configuration for all meditation practices and categories
/// 
/// Direct translation from PWA's PracticeConfig.js with all meditation practices,
/// categories, colors, and helper functions. Provides static configuration and
/// lookup utilities for practice categorization and metadata.

library;

import 'dart:ui';
import '../services/content_service.dart';

class PracticeConfig {
  /// Static cache for preloaded content
  static List<PracticeCategory>? _categories;
  static Map<String, String>? _practiceToCategory;
  static Map<String, String>? _practiceIdToName;
  static Map<String, String>? _practiceNameToId;
  static bool _initialized = false;

  /// Initialize PracticeConfig by preloading all content from manifest
  /// Call this once at app startup before using any other methods
  static Future<void> initialize() async {
    if (_initialized) return;

    final contentService = ContentService();
    
    // Load manifest
    final manifestResult = await contentService.loadManifest();
    if (manifestResult.isFailure) {
      throw Exception('Failed to load content manifest: ${manifestResult.error}');
    }

    _categories = manifestResult.data!.practiceCategories;
    
    // Build all mappings
    await _buildPracticeMappings(contentService);
    
    _initialized = true;
  }

  /// Build all practice name and category mappings
  static Future<void> _buildPracticeMappings(ContentService contentService) async {
    _practiceToCategory = {};
    _practiceIdToName = {};
    _practiceNameToId = {};

    for (final category in _categories!) {
      for (final practiceId in category.practices) {
        // Get display name for this practice ID
        final nameResult = await contentService.getPracticeName(practiceId);
        if (nameResult.isSuccess) {
          final displayName = nameResult.data!;
          
          // Build mappings
          _practiceToCategory![displayName] = category.id;
          _practiceIdToName![practiceId] = displayName;
          _practiceNameToId![displayName] = practiceId;
        }
      }
    }
  }

  /// Color scheme for practice categories used in charts and UI
  static const Map<String, Color> categoryColors = {
    'mindfulness': Color(0xFF06B6D4),      // Cyan/teal
    'compassion': Color(0xFFEC4899),       // Pink
    'sympatheticJoy': Color(0xFFF59E0B),   // Amber/gold
    'equanimity': Color(0xFF8B5CF6),       // Purple
    'wiseReflection': Color(0xFF10B981),   // Emerald green
  };

  /// Available meditation postures
  static const List<String> postures = [
    'Sitting', 
    'Standing', 
    'Walking'
  ];

  /// Get the category for a given practice name
  /// Returns category key for the practice (synchronous after initialization)
  static String getCategoryForPractice(String practiceName) {
    assert(_initialized, 'PracticeConfig.initialize() must be called first');
    return _practiceToCategory![practiceName] ?? 'wise_reflection';
  }

  /// Get practice info for a given practice name
  /// This remains async since it's only used in dialogs that can show loading
  static Future<String?> getPracticeInfo(String practiceName) async {
    assert(_initialized, 'PracticeConfig.initialize() must be called first');
    
    final practiceId = _practiceNameToId![practiceName];
    if (practiceId == null) return null;

    final contentService = ContentService();
    final result = await contentService.getPracticeInfo(practiceId);
    return result.isSuccess ? result.data : null;
  }

  /// Get all practice names for a given category
  static List<String> getPracticesForCategory(String categoryKey) {
    assert(_initialized, 'PracticeConfig.initialize() must be called first');
    
    final category = _categories!.firstWhere(
      (cat) => cat.id == categoryKey,
      orElse: () => const PracticeCategory(id: '', name: '', practices: []),
    );
    
    // Convert practice IDs to display names
    return category.practices
        .map((practiceId) => _practiceIdToName![practiceId])
        .where((name) => name != null)
        .cast<String>()
        .toList();
  }

  /// Get all category keys
  static List<String> getAllCategories() {
    assert(_initialized, 'PracticeConfig.initialize() must be called first');
    return _categories!.map((cat) => cat.id).toList();
  }

  /// Get human-readable category name
  static String getCategoryName(String categoryKey) {
    assert(_initialized, 'PracticeConfig.initialize() must be called first');
    
    final category = _categories!.firstWhere(
      (cat) => cat.id == categoryKey,
      orElse: () => PracticeCategory(id: categoryKey, name: categoryKey, practices: const []),
    );
    return category.name;
  }

  /// Check if a practice name exists in the configuration
  static bool practiceExists(String practiceName) {
    assert(_initialized, 'PracticeConfig.initialize() must be called first');
    return _practiceToCategory!.containsKey(practiceName);
  }

  /// Get all practice names across all categories
  static List<String> getAllPractices() {
    assert(_initialized, 'PracticeConfig.initialize() must be called first');
    return _practiceToCategory!.keys.toList();
  }

  /// Get color for a category (remains static as it's just UI styling)
  static Color getCategoryColor(String categoryKey) {
    return categoryColors[categoryKey] ?? const Color(0xFF6B7280); // Default gray
  }
}