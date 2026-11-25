import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTheme {
  static const Color primary = Color(0xFF153D35);
  static const Color accent = Color(0xFFDDF3E8);
  static const Color background = Color(0xFFF5F7F5);
  static const Color card = Color(0xFFFFFFFF);

  static final ThemeData light = _buildLightTheme();

  static ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: accent,
      surface: card,
    );
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(baseTheme.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: primary,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
