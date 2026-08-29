import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/config/config.dart';
import 'package:randoeats/screens/screens.dart';
import 'package:randoeats/services/services.dart';

/// Actually renders SettingsScreen, unlike settings_screen_test.dart, which
/// only constructs the widget and then tests the category map.
///
/// That older file says it cannot render because SettingsScreen reaches for
/// StorageService.instance directly. Half of that is fixable — StorageService
/// exposes initializeForTest(path), which is what
/// detail_screen_render_test.dart already uses, and with it the screen renders
/// fine.
///
/// The other half is real and limits what can be tested here. testWidgets runs
/// in a FakeAsync zone, and every mutation on this screen (toggles, sliders,
/// unit choice, banning a category, the confirm branch of each destructive
/// dialog) persists to Hive. Those are real disk writes whose futures never
/// complete under fake async, so a test that taps them hangs until the
/// framework timeout rather than failing.
///
/// So this file covers what it can honestly cover: that the whole form lays
/// out, that every theme swatch and category chip is present and correctly
/// keyed, and that each dialog opens and can be dismissed. Covering the
/// mutations properly needs SettingsScreen to take an injected storage
/// dependency instead of reaching for the singleton — a refactor, not a test
/// change.
void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('settings_render');
    await StorageService.instance.initializeForTest(tempDir.path);
  });

  tearDownAll(() async {
    await StorageService.instance.close();
    await tempDir.delete(recursive: true);
  });

  /// Fixed-duration pumps rather than pumpAndSettle: something on this screen
  /// never reports itself settled, so pumpAndSettle runs to its 10-minute
  /// timeout. 400ms clears the AnimatedContainer transitions and the dialog
  /// route animation.
  Future<void> settle(WidgetTester tester) =>
      tester.pump(const Duration(milliseconds: 400));

  Future<void> pumpSettings(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    // Tall enough to lay the entire form out, so nothing needs scrolling into
    // view — ensureVisible deadlocks here, since its future only completes
    // while the tester is pumping.
    tester.view.physicalSize = const Size(1200, 6000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsScreen())),
    );
    await settle(tester);
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(ValueKey<String>(key)), warnIfMissed: false);
    await settle(tester);
  }

  group('SettingsScreen layout', () {
    testWidgets('shows every section header', (tester) async {
      await pumpSettings(tester);

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Search Parameters'), findsOneWidget);
      expect(find.text('Banned Categories'), findsOneWidget);
      expect(find.text('History Settings'), findsOneWidget);
      expect(find.text('Data Management'), findsOneWidget);
    });

    testWidgets('shows every labelled control', (tester) async {
      await pumpSettings(tester);

      expect(find.text('Pick a season'), findsOneWidget);
      expect(find.text('Distance Units'), findsOneWidget);
      expect(find.text('Search Radius'), findsOneWidget);
      expect(find.text('Maximum Results'), findsOneWidget);
      expect(find.text('Open Restaurants Only'), findsOneWidget);
      expect(find.text('Calm Mode'), findsOneWidget);
      expect(find.text('Hide After Picking'), findsOneWidget);
    });

    testWidgets('renders every keyed control', (tester) async {
      await pumpSettings(tester);

      for (final key in const [
        'settingsSearchRadiusSlider1',
        'settingsMaxResultsSlider1',
        'settingsOpenOnlyToggle1',
        'settingsCalmModeToggle1',
        'settingsHideDaysSlider1',
        'settingsUnitMilesTap1',
        'settingsUnitKilometersTap1',
        'settingsClearVisitHistoryBtn1',
        'settingsClearRecentPicksBtn1',
        'settingsClearAllDataBtn1',
      ]) {
        expect(
          find.byKey(ValueKey<String>(key)),
          findsOneWidget,
          reason: 'missing keyed control $key',
        );
      }
    });

    testWidgets('renders a swatch for every theme', (tester) async {
      await pumpSettings(tester);

      for (final theme in AppTheme.values) {
        expect(
          find.byKey(ValueKey<String>('settingsThemeSwatch_${theme.id}')),
          findsOneWidget,
          reason: 'missing swatch for ${theme.id}',
        );
      }
    });

    testWidgets('renders a chip for every bannable category', (tester) async {
      await pumpSettings(tester);

      expect(restaurantCategories, hasLength(26));
      for (final entry in restaurantCategories.entries) {
        expect(
          find.byKey(ValueKey<String>('settingsCategoryChip_${entry.key}')),
          findsOneWidget,
          reason: 'missing chip for ${entry.key}',
        );
        expect(find.text(entry.value), findsWidgets);
      }
    });
  });

  group('SettingsScreen destructive dialogs', () {
    testWidgets('clear visit history opens and cancels', (tester) async {
      await pumpSettings(tester);

      await tapKey(tester, 'settingsClearVisitHistoryBtn1');
      expect(find.text('Clear Visit History?'), findsOneWidget);

      await tapKey(tester, 'settingsClearVisitHistoryCancelBtn1');
      expect(find.text('Clear Visit History?'), findsNothing);
    });

    testWidgets('clear recent picks opens and cancels', (tester) async {
      await pumpSettings(tester);

      await tapKey(tester, 'settingsClearRecentPicksBtn1');
      expect(find.text('Clear Recent Picks?'), findsOneWidget);

      await tapKey(tester, 'settingsClearRecentPicksCancelBtn1');
      expect(find.text('Clear Recent Picks?'), findsNothing);
    });

    testWidgets('clear all data opens and cancels', (tester) async {
      await pumpSettings(tester);

      await tapKey(tester, 'settingsClearAllDataBtn1');
      expect(find.text('Clear All Data?'), findsOneWidget);

      await tapKey(tester, 'settingsClearAllDataCancelBtn1');
      expect(find.text('Clear All Data?'), findsNothing);
    });
  });
}
