import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:randoeats/config/config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Prevent Google Fonts from making HTTP requests in tests.
    // Font files won't be found in test assets, so GoogleFonts will log
    // errors, but the TextStyle objects are still constructed with the
    // correct fontSize, fontWeight, etc.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('GoogieColors', () {
    test('turquoise is correct hex', () {
      expect(GoogieColors.turquoise, const Color(0xFF40E0D0));
    });

    test('deepTeal is correct hex', () {
      expect(GoogieColors.deepTeal, const Color(0xFF0D7377));
    });

    test('coral is correct hex', () {
      expect(GoogieColors.coral, const Color(0xFFFF6F61));
    });

    test('mustard is correct hex', () {
      expect(GoogieColors.mustard, const Color(0xFFFFDB58));
    });

    test('cream is correct hex', () {
      expect(GoogieColors.cream, const Color(0xFFF5F0E1));
    });

    test('chrome is correct hex', () {
      expect(GoogieColors.chrome, const Color(0xFFC0C0C0));
    });

    test('spaceBlack is correct hex', () {
      expect(GoogieColors.spaceBlack, const Color(0xFF1A1A2E));
    });

    test('white is correct hex', () {
      expect(GoogieColors.white, const Color(0xFFFFFFFF));
    });

    test('darkCard is correct hex', () {
      expect(GoogieColors.darkCard, const Color(0xFF2D2D44));
    });
  });

  // GoogieTypography and GoogieTheme call GoogleFonts which attempt async
  // font loading. In test environment, font files are not available and
  // the async operations produce exceptions. We run these tests in a custom
  // Zone that silences those async errors, since the TextStyle and ThemeData
  // objects are still fully constructed with correct properties.

  group('GoogieTypography', () {
    late TextTheme textTheme;

    setUpAll(() {
      runZoned(
        () {
          textTheme = GoogieTypography.textTheme;
        },
        zoneSpecification: ZoneSpecification(
          handleUncaughtError: (self, parent, zone, error, stackTrace) {
            // Silently swallow GoogleFonts font-loading errors in tests.
          },
        ),
      );
    });

    test('textTheme returns a TextTheme', () {
      expect(textTheme, isA<TextTheme>());
    });

    test('textTheme has all text styles', () {
      expect(textTheme.displayLarge, isNotNull);
      expect(textTheme.displayMedium, isNotNull);
      expect(textTheme.displaySmall, isNotNull);
      expect(textTheme.headlineLarge, isNotNull);
      expect(textTheme.headlineMedium, isNotNull);
      expect(textTheme.headlineSmall, isNotNull);
      expect(textTheme.titleLarge, isNotNull);
      expect(textTheme.titleMedium, isNotNull);
      expect(textTheme.titleSmall, isNotNull);
      expect(textTheme.bodyLarge, isNotNull);
      expect(textTheme.bodyMedium, isNotNull);
      expect(textTheme.bodySmall, isNotNull);
      expect(textTheme.labelLarge, isNotNull);
      expect(textTheme.labelMedium, isNotNull);
      expect(textTheme.labelSmall, isNotNull);
    });

    test('display styles use bold weight', () {
      expect(textTheme.displayLarge?.fontWeight, FontWeight.bold);
      expect(textTheme.displayMedium?.fontWeight, FontWeight.bold);
      expect(textTheme.displaySmall?.fontWeight, FontWeight.bold);
    });

    test('display font sizes are correct', () {
      expect(textTheme.displayLarge?.fontSize, 57);
      expect(textTheme.displayMedium?.fontSize, 45);
      expect(textTheme.displaySmall?.fontSize, 36);
    });
  });

  group('GoogieTheme', () {
    late ThemeData lightTheme;
    late ThemeData darkTheme;

    setUpAll(() {
      runZoned(
        () {
          lightTheme = GoogieTheme.light;
          darkTheme = GoogieTheme.dark;
        },
        zoneSpecification: ZoneSpecification(
          handleUncaughtError: (self, parent, zone, error, stackTrace) {
            // Silently swallow GoogleFonts font-loading errors in tests.
          },
        ),
      );
    });

    group('light', () {
      test('uses Material 3', () {
        expect(lightTheme.useMaterial3, isTrue);
      });

      test('has light brightness', () {
        expect(lightTheme.brightness, Brightness.light);
      });

      test('uses cream scaffold background', () {
        expect(lightTheme.scaffoldBackgroundColor, GoogieColors.cream);
      });

      test('has turquoise primary color', () {
        expect(lightTheme.colorScheme.primary, GoogieColors.turquoise);
      });

      test('has coral secondary color', () {
        expect(lightTheme.colorScheme.secondary, GoogieColors.coral);
      });

      test('has mustard tertiary color', () {
        expect(lightTheme.colorScheme.tertiary, GoogieColors.mustard);
      });

      test('appBar uses cream background', () {
        expect(lightTheme.appBarTheme.backgroundColor, GoogieColors.cream);
      });

      test('appBar has no elevation', () {
        expect(lightTheme.appBarTheme.elevation, 0);
      });

      test('card theme uses white background', () {
        expect(lightTheme.cardTheme.color, GoogieColors.white);
      });

      test('elevated button theme is configured', () {
        expect(lightTheme.elevatedButtonTheme.style, isNotNull);
      });

      test('input decoration is filled', () {
        expect(lightTheme.inputDecorationTheme.filled, isTrue);
      });

      test('input decoration uses white fill', () {
        expect(
          lightTheme.inputDecorationTheme.fillColor,
          GoogieColors.white,
        );
      });

      test('text theme applies space black colors', () {
        expect(
          lightTheme.textTheme.bodyLarge?.color,
          GoogieColors.spaceBlack,
        );
      });
    });

    group('dark', () {
      test('uses Material 3', () {
        expect(darkTheme.useMaterial3, isTrue);
      });

      test('has dark brightness', () {
        expect(darkTheme.brightness, Brightness.dark);
      });

      test('uses spaceBlack scaffold background', () {
        expect(
          darkTheme.scaffoldBackgroundColor,
          GoogieColors.spaceBlack,
        );
      });

      test('has turquoise primary color', () {
        expect(darkTheme.colorScheme.primary, GoogieColors.turquoise);
      });

      test('appBar uses spaceBlack background', () {
        expect(
          darkTheme.appBarTheme.backgroundColor,
          GoogieColors.spaceBlack,
        );
      });

      test('card theme uses darkCard background', () {
        expect(darkTheme.cardTheme.color, GoogieColors.darkCard);
      });

      test('input decoration uses darkCard fill', () {
        expect(
          darkTheme.inputDecorationTheme.fillColor,
          GoogieColors.darkCard,
        );
      });

      test('text theme applies cream colors', () {
        expect(darkTheme.textTheme.bodyLarge?.color, GoogieColors.cream);
      });
    });
  });
}
