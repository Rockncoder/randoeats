import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

/// Retro-future typography for rand-o-eats.
///
/// Uses Fredoka for display text (bowling alley vibe) and
/// Nunito for body text (friendly, rounded).
abstract final class GoogieTypography {
  /// Display/headline text style - bold, retro feel
  static TextTheme get textTheme {
    return TextTheme(
      // Display styles - for big headlines
      displayLarge: GoogleFonts.fredoka(
        fontSize: 57,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.25,
      ),
      displayMedium: GoogleFonts.fredoka(
        fontSize: 45,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: GoogleFonts.fredoka(
        fontSize: 36,
        fontWeight: FontWeight.bold,
      ),
      // Headline styles
      headlineLarge: GoogleFonts.fredoka(
        fontSize: 32,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: GoogleFonts.fredoka(
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: GoogleFonts.fredoka(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      // Title styles
      titleLarge: GoogleFonts.fredoka(
        fontSize: 22,
        fontWeight: FontWeight.w500,
      ),
      titleMedium: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      // Body styles - friendly, readable
      bodyLarge: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.4,
      ),
      // Label styles
      labelLarge: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.nunito(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

/// Theme configuration for rand-o-eats.
abstract final class GoogieTheme {
  /// Light theme for the app.
  static ThemeData get light {
    final textTheme = GoogieTypography.textTheme.apply(
      bodyColor: GoogieColors.spaceBlack,
      displayColor: GoogieColors.spaceBlack,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: GoogieColors.cream,
      textTheme: textTheme,
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
    final textTheme = GoogieTypography.textTheme.apply(
      bodyColor: GoogieColors.cream,
      displayColor: GoogieColors.cream,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: GoogieColors.spaceBlack,
      textTheme: textTheme,
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
