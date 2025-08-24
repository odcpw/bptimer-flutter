import 'package:flutter/material.dart';

/// App design tokens and theme extensions
class Spacing {
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
}

class RadiusTokens {
  static const BorderRadius r8 = BorderRadius.all(Radius.circular(8));
  static const BorderRadius r12 = BorderRadius.all(Radius.circular(12));
  static const BorderRadius r16 = BorderRadius.all(Radius.circular(16));
}

class Motion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration med = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
}

class LayoutTokens {
  static const double maxContentWidth = 600.0; // matches PWA

  /// Compute responsive horizontal gutter based on width
  static double gutterForWidth(double width) {
    if (width < 360) return Spacing.s12; // xs
    if (width < 480) return Spacing.s16; // sm
    return Spacing.s20; // md+
  }
}

/// Semantic colors that complement ColorScheme
class SemanticColors extends ThemeExtension<SemanticColors> {
  final Color success;
  final Color warning;
  final Color danger;
  final Color accent;
  final Color border;
  final Color surfaceElevated;

  const SemanticColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.accent,
    required this.border,
    required this.surfaceElevated,
  });

  @override
  ThemeExtension<SemanticColors> copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? accent,
    Color? border,
    Color? surfaceElevated,
  }) {
    return SemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      accent: accent ?? this.accent,
      border: border ?? this.border,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
    );
  }

  @override
  ThemeExtension<SemanticColors> lerp(ThemeExtension<SemanticColors>? other, double t) {
    if (other is! SemanticColors) return this;
    return SemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      border: Color.lerp(border, other.border, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
    );
  }

  static const dark = SemanticColors(
    success: Color(0xFF10b981),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFdc3545),
    accent: Color(0xFF20b2aa),
    border: Color(0xFF404040),
    surfaceElevated: Color(0xFF2a2a2a),
  );
}

