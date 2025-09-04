/// ContentService - Loads and manages markdown content from assets
/// 
/// Provides centralized access to practice info, about sections, and other 
/// content stored as markdown files. Handles manifest loading, caching,
/// and on-demand content loading for the app's content system.

library;

import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import '../utils/result.dart';

/// Represents a practice category with its metadata
class PracticeCategory {
  final String id;
  final String name;
  final List<String> practices;

  const PracticeCategory({
    required this.id,
    required this.name,
    required this.practices,
  });

  factory PracticeCategory.fromYaml(String id, Map<dynamic, dynamic> yaml) {
    return PracticeCategory(
      id: id,
      name: yaml['name'] as String? ?? id,
      practices: (yaml['practices'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );
  }
}

/// Represents content manifest structure
class ContentManifest {
  final List<PracticeCategory> practiceCategories;
  final List<String> aboutSections;
  final String smaInfo;

  const ContentManifest({
    required this.practiceCategories,
    required this.aboutSections,
    required this.smaInfo,
  });

  factory ContentManifest.fromYaml(Map<dynamic, dynamic> yaml) {
    final categories = <PracticeCategory>[];
    final practiceCategories = yaml['practice_categories'] as List<dynamic>?;
    
    if (practiceCategories != null) {
      for (final category in practiceCategories) {
        if (category is Map<dynamic, dynamic>) {
          final id = category['id'] as String?;
          if (id != null) {
            categories.add(PracticeCategory.fromYaml(id, category));
          }
        }
      }
    }

    return ContentManifest(
      practiceCategories: categories,
      aboutSections: (yaml['about_sections'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      smaInfo: yaml['sma_info'] as String? ?? 'sma_info',
    );
  }
}

/// Content with parsed frontmatter and body
class ContentWithMeta {
  final String title;
  final String content;
  final Map<String, dynamic> metadata;

  const ContentWithMeta({
    required this.title,
    required this.content,
    required this.metadata,
  });
}

class ContentService {
  static final ContentService _instance = ContentService._internal();
  factory ContentService() => _instance;
  ContentService._internal();

  ContentManifest? _manifest;
  final Map<String, String> _contentCache = {};
  final Map<String, ContentWithMeta> _parsedContentCache = {};

  /// Load and cache the content manifest
  Future<Result<ContentManifest, String>> loadManifest() async {
    if (_manifest != null) {
      return Success(_manifest!);
    }

    try {
      final yamlString = await rootBundle.loadString('assets/content/manifest.yaml');
      final dynamic yamlData = loadYaml(yamlString);
      
      if (yamlData is Map<dynamic, dynamic>) {
        _manifest = ContentManifest.fromYaml(yamlData);
        return Success(_manifest!);
      } else {
        return Failure('Invalid manifest format');
      }
    } catch (e) {
      return Failure('Failed to load manifest: $e');
    }
  }

  /// Get practice info content for a specific practice
  Future<Result<String, String>> getPracticeInfo(String practiceId) async {
    final manifestResult = await loadManifest();
    if (manifestResult.isFailure) {
      return Failure(manifestResult.error!);
    }

    final manifest = manifestResult.data!;
    
    // Find which category this practice belongs to
    String? categoryId;
    for (final category in manifest.practiceCategories) {
      if (category.practices.contains(practiceId)) {
        categoryId = category.id;
        break;
      }
    }

    if (categoryId == null) {
      return Failure('Practice not found in manifest: $practiceId');
    }

    final assetPath = 'assets/content/practices/$categoryId/$practiceId.md';
    return await _loadAndParseContent(assetPath);
  }

  /// Get about content (single file with all sections)
  Future<Result<String, String>> getAboutContent() async {
    const assetPath = 'assets/content/about.md';
    return await _loadAndParseContent(assetPath);
  }

  /// Get SMA info content
  Future<Result<String, String>> getSmaInfo() async {
    const assetPath = 'assets/content/sma_info.md';
    return await _loadAndParseContent(assetPath);
  }

  /// Load content from asset path and extract just the body (no frontmatter)
  Future<Result<String, String>> _loadAndParseContent(String assetPath) async {
    // Check cache first
    if (_contentCache.containsKey(assetPath)) {
      return Success(_contentCache[assetPath]!);
    }

    try {
      final content = await rootBundle.loadString(assetPath);
      final parsed = _parseMarkdownWithFrontmatter(content);
      
      // Cache the content body
      _contentCache[assetPath] = parsed.content;
      _parsedContentCache[assetPath] = parsed;
      
      return Success(parsed.content);
    } catch (e) {
      return Failure('Failed to load content from $assetPath: $e');
    }
  }

  /// Parse markdown content with YAML frontmatter
  ContentWithMeta _parseMarkdownWithFrontmatter(String content) {
    final lines = content.split('\n');
    
    // Check if content starts with frontmatter
    if (lines.isNotEmpty && lines[0].trim() == '---') {
      // Find end of frontmatter
      int endIndex = -1;
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim() == '---') {
          endIndex = i;
          break;
        }
      }
      
      if (endIndex > 0) {
        // Extract frontmatter
        final frontmatterLines = lines.sublist(1, endIndex);
        final frontmatterContent = frontmatterLines.join('\n');
        
        // Extract body content
        final bodyLines = lines.sublist(endIndex + 1);
        final bodyContent = bodyLines.join('\n').trim();
        
        // Parse frontmatter YAML
        Map<String, dynamic> metadata = {};
        String title = '';
        
        try {
          final dynamic yamlData = loadYaml(frontmatterContent);
          if (yamlData is Map) {
            metadata = Map<String, dynamic>.from(yamlData);
            title = metadata['title'] as String? ?? '';
          }
        } catch (e) {
          // If frontmatter parsing fails, just use the content as-is
        }
        
        return ContentWithMeta(
          title: title,
          content: bodyContent,
          metadata: metadata,
        );
      }
    }
    
    // No frontmatter found, return content as-is
    return ContentWithMeta(
      title: '',
      content: content.trim(),
      metadata: {},
    );
  }

  /// Get all practice categories from manifest
  Future<Result<List<PracticeCategory>, String>> getPracticeCategories() async {
    final manifestResult = await loadManifest();
    if (manifestResult.isFailure) {
      return Failure(manifestResult.error!);
    }
    
    return Success(manifestResult.data!.practiceCategories);
  }

  /// Get practice name for a practice ID (from frontmatter title)
  Future<Result<String, String>> getPracticeName(String practiceId) async {
    final manifestResult = await loadManifest();
    if (manifestResult.isFailure) {
      return Failure(manifestResult.error!);
    }

    final manifest = manifestResult.data!;
    
    // Find which category this practice belongs to
    String? categoryId;
    for (final category in manifest.practiceCategories) {
      if (category.practices.contains(practiceId)) {
        categoryId = category.id;
        break;
      }
    }

    if (categoryId == null) {
      return Failure('Practice not found: $practiceId');
    }

    final assetPath = 'assets/content/practices/$categoryId/$practiceId.md';
    
    // Check parsed cache first
    if (_parsedContentCache.containsKey(assetPath)) {
      final cached = _parsedContentCache[assetPath]!;
      return Success(cached.title.isNotEmpty ? cached.title : practiceId);
    }

    // Load and parse to get title
    final contentResult = await _loadAndParseContent(assetPath);
    if (contentResult.isFailure) {
      return Failure(contentResult.error!);
    }

    final parsed = _parsedContentCache[assetPath]!;
    return Success(parsed.title.isNotEmpty ? parsed.title : practiceId);
  }

  /// Clear all caches (useful for testing or memory management)
  void clearCache() {
    _contentCache.clear();
    _parsedContentCache.clear();
    _manifest = null;
  }
}