import 'package:flutter/material.dart';
import '../ui/tokens.dart';

ThemeData buildDarkTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF20b2aa),
      secondary: Color(0xFF06b6d4),
      surface: Color(0xFF1e1e1e),
      onSurface: Color(0xFFe5e5e5),
      onPrimary: Color(0xFF000000),
    ),
    scaffoldBackgroundColor: const Color(0xFF1e1e1e),
  );

  return base.copyWith(
    extensions: const <ThemeExtension<dynamic>>[
      SemanticColors.dark,
    ],
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1e1e1e),
      foregroundColor: Color(0xFFe5e5e5),
      elevation: 0,
      centerTitle: true,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFF2a2a2a),
      shape: RoundedRectangleBorder(borderRadius: RadiusTokens.r16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF20b2aa),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: const RoundedRectangleBorder(borderRadius: RadiusTokens.r8),
        minimumSize: const Size(120, 48),
        textStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF20b2aa),
        side: const BorderSide(color: Color(0xFF20b2aa)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: const RoundedRectangleBorder(borderRadius: RadiusTokens.r8),
        minimumSize: const Size(120, 48),
        textStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF20b2aa),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: const RoundedRectangleBorder(borderRadius: RadiusTokens.r8),
        textStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF20b2aa),
      foregroundColor: Colors.black,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF2a2a2a),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: RadiusTokens.r12),
      margin: EdgeInsets.zero,
    ),
    listTileTheme: const ListTileThemeData(
      textColor: Color(0xFFe5e5e5),
      iconColor: Color(0xFF20b2aa),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF404040),
      thickness: 1,
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: Color(0xFF2a2a2a),
      shape: RoundedRectangleBorder(borderRadius: RadiusTokens.r12),
      textStyle: TextStyle(color: Color(0xFFe5e5e5)),
    ),
  );
}
