/// TimerScreen - Main meditation timer interface
/// 
/// Displays circular progress timer with duration controls, practice selection,
/// and session management. Core screen of the meditation timer app.

library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/timer_service.dart';
import '../services/database_service.dart';
import '../models/session.dart';
import '../models/practice.dart';
import '../widgets/circular_timer.dart';
import '../widgets/session_builder.dart';
import '../widgets/practice_info_button.dart';
import '../utils/constants.dart';
import '../ui/layout.dart';
import '../ui/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_dialog.dart';
import '../utils/result.dart';
import '../widgets/section.dart';
import '../widgets/info_block.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<TimerService>(
        builder: (context, timerService, child) {
          return SafeArea(
            child: AppScaffoldBody(
              padding: const EdgeInsets.symmetric(vertical: Spacing.s16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                  const SizedBox(height: UIConstants.buttonSpacing),
                  
                  // Main timer display - centered like PWA
                  CircularTimer(),
                  const SizedBox(height: 40),

                  // Duration controls - horizontal like PWA
                  _buildDurationControls(context, timerService),
                  const SizedBox(height: UIConstants.buttonSpacing * 1.8),

                  // Timer control buttons like PWA - separate start/pause and stop
                  _buildTimerControls(context, timerService),
                  const SizedBox(height: 40),

                  // Collapsible Practice section like PWA
                  if (!timerService.isRunning && !timerService.isPaused)
                    _buildCollapsiblePracticeSection(context, timerService),

                  // Session summary when running or paused
                  if (timerService.isRunning || timerService.isPaused)
                    _buildSessionSummary(context, timerService),

                  // Completion screen
                  if (timerService.isCompleted)
                    _buildCompletionScreen(context, timerService),
                  
                  // Recent sessions at bottom like PWA
                  if (!timerService.isRunning && !timerService.isPaused)
                    _buildRecentSessions(context),
                  
                  const SizedBox(height: 100), // Extra space for scrolling
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build duration adjustment controls - PWA style horizontal layout
  Widget _buildDurationControls(BuildContext context, TimerService timerService) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Decrease button "-5"
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF404040)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: MaterialButton(
            onPressed: timerService.isRunning ? null : timerService.decreaseDuration,
            minWidth: UIConstants.buttonWidth * 0.4,
            height: 48,
            child: const Text(
              '-5',
              style: TextStyle(
                fontSize: TypographyConstants.buttonTextSize,
                fontWeight: TypographyConstants.fontWeightMedium,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 24),
        
        // Duration display with golden ratio sizing
        Text(
          '${timerService.duration ~/ 60} min',
          style: const TextStyle(
            fontSize: TypographyConstants.durationControlSize,
            fontWeight: TypographyConstants.fontWeightLight,
            color: Color(0xFFe5e5e5),
          ),
        ),
        
        const SizedBox(width: 24),
        
        // Increase button "+5"
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF404040)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: MaterialButton(
            onPressed: timerService.isRunning ? null : timerService.increaseDuration,
            minWidth: UIConstants.buttonWidth * 0.4,
            height: 48,
            child: const Text(
              '+5',
              style: TextStyle(
                fontSize: TypographyConstants.buttonTextSize,
                fontWeight: TypographyConstants.fontWeightMedium,
              ),
            ),
          ),
        ),
      ],
    );
  }


  /// Build timer control buttons - PWA style with separate start/pause and stop buttons
  Widget _buildTimerControls(BuildContext context, TimerService timerService) {
    final buttons = <Widget>[
      AppButton.primary(
        _getMainButtonText(timerService),
        icon: _getMainButtonIcon(timerService),
        onPressed: _getMainButtonAction(timerService),
        size: AppButtonSize.lg,
      ),
    ];
    if (timerService.isRunning || timerService.isPaused) {
      buttons.add(
        AppButton.danger(
          'Stop',
          icon: Icons.stop,
          onPressed: () => _showPostSessionModal(context, timerService),
          size: AppButtonSize.lg,
        ),
      );
    }
    return ButtonRow(children: buttons);
  }

  String _getMainButtonText(TimerService timerService) {
    switch (timerService.state) {
      case TimerState.stopped:
      case TimerState.completed:
        return 'Start';
      case TimerState.running:
        return 'Pause';
      case TimerState.paused:
        return 'Resume';
    }
  }

  IconData _getMainButtonIcon(TimerService timerService) {
    switch (timerService.state) {
      case TimerState.stopped:
      case TimerState.completed:
      case TimerState.paused:
        return Icons.play_arrow;
      case TimerState.running:
        return Icons.pause;
    }
  }

  VoidCallback? _getMainButtonAction(TimerService timerService) {
    switch (timerService.state) {
      case TimerState.stopped:
      case TimerState.completed:
        return () => timerService.start();
      case TimerState.running:
        return () => timerService.pause();
      case TimerState.paused:
        return () => timerService.resume();
    }
  }

  /// Build collapsible practice section - PWA style
  Widget _buildCollapsiblePracticeSection(BuildContext context, TimerService timerService) {
    return Section(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        leading: const Icon(Icons.play_arrow, size: 16),
        title: const Text(
          'Plan Session (Optional)',
          style: TextStyle(
            fontSize: TypographyConstants.buttonTextSize,
            fontWeight: TypographyConstants.fontWeightRegular,
          ),
        ),
        children: [
          const SizedBox(height: Spacing.s8),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SessionBuilder(
              initialPractices: timerService.selectedPractices,
              initialPosture: timerService.selectedPosture ?? 'Sitting',
              config: SessionBuilderConfig.planning,
              onUpdate: (practices, posture) {
                // Update timer service with new session configuration
                timerService.clearPractices();
                for (final practice in practices) {
                  timerService.addPractice(practice);
                }
                timerService.setPosture(posture);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build recent sessions section - PWA style with real data
  Widget _buildRecentSessions(BuildContext context) {
    return FutureBuilder<DatabaseResult<List<Session>>>(
      future: DatabaseService().getRecentSessions(7), // Last 7 days
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Section(title: 'Recent Sessions', child: InfoBlock(state: InfoState.loading));
        }
        if (snapshot.hasError || (snapshot.hasData && snapshot.data!.isFailure)) {
          return const Section(
            title: 'Recent Sessions',
            child: InfoBlock(state: InfoState.error, icon: Icons.error_outline, title: 'Could not load', message: 'Error loading recent sessions'),
          );
        }
        final sessions = snapshot.data?.getOrElse([]) ?? [];
        if (sessions.isEmpty) {
          return const Section(
            title: 'Recent Sessions',
            child: InfoBlock(state: InfoState.empty, icon: Icons.history, title: 'No recent sessions', message: 'Your latest sessions will appear here'),
          );
        }

        return Section(
          title: 'Recent Sessions',
          child: Column(
            children: sessions.take(3).map((s) => _buildRecentSessionItem(context, s)).toList(),
          ),
        );
      },
    );
  }

  /// Build individual recent session item
  Widget _buildRecentSessionItem(BuildContext context, Session session) {
    final timeSince = _getTimeSince(session.date);
    final durationText = '${session.duration ~/ 60} min';
    final practicesText = session.practices.isNotEmpty 
        ? session.practices.first.name 
        : 'No practices recorded';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _loadSessionAsTemplate(context, session),
          child: Container(
            padding: const EdgeInsets.all(16),
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
                      // Practice name with info button
                      if (session.practices.isNotEmpty)
                        PracticeTextWithInfo(
                          practiceName: practicesText,
                          textStyle: const TextStyle(
                            color: Color(0xFFe5e5e5),
                            fontWeight: TypographyConstants.fontWeightMedium,
                          ),
                          infoButtonSize: 16.0,
                        )
                      else
                        Text(
                          practicesText,
                          style: const TextStyle(
                            color: Color(0xFFe5e5e5),
                            fontWeight: TypographyConstants.fontWeightMedium,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '$timeSince • $durationText • ${session.posture}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: TypographyConstants.captionTextSize,
                        ),
                      ),
                      if (session.practices.length > 1) ...[
                        const SizedBox(height: 4),
                        Text(
                          '+${session.practices.length - 1} more practices',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: TypographyConstants.fontSizeXSmall,
                          ),
                        ),
                      ],
                    ],
                  ),
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
    );
  }

  /// Get human-readable time since session
  String _getTimeSince(DateTime sessionDate) {
    final now = DateTime.now();
    final difference = now.difference(sessionDate);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min ago';
    } else {
      return 'Just now';
    }
  }

  /// Load session as template for current timer
  void _loadSessionAsTemplate(BuildContext context, Session session) {
    final timerService = Provider.of<TimerService>(context, listen: false);
    
    // Clear current practices and load from session
    timerService.clearPractices();
    for (final practice in session.practices) {
      timerService.addPractice(practice);
    }
    timerService.setPosture(session.posture);
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Loaded session template: ${session.practices.isNotEmpty ? session.practices.first.name : "Session"}',
        ),
        backgroundColor: const Color(0xFF20b2aa),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Build session summary for running/paused timer
  Widget _buildSessionSummary(BuildContext context, TimerService timerService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Session',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Practices with individual info buttons
            if (timerService.selectedPractices.isNotEmpty) ...[
              const Text(
                'Practices:',
                style: TextStyle(
                  fontSize: TypographyConstants.fontSizeBase,
                  fontWeight: TypographyConstants.fontWeightMedium,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: timerService.selectedPractices.map((practice) {
                  return Chip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          practice.name,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        PracticeInfoButton(
                          practiceName: practice.name,
                          size: 14.0,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                    backgroundColor: const Color.fromARGB(51, 32, 178, 170),
                    side: const BorderSide(color: Color(0xFF20b2aa)),
                  );
                }).toList(),
              ),
            ] else ...[
              Text(
                'Practices: ${timerService.getPracticeSummary()}',
                style: const TextStyle(fontSize: TypographyConstants.fontSizeBase),
              ),
            ],
            
            const SizedBox(height: 8),
            if (timerService.selectedPosture != null)
              Text(
                'Posture: ${timerService.selectedPosture}',
                style: const TextStyle(fontSize: TypographyConstants.fontSizeBase),
              ),
          ],
        ),
      ),
    );
  }

  /// Build completion screen
  Widget _buildCompletionScreen(BuildContext context, TimerService timerService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(
              Icons.celebration,
              size: 48,
              color: Color(0xFF20b2aa),
            ),
            const SizedBox(height: 16),
            Text(
              'Session Complete!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Well done! You meditated for ${timerService.formattedElapsed}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Record what you actually practiced?',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Show individual practices with info buttons
            if (timerService.selectedPractices.isNotEmpty) ...[
              const Text(
                'Practices completed:',
                style: TextStyle(
                  fontSize: TypographyConstants.fontSizeBase,
                  fontWeight: TypographyConstants.fontWeightMedium,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: timerService.selectedPractices.map((practice) {
                  return Chip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          practice.name,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        PracticeInfoButton(
                          practiceName: practice.name,
                          size: 14.0,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                    backgroundColor: const Color.fromARGB(51, 16, 185, 129),
                    side: const BorderSide(color: Color(0xFF10b981)),
                  );
                }).toList(),
              ),
            ] else ...[
              Text(
                timerService.getPracticeSummary(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            
            // Action buttons
            Column(
              children: [
                AppButton.primary('Record Session', icon: Icons.edit, onPressed: () => _showPostSessionModal(context, timerService), fullWidth: true),
                const SizedBox(height: Spacing.s12),
                AppButton.outline('Save Time Only', icon: Icons.schedule, onPressed: () => _saveTimeOnlyWithElapsedCapture(context, timerService), fullWidth: true),
                const SizedBox(height: Spacing.s12),
                AppButton.quiet('Start New Session', icon: Icons.refresh, onPressed: () {
                  timerService.stopBellSound(); // Stop bell when starting new session
                  timerService.reset();
                }, fullWidth: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show post-session recording modal - PWA style
  void _showPostSessionModal(BuildContext context, TimerService timerService) {
    // Capture elapsed time BEFORE stopping to preserve it for session saving
    final elapsedSeconds = timerService.elapsed;
    
    // Stop timer and bell sound first like PWA
    timerService.stopBellSound(); // Stop bell immediately when user interacts
    timerService.stop(); // Fire and forget for UI responsiveness
    
    List<Practice> postSessionPractices = List.from(timerService.selectedPractices);
    String postSessionPosture = timerService.selectedPosture ?? 'Sitting';
    AppDialog.show(
      context: context,
      title: 'What did you practice?',
      showClose: true,
      content: SessionBuilder(
        initialPractices: postSessionPractices,
        initialPosture: postSessionPosture,
        config: SessionBuilderConfig.postSession,
        onUpdate: (practices, posture) {
          postSessionPractices = practices;
          postSessionPosture = posture;
        },
      ),
      actions: [
        AppButton.primary(
          'Save Session',
          onPressed: () {
            if (postSessionPractices.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Select at least one practice or use "Save Time Only"'),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            Navigator.of(context).pop();
            _saveSessionWithPractices(
              context,
              timerService,
              postSessionPractices,
              postSessionPosture,
              elapsedSeconds,
            );
          },
        ),
        AppButton.outline('Save Time Only', onPressed: () {
          Navigator.of(context).pop();
          _saveTimeOnly(context, timerService, elapsedSeconds);
        }),
        AppButton.quiet('Don\'t Save', onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }

  /// Save session with detailed practice information
  void _saveSessionWithPractices(
    BuildContext context,
    TimerService timerService,
    List<Practice> practices,
    String posture,
    int elapsedSeconds,
  ) async {
    try {
      final session = Session(
        id: 'session_${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        duration: elapsedSeconds,
        practices: practices,
        posture: posture,
        notes: null,
      );

      await DatabaseService().saveSession(session);
      
      await timerService.reset();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session saved with practice details!'),
            backgroundColor: Color(0xFF20b2aa),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Wrapper to safely capture elapsed time before saving time-only session
  void _saveTimeOnlyWithElapsedCapture(BuildContext context, TimerService timerService) {
    final elapsedSeconds = timerService.elapsed;
    _saveTimeOnly(context, timerService, elapsedSeconds);
  }

  /// Save session with just duration (no practice details)
  void _saveTimeOnly(BuildContext context, TimerService timerService, int elapsedSeconds) async {
    // Stop bell sound immediately when user interacts
    timerService.stopBellSound();
    
    try {
      final session = Session(
        id: 'session_${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        duration: elapsedSeconds,
        practices: [], // Empty practices list
        posture: 'Sitting', // Default posture
        notes: 'Time-only session',
      );

      await DatabaseService().saveSession(session);
      
      await timerService.reset();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session time saved!'),
            backgroundColor: Color(0xFF20b2aa),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
