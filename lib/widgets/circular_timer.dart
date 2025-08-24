/// CountdownDisplay - Simple countdown timer display (matches PWA)
/// 
/// Displays remaining time in large text format with golden ratio typography.
/// Responsive design with clamp-style sizing matching PWA implementation.
/// Clean and focused countdown timer without circular progress complexity.

library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/timer_service.dart';
import '../utils/constants.dart';

class CircularTimer extends StatelessWidget {
  const CircularTimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerService>(
      builder: (context, timerService, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main countdown display - showing REMAINING time like PWA with responsive sizing
              LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final responsiveSize = _calculateResponsiveTimerSize(screenWidth);
                  
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      timerService.formattedRemaining,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: responsiveSize,
                        fontWeight: TypographyConstants.fontWeightLight,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: _getTimerColor(timerService),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              // State indicator text with golden ratio sizing
              Text(
                _getStateText(timerService),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: TypographyConstants.fontSizeMedium,
                  fontWeight: TypographyConstants.fontWeightRegular,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Get timer color based on state
  Color _getTimerColor(TimerService timerService) {
    switch (timerService.state) {
      case TimerState.running:
        return const Color(0xFF20b2aa); // Teal - active
      case TimerState.paused:
        return const Color(0xFFF59E0B); // Amber - paused
      case TimerState.completed:
        return const Color(0xFF10b981); // Green - completed
      case TimerState.stopped:
        return const Color(0xFFe5e5e5); // White - ready
    }
  }

  /// Get state text based on timer state
  String _getStateText(TimerService timerService) {
    switch (timerService.state) {
      case TimerState.running:
        return 'Meditating...';
      case TimerState.paused:
        return 'Paused';
      case TimerState.completed:
        return 'Session Complete!';
      case TimerState.stopped:
        return 'Ready to begin';
    }
  }

  /// Calculate responsive timer font size mimicking PWA's clamp(80px, 15vw, 144px)
  /// Uses golden ratio constraints for harmonious scaling
  double _calculateResponsiveTimerSize(double screenWidth) {
    // Calculate viewport-based size (15vw)
    final viewportSize = screenWidth * TypographyConstants.timerFontSizeViewport;
    
    // Apply clamp constraints: min(max(min, viewport), max)
    return viewportSize.clamp(
      TypographyConstants.timerFontSizeMin,  // 80px minimum
      TypographyConstants.timerFontSizeMax,  // 144px maximum
    );
  }
}