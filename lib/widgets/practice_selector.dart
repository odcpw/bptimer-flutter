/// PracticeSelector - Widget for selecting meditation practices
/// 
/// Allows users to browse and select meditation practices by category.
/// Integrates with TimerService to set selected practices for sessions.

library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/practice.dart';
import '../models/practice_config.dart';
import '../services/timer_service.dart';

class PracticeSelector extends StatefulWidget {
  const PracticeSelector({super.key});

  @override
  State<PracticeSelector> createState() => _PracticeSelectorState();
}

class _PracticeSelectorState extends State<PracticeSelector> {
  String? _expandedCategory;

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerService>(
      builder: (context, timerService, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Posture selection - PWA order: FIRST
            Text(
              'Posture:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: PracticeConfig.postures.map((posture) {
                final isSelected = timerService.selectedPosture == posture;
                return ChoiceChip(
                  label: Text(posture),
                  selected: isSelected,
                  onSelected: (selected) {
                    timerService.setPosture(selected ? posture : null);
                  },
                  selectedColor: const Color(0xFF20b2aa),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),

            // Selected practices summary - PWA order: SECOND
            if (timerService.selectedPractices.isNotEmpty) ...[
              Text(
                'Session Structure:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: timerService.selectedPractices.map((practice) {
                  return Chip(
                    label: Text(
                      practice.name,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: PracticeConfig.getCategoryColor(practice.category),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => timerService.removePractice(practice),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Practice categories - PWA order: THIRD
            Text(
              'Browse Practices:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            
            // Category expansion tiles
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
                          style: const TextStyle(fontWeight: FontWeight.w500),
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
                      info: PracticeConfig.getPracticeInfo(practiceName),
                    );
                    
                    final isSelected = timerService.selectedPractices
                        .any((p) => p.name == practiceName);
                    
                    return ListTile(
                      title: Text(
                        practiceName,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? color : null,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Info button for each practice
                          IconButton(
                            icon: Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Colors.grey[400],
                            ),
                            onPressed: () => _showPracticeInfo(context, practice),
                          ),
                          if (isSelected) 
                            Icon(Icons.check, color: color, size: 20),
                        ],
                      ),
                      onTap: () {
                        if (isSelected) {
                          timerService.removePractice(practice);
                        } else {
                          timerService.addPractice(practice);
                        }
                      },
                    );
                  }).toList(),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  /// Show practice information dialog
  void _showPracticeInfo(BuildContext context, Practice practice) {
    final info = practice.info;
    if (info == null || info.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(practice.name),
        content: SingleChildScrollView(
          child: Text(
            info,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}