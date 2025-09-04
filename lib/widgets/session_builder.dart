/// SessionBuilder - Unified session building component matching PWA
/// 
/// Reusable component for building meditation sessions with practice selection,
/// drag-and-drop reordering, and posture configuration. Uses result-based
/// error handling for favorites operations.
/// 
/// Key features:
/// - Practice selection from hierarchical categories  
/// - Drag-and-drop practice reordering (mobile-optimized)
/// - Posture selection interface
/// - Session state management and persistence
/// - Matches PWA SessionBuilder.js functionality exactly

library;

import 'package:flutter/material.dart';
import '../models/practice.dart';
import '../models/practice_config.dart';
import '../models/favorite_session.dart';
import '../services/favorites_service.dart';
import '../widgets/practice_info_button.dart';
import '../utils/constants.dart';

/// Configuration for SessionBuilder behavior
class SessionBuilderConfig {
  final String namespace; // 'planning' or 'postSession'
  final bool showFavorites; // Show favorites section
  final bool showAddButton; // Show "Add Practice" button
  final String addButtonText; // Text for add button
  
  const SessionBuilderConfig({
    this.namespace = 'session',
    this.showFavorites = true,
    this.showAddButton = true,
    this.addButtonText = 'Add Practice',
  });
  
  // Predefined configs for different use cases
  static const planning = SessionBuilderConfig(
    namespace: 'planning',
    showFavorites: true,
    showAddButton: true,
    addButtonText: 'Add Practice',
  );
  
  static const postSession = SessionBuilderConfig(
    namespace: 'postSession', 
    showFavorites: false,
    showAddButton: true,
    addButtonText: 'Add Practice',
  );
}

class SessionBuilder extends StatefulWidget {
  final List<Practice> initialPractices;
  final String initialPosture;
  final Function(List<Practice>, String) onUpdate;
  final SessionBuilderConfig config;

  const SessionBuilder({
    super.key,
    this.initialPractices = const [],
    this.initialPosture = 'Sitting',
    required this.onUpdate,
    this.config = SessionBuilderConfig.planning,
  });

  @override
  State<SessionBuilder> createState() => _SessionBuilderState();
}

class _SessionBuilderState extends State<SessionBuilder> {
  late List<Practice> _practices;
  late String _posture;
  bool _showPracticeSelector = false;
  String? _expandedCategory;
  
  // Favorites functionality
  final FavoritesService _favoritesService = FavoritesService();
  final TextEditingController _favoriteNameController = TextEditingController();
  List<FavoriteSession> _favorites = [];
  bool _favoritesLoading = true;

  @override
  void initState() {
    super.initState();
    _practices = List.from(widget.initialPractices);
    _posture = widget.initialPosture;
    _loadFavorites();
  }

  @override
  void dispose() {
    _favoriteNameController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SessionBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPractices != widget.initialPractices) {
      _practices = List.from(widget.initialPractices);
    }
    if (oldWidget.initialPosture != widget.initialPosture) {
      _posture = widget.initialPosture;
    }
  }

  /// Notify parent of changes
  void _notifyUpdate() {
    widget.onUpdate(_practices, _posture);
  }

  /// Select posture and update state
  void _selectPosture(String posture) {
    setState(() {
      _posture = posture;
    });
    _notifyUpdate();
  }

  /// Add practice to session
  void _addPractice(Practice practice) {
    if (!_practices.any((p) => p.name == practice.name)) {
      setState(() {
        _practices.add(practice);
      });
      _notifyUpdate();
    }
  }

  /// Remove practice from session
  void _removePractice(int index) {
    setState(() {
      _practices.removeAt(index);
    });
    _notifyUpdate();
  }

  /// Reorder practices via drag and drop
  void _reorderPractices(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final practice = _practices.removeAt(oldIndex);
      _practices.insert(newIndex, practice);
    });
    _notifyUpdate();
  }

  /// Toggle practice selector visibility
  void _togglePracticeSelector() {
    setState(() {
      _showPracticeSelector = !_showPracticeSelector;
    });
  }

  /// Load favorites from storage
  Future<void> _loadFavorites() async {
    if (widget.config.showFavorites) {
      final favoritesResult = await _favoritesService.getFavorites();
      if (mounted) {
        setState(() {
          _favorites = favoritesResult.getOrElse([]);
          _favoritesLoading = false;
        });
        
        if (favoritesResult.isFailure) {
          _showMessage('Failed to load favorites: ${favoritesResult.error}');
        }
      }
    }
  }

  /// Load favorite session into current session
  Future<void> _loadFavoriteSession(FavoriteSession favorite) async {
    setState(() {
      _practices = List.from(favorite.practices);
      _posture = favorite.posture;
    });
    
    // Mark as used and refresh favorites list
    final loadResult = await _favoritesService.loadFavorite(favorite.id);
    await _loadFavorites();
    
    _notifyUpdate();
    
    if (mounted) {
      if (loadResult.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded favorite: ${favorite.name}'),
            backgroundColor: const Color(0xFF20b2aa),
          ),
        );
      } else {
        _showMessage('Failed to load favorite: ${loadResult.error}');
      }
    }
  }

  /// Save current session as favorite
  Future<void> _saveFavorite() async {
    final name = _favoriteNameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Please enter a name for the favorite');
      return;
    }
    
    if (_practices.isEmpty) {
      _showMessage('Please select at least one practice');
      return;
    }

    final result = await _favoritesService.saveFavorite(name, _practices, _posture);
    if (result.isSuccess) {
      _favoriteNameController.clear();
      await _loadFavorites();
      _showMessage('Favorite saved successfully!');
    } else {
      _showMessage(result.error!);
    }
  }

  /// Delete a favorite session
  Future<void> _deleteFavorite(FavoriteSession favorite) async {
    final result = await _favoritesService.deleteFavorite(favorite.id);
    if (result.isSuccess) {
      await _loadFavorites();
      _showMessage('Favorite deleted');
    } else {
      _showMessage(result.error!);
    }
  }

  /// Show a message to user
  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF20b2aa),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Posture selection - PWA order: FIRST
        _buildPostureSelection(),
        const SizedBox(height: 24),
        
        // Selected practices - PWA order: SECOND  
        _buildSelectedPractices(),
        const SizedBox(height: 16),
        
        // Add practice button
        if (widget.config.showAddButton)
          _buildAddPracticeButton(),
        
        // Practice selector - PWA order: THIRD
        if (_showPracticeSelector) ...[
          const SizedBox(height: 16),
          _buildPracticeSelector(),
        ],
        
        // Favorites section (only for planning mode)
        if (widget.config.showFavorites) ...[
          const SizedBox(height: 24),
          _buildFavoritesSection(),
        ],
      ],
    );
  }

  /// Build posture selection buttons
  Widget _buildPostureSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Posture:',
          style: TextStyle(
            fontSize: TypographyConstants.fontSizeBase,
            fontWeight: TypographyConstants.fontWeightMedium,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: PracticeConfig.postures.map((posture) {
            final isSelected = _posture == posture;
            return ChoiceChip(
              label: Text(posture),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) _selectPosture(posture);
              },
              selectedColor: const Color(0xFF20b2aa),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Build selected practices with drag-and-drop reordering
  Widget _buildSelectedPractices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Session Structure:',
          style: TextStyle(
            fontSize: TypographyConstants.fontSizeBase,
            fontWeight: TypographyConstants.fontWeightMedium,
          ),
        ),
        const SizedBox(height: 8),
        
        if (_practices.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2a2a2a),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF404040)),
            ),
            child: const Text(
              'No practices selected',
              style: TextStyle(
                color: Colors.grey,
                fontSize: TypographyConstants.fontSizeBase,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ] else ...[
          // Drag-and-drop reorderable list
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: _reorderPractices,
            itemCount: _practices.length,
            itemBuilder: (context, index) {
              final practice = _practices[index];
              return Container(
                key: ValueKey(practice.name),
                margin: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.drag_handle,
                      color: Color(0xFF20b2aa),
                    ),
                    title: PracticeTextWithInfo(
                      practiceName: practice.name,
                      textStyle: TextStyle(
                        fontSize: TypographyConstants.fontSizeBase,
                        color: PracticeConfig.getCategoryColor(practice.category),
                      ),
                      infoButtonSize: 16.0,
                    ),
                    subtitle: Text(
                      PracticeConfig.getCategoryName(practice.category),
                      style: TextStyle(
                        fontSize: TypographyConstants.fontSizeSmall,
                        color: Colors.grey[400],
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: Colors.red[400],
                      onPressed: () => _removePractice(index),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  /// Build add practice button
  Widget _buildAddPracticeButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _togglePracticeSelector,
        icon: Icon(_showPracticeSelector ? Icons.expand_less : Icons.add),
        label: Text(_showPracticeSelector ? 'Hide Practices' : widget.config.addButtonText),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF20b2aa),
          side: const BorderSide(color: Color(0xFF20b2aa)),
        ),
      ),
    );
  }

  /// Build practice category selector
  Widget _buildPracticeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Browse Practices:',
          style: TextStyle(
            fontSize: TypographyConstants.fontSizeBase,
            fontWeight: TypographyConstants.fontWeightMedium,
          ),
        ),
        const SizedBox(height: 8),
        
        ...PracticeConfig.getAllCategories().map((categoryKey) {
          final categoryName = PracticeConfig.getCategoryName(categoryKey);
          final practices = PracticeConfig.getPracticesForCategory(categoryKey);
          final color = PracticeConfig.getCategoryColor(categoryKey);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              title: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      categoryName,
                      style: const TextStyle(
                        fontWeight: TypographyConstants.fontWeightMedium,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text('${practices.length} practices'),
              initiallyExpanded: _expandedCategory == categoryKey,
              onExpansionChanged: (expanded) {
                setState(() {
                  _expandedCategory = expanded ? categoryKey : null;
                });
              },
              children: practices.map((practiceName) {
                final practice = Practice(
                  name: practiceName,
                  category: categoryKey,
                );
                
                final isSelected = _practices.any((p) => p.name == practiceName);
                
                return ListTile(
                  title: Text(
                    practiceName,
                    style: TextStyle(
                      fontSize: TypographyConstants.fontSizeBase,
                      color: isSelected ? color : null,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PracticeInfoButton(
                        practiceName: practiceName,
                        size: 18.0,
                      ),
                      const SizedBox(width: 8),
                      if (isSelected) 
                        Icon(Icons.check, color: color, size: 20)
                      else
                        Icon(Icons.add, color: Colors.grey[400], size: 20),
                    ],
                  ),
                  onTap: () {
                    if (isSelected) {
                      // Find and remove the selected practice
                      final index = _practices.indexWhere((p) => p.name == practiceName);
                      if (index != -1) {
                        _removePractice(index);
                      }
                    } else {
                      _addPractice(practice);
                    }
                  },
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }

  /// Build favorites section with real favorites functionality
  Widget _buildFavoritesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Load Favorite:',
          style: TextStyle(
            fontSize: TypographyConstants.fontSizeBase,
            fontWeight: TypographyConstants.fontWeightMedium,
          ),
        ),
        const SizedBox(height: 8),
        
        // Favorites list
        if (_favoritesLoading) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2a2a2a),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF404040)),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF20b2aa),
                strokeWidth: 2,
              ),
            ),
          ),
        ] else if (_favorites.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2a2a2a),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF404040)),
            ),
            child: const Text(
              'No favorites saved',
              style: TextStyle(
                color: Colors.grey,
                fontSize: TypographyConstants.fontSizeBase,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ] else ...[
          // Show favorites (max 3 for UI space)
          ..._favorites.take(3).map((favorite) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: const Color(0xFF2a2a2a),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _loadFavoriteSession(favorite),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF404040)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              favorite.name,
                              style: const TextStyle(
                                color: Color(0xFFe5e5e5),
                                fontWeight: TypographyConstants.fontWeightMedium,
                                fontSize: TypographyConstants.fontSizeBase,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${favorite.practicesSummary} • ${favorite.posture}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: TypographyConstants.captionTextSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 18,
                        ),
                        onPressed: () => _showDeleteConfirmation(favorite),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF20b2aa),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )),
          
          if (_favorites.length > 3) ...[
            Text(
              '+${_favorites.length - 3} more favorites',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: TypographyConstants.captionTextSize,
              ),
            ),
          ],
        ],
        
        const SizedBox(height: 16),
        
        // Save favorite section
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _favoriteNameController,
                decoration: const InputDecoration(
                  hintText: 'Session name (optional)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: const TextStyle(fontSize: TypographyConstants.fontSizeBase),
                maxLength: 50,
                buildCounter: (context, {required currentLength, maxLength, required isFocused}) {
                  return null; // Hide character counter
                },
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _practices.isNotEmpty ? _saveFavorite : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF20b2aa),
                foregroundColor: Colors.black,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmation(FavoriteSession favorite) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2a2a2a),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 8)),
              ],
              border: Border.all(color: const Color(0xFF404040), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delete Favorite',
                  style: TextStyle(
                    fontSize: TypographyConstants.fontSizeLarge,
                    fontWeight: TypographyConstants.fontWeightSemiBold,
                    color: Color(0xFFe5e5e5),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to delete "${favorite.name}"?',
                  style: const TextStyle(color: Color(0xFFe5e5e5)),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFFb0b0b0))),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _deleteFavorite(favorite);
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}