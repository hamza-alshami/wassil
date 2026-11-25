import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTheme {
  static const Color primary = Color(0xFF153D35);
  static const Color primaryDeep = Color(0xFF102E29);
  static const Color accent = Color(0xFFDDF3E8);
  static const Color background = Color(0xFFF4F7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF172922);
  static const Color muted = Color(0xFF738078);
  static const Color outline = Color(0xFFE4EAE6);
  static const Color statusPending = Color(0xFF94620B);
  static const Color statusPendingSurface = Color(0xFFFFF3D8);
  static const Color statusActive = Color(0xFF286B5B);
  static const Color statusActiveSurface = Color(0xFFE7F3EE);
  static const Color statusDelivered = Color(0xFF28704B);
  static const Color statusDeliveredSurface = Color(0xFFE6F4EB);
  static const Color statusCancelled = Color(0xFFAD453C);
  static const Color statusCancelledSurface = Color(0xFFFCEBE9);

  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double cardRadius = 22;
  static const double controlRadius = 15;

  static const List<BoxShadow> softShadows = [
    BoxShadow(color: Color(0x09153D35), blurRadius: 18, offset: Offset(0, 6)),
  ];

  static BoxDecoration surfaceDecoration({double radius = cardRadius}) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: outline),
      boxShadow: softShadows,
    );
  }

  static final ThemeData light = _buildLightTheme();

  static ThemeData _buildLightTheme() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          secondary: const Color(0xFF5E8E76),
          surface: surface,
          onSurface: ink,
          outline: outline,
          error: const Color(0xFFB8493E),
        );
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      dividerColor: outline,
      splashFactory: InkSparkle.splashFactory,
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(
        baseTheme.textTheme,
      ).apply(bodyColor: ink, displayColor: ink),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: .5,
        shadowColor: const Color(0x14153D35),
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: outline),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: outline,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
