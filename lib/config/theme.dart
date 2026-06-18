import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A full set of Googie color tokens for one theme. Swapping the active
/// [GoogiePalette] (via [GoogieColors.current]) re-skins the whole app.
///
/// Tokens are named by their Spring (default) hue for continuity with the
/// original palette, but each theme supplies its own values, so e.g.
/// `turquoise` is a bright sky-blue in Winter. Think of them by role:
/// `turquoise` = primary accent, `coral` = CTA/secondary, `mustard` =
/// highlight/tertiary, `deepTeal` = readable accent text, `cream` = app
/// background, `white` = card base, `cardTint` = card surface, `chrome` =
/// borders, `spaceBlack` = primary text ink.
@immutable
class GoogiePalette {
  /// Creates a [GoogiePalette].
  const GoogiePalette({
    required this.turquoise,
    required this.deepTeal,
    required this.coral,
    required this.mustard,
    required this.cream,
    required this.chrome,
    required this.spaceBlack,
    required this.white,
    required this.darkCard,
    required this.statusOpen,
    required this.statusClosed,
    required this.turquoiseContainer,
    required this.onTurquoiseContainer,
    required this.coralContainer,
    required this.onCoralContainer,
    required this.mustardContainer,
    required this.onMustardContainer,
    required this.statusOpenContainer,
    required this.cardTint,
    required this.brightness,
  });

  /// Primary accent.
  final Color turquoise;

  /// Readable accent text (AA on the app background).
  final Color deepTeal;

  /// CTA / secondary accent.
  final Color coral;

  /// Highlight / tertiary accent.
  final Color mustard;

  /// App (scaffold) background.
  final Color cream;

  /// Borders, subtle dividers.
  final Color chrome;

  /// Primary text ink.
  final Color spaceBlack;

  /// Base card / elevated surface.
  final Color white;

  /// Elevated surface for dark themes.
  final Color darkCard;

  /// "Open" status accent.
  final Color statusOpen;

  /// "Closed" status accent.
  final Color statusClosed;

  /// Primary tonal container fill.
  final Color turquoiseContainer;

  /// Text/icon on [turquoiseContainer].
  final Color onTurquoiseContainer;

  /// Secondary tonal container fill.
  final Color coralContainer;

  /// Text/icon on [coralContainer].
  final Color onCoralContainer;

  /// Tertiary tonal container fill.
  final Color mustardContainer;

  /// Text/icon on [mustardContainer].
  final Color onMustardContainer;

  /// Soft "open" fill paired with [statusOpen] text.
  final Color statusOpenContainer;

  /// Tinted card surface.
  final Color cardTint;

  /// Overall light/dark brightness of this palette.
  final Brightness brightness;

  /// Spring — the original warm pastel cream + turquoise/coral/mustard look.
  static const spring = GoogiePalette(
    turquoise: Color(0xFF40E0D0),
    deepTeal: Color(0xFF0D7377),
    coral: Color(0xFFFF6F61),
    mustard: Color(0xFFFFDB58),
    cream: Color(0xFFF5F0E1),
    chrome: Color(0xFFC0C0C0),
    spaceBlack: Color(0xFF1A1A2E),
    white: Color(0xFFFFFFFF),
    darkCard: Color(0xFF2D2D44),
    statusOpen: Color(0xFF2E7D5B),
    statusClosed: Color(0xFFC4452F),
    turquoiseContainer: Color(0xFFCBEFE9),
    onTurquoiseContainer: Color(0xFF06423C),
    coralContainer: Color(0xFFFFDAD2),
    onCoralContainer: Color(0xFF5A160B),
    mustardContainer: Color(0xFFFAE9B0),
    onMustardContainer: Color(0xFF3F3300),
    statusOpenContainer: Color(0xFFCDEBD9),
    cardTint: Color(0xFFF3FBF9),
    brightness: Brightness.light,
  );

  /// Light — crisp, airy white with a cooler teal.
  static const light = GoogiePalette(
    turquoise: Color(0xFF159E92),
    deepTeal: Color(0xFF0B6E72),
    coral: Color(0xFFF15B4C),
    mustard: Color(0xFFE3A92E),
    cream: Color(0xFFFBFCFD),
    chrome: Color(0xFFDCE2E6),
    spaceBlack: Color(0xFF1A1C1E),
    white: Color(0xFFFFFFFF),
    darkCard: Color(0xFF2D2D44),
    statusOpen: Color(0xFF2E7D5B),
    statusClosed: Color(0xFFC4452F),
    turquoiseContainer: Color(0xFFCDEFEB),
    onTurquoiseContainer: Color(0xFF05423C),
    coralContainer: Color(0xFFFFDAD3),
    onCoralContainer: Color(0xFF5A160B),
    mustardContainer: Color(0xFFF7E9BD),
    onMustardContainer: Color(0xFF3D3300),
    statusOpenContainer: Color(0xFFCDEBD9),
    cardTint: Color(0xFFEFF4F5),
    brightness: Brightness.light,
  );

  /// Dark — atomic-age space: deep navy surfaces, glowing accents.
  static const dark = GoogiePalette(
    turquoise: Color(0xFF40E0D0),
    deepTeal: Color(0xFF7FE9DD),
    coral: Color(0xFFFF8A75),
    mustard: Color(0xFFFFE07A),
    cream: Color(0xFF15151F),
    chrome: Color(0xFF454A5E),
    spaceBlack: Color(0xFFECECF4),
    white: Color(0xFF222238),
    darkCard: Color(0xFF222238),
    statusOpen: Color(0xFF66D6A1),
    statusClosed: Color(0xFFFF8A75),
    turquoiseContainer: Color(0xFF123A38),
    onTurquoiseContainer: Color(0xFFA6F0E7),
    coralContainer: Color(0xFF4A1A12),
    onCoralContainer: Color(0xFFFFD7CD),
    mustardContainer: Color(0xFF3E3413),
    onMustardContainer: Color(0xFFF6E3A0),
    statusOpenContainer: Color(0xFF163A2C),
    cardTint: Color(0xFF272A3E),
    brightness: Brightness.dark,
  );

  /// Summer — sunny, hot: sandy background, sea-teal, hot coral, sun gold.
  static const summer = GoogiePalette(
    turquoise: Color(0xFF00BFA6),
    deepTeal: Color(0xFF0E6E63),
    coral: Color(0xFFFF5A4D),
    mustard: Color(0xFFFFAF14),
    cream: Color(0xFFFFF4E2),
    chrome: Color(0xFFE8D4B8),
    spaceBlack: Color(0xFF3A2A1A),
    white: Color(0xFFFFFFFF),
    darkCard: Color(0xFF2D2D44),
    statusOpen: Color(0xFF2E7D5B),
    statusClosed: Color(0xFFC4452F),
    turquoiseContainer: Color(0xFFBFF0E8),
    onTurquoiseContainer: Color(0xFF06423C),
    coralContainer: Color(0xFFFFDAD2),
    onCoralContainer: Color(0xFF5A160B),
    mustardContainer: Color(0xFFFFE8B0),
    onMustardContainer: Color(0xFF3F2E00),
    statusOpenContainer: Color(0xFFCFEBD9),
    cardTint: Color(0xFFFFF1DD),
    brightness: Brightness.light,
  );

  /// Winter — Finnish midwinter: white and shades of grey, bright sky blue.
  static const winter = GoogiePalette(
    turquoise: Color(0xFF2F9BD8),
    deepTeal: Color(0xFF1C5476),
    coral: Color(0xFF0E5A8A),
    mustard: Color(0xFF8FA8B8),
    cream: Color(0xFFEEF3F7),
    chrome: Color(0xFFC2CDD8),
    spaceBlack: Color(0xFF1B2730),
    white: Color(0xFFFFFFFF),
    darkCard: Color(0xFF2D2D44),
    statusOpen: Color(0xFF2E7D5B),
    statusClosed: Color(0xFFB23A3A),
    turquoiseContainer: Color(0xFFD2E8F6),
    onTurquoiseContainer: Color(0xFF0A3A57),
    coralContainer: Color(0xFFCFE0EE),
    onCoralContainer: Color(0xFF0B3A5C),
    mustardContainer: Color(0xFFDCE6EC),
    onMustardContainer: Color(0xFF2B3A44),
    statusOpenContainer: Color(0xFFD2EADB),
    cardTint: Color(0xFFE6EDF3),
    brightness: Brightness.light,
  );

  /// Autumn — cozy parchment with burnt orange, brick red, and golden leaves.
  static const autumn = GoogiePalette(
    turquoise: Color(0xFFD9722B),
    deepTeal: Color(0xFF7A3A1B),
    coral: Color(0xFFB83A2B),
    mustard: Color(0xFFE0A126),
    cream: Color(0xFFF5ECDA),
    chrome: Color(0xFFCBB89A),
    spaceBlack: Color(0xFF2E2013),
    white: Color(0xFFFFFDF7),
    darkCard: Color(0xFF2D2D44),
    statusOpen: Color(0xFF4E7A3A),
    statusClosed: Color(0xFFB23A2E),
    turquoiseContainer: Color(0xFFF7DEC4),
    onTurquoiseContainer: Color(0xFF5A2A0E),
    coralContainer: Color(0xFFF8D6CD),
    onCoralContainer: Color(0xFF551407),
    mustardContainer: Color(0xFFF2E3B2),
    onMustardContainer: Color(0xFF463600),
    statusOpenContainer: Color(0xFFDDE8C6),
    cardTint: Color(0xFFFBF3E5),
    brightness: Brightness.light,
  );
}

/// Googie / 60s Retro-Future colors for rand-o-eats.
///
/// Members delegate to [current], the active [GoogiePalette]. Because these are
/// getters (not `const`), switching [current] and rebuilding re-skins the app.
abstract final class GoogieColors {
  /// The active palette. Set this before building the themed widget tree
  /// (see `App`); changing it + rebuilding swaps every token below.
  static GoogiePalette current = GoogiePalette.spring;

  /// Primary accent.
  static Color get turquoise => current.turquoise;

  /// Readable accent text (AA on the app background).
  static Color get deepTeal => current.deepTeal;

  /// CTA / secondary accent.
  static Color get coral => current.coral;

  /// Highlight / tertiary accent.
  static Color get mustard => current.mustard;

  /// App background color.
  static Color get cream => current.cream;

  /// Borders, subtle accents.
  static Color get chrome => current.chrome;

  /// Primary text ink.
  static Color get spaceBlack => current.spaceBlack;

  /// Base card surface.
  static Color get white => current.white;

  /// Elevated surface for dark themes.
  static Color get darkCard => current.darkCard;

  /// "Open" status accent.
  static Color get statusOpen => current.statusOpen;

  /// "Closed" status accent.
  static Color get statusClosed => current.statusClosed;

  /// Primary tonal container fill.
  static Color get turquoiseContainer => current.turquoiseContainer;

  /// Text/icon on [turquoiseContainer].
  static Color get onTurquoiseContainer => current.onTurquoiseContainer;

  /// Secondary tonal container fill.
  static Color get coralContainer => current.coralContainer;

  /// Text/icon on [coralContainer].
  static Color get onCoralContainer => current.onCoralContainer;

  /// Tertiary tonal container fill.
  static Color get mustardContainer => current.mustardContainer;

  /// Text/icon on [mustardContainer].
  static Color get onMustardContainer => current.onMustardContainer;

  /// Soft "open" fill paired with [statusOpen] text.
  static Color get statusOpenContainer => current.statusOpenContainer;

  /// Tinted card surface.
  static Color get cardTint => current.cardTint;
}

/// A selectable, persisted app theme.
enum AppTheme {
  /// Crisp, airy light.
  light('light', 'Light', GoogiePalette.light),

  /// Atomic-age dark.
  dark('dark', 'Dark', GoogiePalette.dark),

  /// The default warm pastel look.
  spring('spring', 'Spring', GoogiePalette.spring),

  /// Sunny, hot summer.
  summer('summer', 'Summer', GoogiePalette.summer),

  /// Cozy autumn.
  autumn('autumn', 'Autumn', GoogiePalette.autumn),

  /// Finnish midwinter.
  winter('winter', 'Winter', GoogiePalette.winter);

  const AppTheme(this.id, this.label, this.palette);

  /// Stable storage id.
  final String id;

  /// Human-facing label.
  final String label;

  /// The colors for this theme.
  final GoogiePalette palette;

  /// The default theme.
  static const AppTheme fallback = AppTheme.spring;

  /// Resolves a stored [id] back to a theme, or null if unknown.
  static AppTheme? fromId(String? id) {
    for (final t in AppTheme.values) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// The built [ThemeData] for this theme.
  ThemeData get data => GoogieTheme.fromPalette(palette);
}

/// Retro-future typography for rand-o-eats.
abstract final class GoogieTypography {
  /// Display/headline + body type scale (Fredoka + Nunito).
  static TextTheme get textTheme {
    return TextTheme(
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
      bodyLarge: GoogleFonts.nunito(
        fontSize: 16,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.nunito(
        fontSize: 14,
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.nunito(
        fontSize: 12,
        letterSpacing: 0.4,
      ),
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

/// Builds [ThemeData] from a [GoogiePalette].
abstract final class GoogieTheme {
  static Color _bestOn(Color c) =>
      ThemeData.estimateBrightnessForColor(c) == Brightness.dark
      ? Colors.white
      : Colors.black;

  /// Builds the full themed [ThemeData] for [p].
  static ThemeData fromPalette(GoogiePalette p) {
    final textTheme = GoogieTypography.textTheme.apply(
      bodyColor: p.spaceBlack,
      displayColor: p.spaceBlack,
    );

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: p.turquoise,
          brightness: p.brightness,
        ).copyWith(
          primary: p.turquoise,
          onPrimary: _bestOn(p.turquoise),
          primaryContainer: p.turquoiseContainer,
          onPrimaryContainer: p.onTurquoiseContainer,
          secondary: p.coral,
          onSecondary: _bestOn(p.coral),
          secondaryContainer: p.coralContainer,
          onSecondaryContainer: p.onCoralContainer,
          tertiary: p.mustard,
          onTertiary: _bestOn(p.mustard),
          tertiaryContainer: p.mustardContainer,
          onTertiaryContainer: p.onMustardContainer,
          surface: p.white,
          onSurface: p.spaceBlack,
          surfaceContainerLowest: p.white,
          surfaceContainerLow: p.cardTint,
          surfaceContainer: p.cardTint,
          surfaceContainerHighest: p.cream,
          outline: p.chrome,
          outlineVariant: p.chrome,
          error: p.statusClosed,
          onError: _bestOn(p.statusClosed),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      scaffoldBackgroundColor: p.cream,
      textTheme: textTheme,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: p.cream,
        foregroundColor: p.spaceBlack,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: p.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.chrome),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.coral,
          foregroundColor: _bestOn(p.coral),
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
          foregroundColor: p.turquoise,
          minimumSize: const Size(double.infinity, 64),
          side: BorderSide(color: p.turquoise, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.coral,
        foregroundColor: _bestOn(p.coral),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.chrome),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.chrome),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.turquoise, width: 2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.turquoise;
          return p.chrome;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return p.turquoise.withValues(alpha: 0.5);
          }
          return p.chrome.withValues(alpha: 0.5);
        }),
      ),
      dividerTheme: DividerThemeData(
        color: p.chrome,
        thickness: 1,
      ),
    );
  }

  /// Back-compat: the default (Spring) light theme.
  static ThemeData get light => fromPalette(GoogiePalette.spring);

  /// Back-compat: the dark theme.
  static ThemeData get dark => fromPalette(GoogiePalette.dark);
}
