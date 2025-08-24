/// FavoritesService - Manage saved session configurations
/// 
/// Handles saving, loading, and managing user's favorite session templates.
/// Uses result-based error handling and SharedPreferences for local storage.

library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite_session.dart';
import '../models/practice.dart';
import '../utils/result.dart';
import '../utils/constants.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorite_sessions';
  static const int _maxFavorites = ValidationConstants.maxFavorites;

  /// Get all favorite sessions, sorted by last used
  Future<DatabaseResult<List<FavoriteSession>>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString(_favoritesKey);
    
    if (favoritesJson == null || favoritesJson.isEmpty) {
      debugPrint('[Favorites] No favorites found in storage');
      return const Success([]);
    }

    final favoritesList = json.decode(favoritesJson) as List<dynamic>;
    final favorites = favoritesList
        .map((f) => FavoriteSession.fromJson(f as Map<String, dynamic>))
        .toList();

    // Sort by last used (most recent first)
    favorites.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    
    debugPrint('[Favorites] Loaded ${favorites.length} favorites, sorted by last used');
    return Success(favorites);
  }

  /// Save a new favorite session
  Future<SimpleResult> saveFavorite(String name, List<Practice> practices, String posture) async {
    debugPrint('[Favorites] Attempting to save: "${name.trim()}", practices=${practices.length}, posture=$posture');
    
    if (name.trim().isEmpty) {
      debugPrint('[Favorites] Save failed: name too short');
      return const Failure(FavoritesError.nameTooShort);
    }

    if (practices.isEmpty) {
      debugPrint('[Favorites] Save failed: no practices provided');
      return const Failure(FavoritesError.noPractices);
    }

    final favoritesResult = await getFavorites();
    if (favoritesResult.isFailure) {
      return Failure(favoritesResult.error!);
    }
    
    final favorites = favoritesResult.data!;
    
    // Check if we're at the limit
    if (favorites.length >= _maxFavorites) {
      debugPrint('[Favorites] Save failed: limit reached (${favorites.length}/$_maxFavorites)');
      return const Failure(FavoritesError.limitReached);
    }

    // Check for duplicate names
    if (favorites.any((f) => f.name.toLowerCase() == name.trim().toLowerCase())) {
      debugPrint('[Favorites] Save failed: name "${name.trim()}" already exists');
      return const Failure(FavoritesError.nameExists);
    }

    final newFavorite = FavoriteSession(
      id: 'fav_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      practices: List.from(practices),
      posture: posture,
      createdAt: DateTime.now(),
      lastUsed: DateTime.now(),
    );

    favorites.insert(0, newFavorite); // Add to beginning (most recent)
    final saveResult = await _saveFavoritesToStorage(favorites);
    
    if (saveResult.isSuccess) {
      debugPrint('[Favorites] Successfully saved: "${newFavorite.name}" (id=${newFavorite.id})');
    } else {
      debugPrint('[ERROR][Favorites] Failed to save to storage: "${newFavorite.name}"');
    }
    
    return saveResult;
  }

  /// Update an existing favorite session
  Future<SimpleResult> updateFavorite(String id, String name, List<Practice> practices, String posture) async {
    debugPrint('[Favorites] Attempting to update: id=$id, name="${name.trim()}", practices=${practices.length}');
    
    if (name.trim().isEmpty) {
      debugPrint('[Favorites] Update failed: name too short');
      return const Failure(FavoritesError.nameTooShort);
    }

    if (practices.isEmpty) {
      debugPrint('[Favorites] Update failed: no practices provided');
      return const Failure(FavoritesError.noPractices);
    }

    final favoritesResult = await getFavorites();
    if (favoritesResult.isFailure) {
      return Failure(favoritesResult.error!);
    }
    
    final favorites = favoritesResult.data!;
    final index = favorites.indexWhere((f) => f.id == id);
    
    if (index == -1) {
      debugPrint('[Favorites] Update failed: favorite not found (id=$id)');
      return const Failure(FavoritesError.notFound);
    }

    // Check for duplicate names (excluding current favorite)
    if (favorites.any((f) => f.id != id && f.name.toLowerCase() == name.trim().toLowerCase())) {
      debugPrint('[Favorites] Update failed: name "${name.trim()}" already exists');
      return const Failure(FavoritesError.nameExists);
    }

    final updatedFavorite = favorites[index].copyWith(
      name: name.trim(),
      practices: List.from(practices),
      posture: posture,
      lastUsed: DateTime.now(),
    );

    favorites[index] = updatedFavorite;
    final saveResult = await _saveFavoritesToStorage(favorites);
    
    if (saveResult.isSuccess) {
      debugPrint('[Favorites] Successfully updated: "${updatedFavorite.name}" (id=$id)');
    } else {
      debugPrint('[ERROR][Favorites] Failed to update storage for: "${updatedFavorite.name}"');
    }
    
    return saveResult;
  }

  /// Delete a favorite session
  Future<SimpleResult> deleteFavorite(String id) async {
    debugPrint('[Favorites] Attempting to delete: id=$id');
    
    final favoritesResult = await getFavorites();
    if (favoritesResult.isFailure) {
      debugPrint('[ERROR][Favorites] Delete failed: could not load favorites');
      return Failure(favoritesResult.error!);
    }
    
    final favorites = favoritesResult.data!;
    final initialLength = favorites.length;
    final targetFavorite = favorites.where((f) => f.id == id).firstOrNull;
    
    favorites.removeWhere((f) => f.id == id);
    
    if (favorites.length < initialLength) {
      final saveResult = await _saveFavoritesToStorage(favorites);
      if (saveResult.isSuccess) {
        debugPrint('[Favorites] Successfully deleted: "${targetFavorite?.name ?? 'Unknown'}" (id=$id)');
      } else {
        debugPrint('[ERROR][Favorites] Failed to save after delete: id=$id');
      }
      return saveResult;
    }
    
    debugPrint('[Favorites] Delete failed: favorite not found (id=$id)');
    return const Failure(FavoritesError.notFound);
  }

  /// Load and mark favorite as used
  Future<DatabaseResult<FavoriteSession?>> loadFavorite(String id) async {
    debugPrint('[Favorites] Loading and marking as used: id=$id');
    
    final favoritesResult = await getFavorites();
    if (favoritesResult.isFailure) {
      debugPrint('[ERROR][Favorites] Load failed: could not get favorites');
      return Failure(favoritesResult.error!);
    }
    
    final favorites = favoritesResult.data!;
    final index = favorites.indexWhere((f) => f.id == id);
    
    if (index == -1) {
      debugPrint('[Favorites] Load failed: favorite not found (id=$id)');
      return const Failure(FavoritesError.notFound);
    }

    final favorite = favorites[index].markAsUsed();
    favorites[index] = favorite;
    
    final saveResult = await _saveFavoritesToStorage(favorites);
    if (saveResult.isFailure) {
      debugPrint('[ERROR][Favorites] Failed to save usage update for: "${favorite.name}"');
      return Failure(saveResult.error!);
    }
    
    debugPrint('[Favorites] Successfully loaded and marked as used: "${favorite.name}" (id=$id)');
    return Success(favorite);
  }

  /// Get favorite by ID
  Future<DatabaseResult<FavoriteSession?>> getFavoriteById(String id) async {
    final favoritesResult = await getFavorites();
    if (favoritesResult.isFailure) {
      return Failure(favoritesResult.error!);
    }
    
    final favorites = favoritesResult.data!;
    final favorite = favorites.where((f) => f.id == id).firstOrNull;
    return Success(favorite);
  }

  /// Check if favorite name exists
  Future<DatabaseResult<bool>> favoriteNameExists(String name, {String? excludeId}) async {
    final favoritesResult = await getFavorites();
    if (favoritesResult.isFailure) {
      return Failure(favoritesResult.error!);
    }
    
    final favorites = favoritesResult.data!;
    final exists = favorites.any((f) => 
      f.id != excludeId && 
      f.name.toLowerCase() == name.trim().toLowerCase()
    );
    return Success(exists);
  }

  /// Get favorites count
  Future<DatabaseResult<int>> getFavoritesCount() async {
    final favoritesResult = await getFavorites();
    if (favoritesResult.isFailure) {
      return Failure(favoritesResult.error!);
    }
    
    return Success(favoritesResult.data!.length);
  }

  /// Clear all favorites (for data management/reset)
  Future<SimpleResult> clearAllFavorites() async {
    debugPrint('[Favorites] Clearing all favorites');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favoritesKey);
    
    debugPrint('[Favorites] All favorites cleared successfully');
    return const Success(true);
  }

  /// Export favorites to JSON string (for backup/sharing)
  Future<DatabaseResult<String>> exportFavorites() async {
    debugPrint('[Favorites] Starting export process');
    
    final favoritesResult = await getFavorites();
    if (favoritesResult.isFailure) {
      debugPrint('[ERROR][Favorites] Export failed: could not load favorites');
      return Failure(favoritesResult.error!);
    }
    
    final favorites = favoritesResult.data!;
    final exportData = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'favorites': favorites.map((f) => f.toJson()).toList(),
    };
    final jsonString = json.encode(exportData);
    
    debugPrint('[Favorites] Successfully exported ${favorites.length} favorites');
    return Success(jsonString);
  }

  /// Import favorites from JSON string (merge with existing)
  Future<SimpleResult> importFavorites(String jsonString, {bool replaceAll = false}) async {
    debugPrint('[Favorites] Starting import process (replaceAll=$replaceAll)');
    
    try {
      final importData = json.decode(jsonString) as Map<String, dynamic>;
      final importedFavorites = (importData['favorites'] as List<dynamic>)
          .map((f) => FavoriteSession.fromJson(f as Map<String, dynamic>))
          .toList();
      
      debugPrint('[Favorites] Parsed ${importedFavorites.length} favorites from import data');

      List<FavoriteSession> currentFavorites;
      if (replaceAll) {
        currentFavorites = [];
      } else {
        final favoritesResult = await getFavorites();
        if (favoritesResult.isFailure) {
          return Failure(favoritesResult.error!);
        }
        currentFavorites = favoritesResult.data!;
      }

      // Merge imported favorites, handling name conflicts
      int importedCount = 0;
      for (final importedFav in importedFavorites) {
        if (currentFavorites.length >= _maxFavorites) break;
        
        // Check for name conflicts
        String finalName = importedFav.name;
        int counter = 1;
        while (currentFavorites.any((f) => f.name.toLowerCase() == finalName.toLowerCase())) {
          finalName = '${importedFav.name} ($counter)';
          counter++;
        }

        final newFavorite = importedFav.copyWith(
          id: 'fav_${DateTime.now().millisecondsSinceEpoch}_$importedCount',
          name: finalName,
          lastUsed: DateTime.now(),
        );

        currentFavorites.add(newFavorite);
        importedCount++;
      }

      final saveResult = await _saveFavoritesToStorage(currentFavorites);
      
      if (saveResult.isSuccess) {
        debugPrint('[Favorites] Successfully imported $importedCount favorites (total now: ${currentFavorites.length})');
      } else {
        debugPrint('[ERROR][Favorites] Failed to save imported favorites');
      }
      
      return saveResult;
    } catch (e) {
      debugPrint('[ERROR][Favorites] Import failed: $e');
      return const Failure(FavoritesError.loadFailed);
    }
  }

  /// Save favorites list to SharedPreferences
  Future<SimpleResult> _saveFavoritesToStorage(List<FavoriteSession> favorites) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = json.encode(
        favorites.map((f) => f.toJson()).toList()
      );
      await prefs.setString(_favoritesKey, favoritesJson);
      debugPrint('[Favorites] Saved ${favorites.length} favorites to storage');
      return const Success(true);
    } catch (e) {
      debugPrint('[ERROR][Favorites] Failed to save to storage: $e');
      return const Failure(FavoritesError.saveFailed);
    }
  }
}