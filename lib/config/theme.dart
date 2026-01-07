import 'package:flutter/material.dart';

/// Googie / 60s Retro-Future color palette for rand-o-eats.
///
/// Inspired by The Jetsons, Lost in Space, and atomic-age design.
abstract final class GoogieColors {
  /// Primary accent - used for headers, highlights
  static const turquoise = Color(0xFF40E0D0);

  /// Secondary accent - used for CTAs, buttons
  static const coral = Color(0xFFFF6F61);

  /// Highlights, stars, warning states
  static const mustard = Color(0xFFFFDB58);

  /// App background color (matches splash screen logo background)
  static const cream = Color(0xFFF5F0E1);

  /// Borders, subtle accents
  static const chrome = Color(0xFFC0C0C0);

  /// Text color, dark mode background
  static const spaceBlack = Color(0xFF1A1A2E);

  /// Card backgrounds in light mode
  static const white = Color(0xFFFFFFFF);

  /// Card backgrounds in dark mode
  static const darkCard = Color(0xFF2D2D44);
}

/// Theme configuration for rand-o-eats.
abstract final class GoogieTheme {
  /// Light theme for the app.
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: GoogieColors.cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: GoogieColors.turquoise,
        primary: GoogieColors.turquoise,
        secondary: GoogieColors.coral,
        tertiary: GoogieColors.mustard,
        surface: GoogieColors.white,
        onSurface: GoogieColors.spaceBlack,
        surfaceContainerHighest: GoogieColors.cream,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: GoogieColors.cream,
        foregroundColor: GoogieColors.spaceBlack,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: GoogieColors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: GoogieColors.chrome),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GoogieColors.coral,
          foregroundColor: GoogieColors.white,
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GoogieColors.turquoise,
          minimumSize: const Size(double.infinity, 64),
          side: const BorderSide(color: GoogieColors.turquoise, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: GoogieColors.coral,
        foregroundColor: GoogieColors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GoogieColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: GoogieColors.chrome),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: GoogieColors.chrome),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: GoogieColors.turquoise, width: 2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogieColors.turquoise;
          }
          return GoogieColors.chrome;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogieColors.turquoise.withValues(alpha: 0.5);
          }
          return GoogieColors.chrome.withValues(alpha: 0.5);
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: GoogieColors.chrome,
        thickness: 1,
      ),
    );
  }

  /// Dark theme for the app.
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: GoogieColors.spaceBlack,
      colorScheme: ColorScheme.fromSeed(
        seedColor: GoogieColors.turquoise,
        brightness: Brightness.dark,
        primary: GoogieColors.turquoise,
        secondary: GoogieColors.coral,
        tertiary: GoogieColors.mustard,
        surface: GoogieColors.darkCard,
        onSurface: GoogieColors.cream,
        surfaceContainerHighest: GoogieColors.spaceBlack,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: GoogieColors.spaceBlack,
        foregroundColor: GoogieColors.cream,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: GoogieColors.darkCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: GoogieColors.chrome.withValues(alpha: 0.3)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GoogieColors.coral,
          foregroundColor: GoogieColors.white,
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GoogieColors.turquoise,
          minimumSize: const Size(double.infinity, 64),
          side: const BorderSide(color: GoogieColors.turquoise, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: GoogieColors.coral,
        foregroundColor: GoogieColors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GoogieColors.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: GoogieColors.chrome.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: GoogieColors.chrome.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: GoogieColors.turquoise, width: 2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogieColors.turquoise;
          }
          return GoogieColors.chrome;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogieColors.turquoise.withValues(alpha: 0.5);
          }
          return GoogieColors.chrome.withValues(alpha: 0.5);
        }),
      ),
      dividerTheme: DividerThemeData(
        color: GoogieColors.chrome.withValues(alpha: 0.3),
        thickness: 1,
      ),
    );
  }
}
