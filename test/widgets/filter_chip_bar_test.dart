import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/providers/active_filters_provider.dart';
import 'package:randoeats/widgets/filter_chip_bar.dart';

void main() {
  group('FilterChipBar', () {
    Future<ProviderContainer> pump(
      WidgetTester tester, {
      VoidCallback? onSaveSpot,
    }) async {
      // Wide surface so every chip is on-screen and hittable.
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(2200, 400);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: FilterChipBar(onSaveSpot: onSaveSpot)),
          ),
        ),
      );
      return container;
    }

    testWidgets('renders cuisine + facet chips', (tester) async {
      await pump(tester);
      expect(find.text('Mexican'), findsOneWidget);
      expect(find.text('Beer'), findsOneWidget);
      expect(find.text('Patio'), findsOneWidget);
      expect(find.text('4.0+'), findsOneWidget);
    });

    testWidgets('tapping Beer toggles servesBeer', (tester) async {
      final container = await pump(tester);
      await tester.tap(find.byKey(const ValueKey('filter_beer')));
      await tester.pump();
      expect(container.read(activeFiltersProvider).servesBeer, isTrue);
      await tester.tap(find.byKey(const ValueKey('filter_beer')));
      await tester.pump();
      expect(container.read(activeFiltersProvider).servesBeer, isFalse);
    });

    testWidgets('tapping Mexican toggles the cuisine', (tester) async {
      final container = await pump(tester);
      await tester.tap(find.byKey(const ValueKey('filter_cuisine_mexican')));
      await tester.pump();
      expect(container.read(activeFiltersProvider).cuisines, {'mexican'});
    });

    testWidgets('tapping 4.0+ sets then clears minRating', (tester) async {
      final container = await pump(tester);
      await tester.tap(find.byKey(const ValueKey('filter_rating')));
      await tester.pump();
      expect(container.read(activeFiltersProvider).minRating, 4.0);
      await tester.tap(find.byKey(const ValueKey('filter_rating')));
      await tester.pump();
      expect(container.read(activeFiltersProvider).minRating, isNull);
    });

    testWidgets('tapping a price chip toggles the level', (tester) async {
      final container = await pump(tester);
      await tester.tap(find.byKey(const ValueKey('filter_price_2')));
      await tester.pump();
      expect(container.read(activeFiltersProvider).priceLevels, {2});
    });

    testWidgets('save-spot star is hidden without onSaveSpot', (tester) async {
      final container = await pump(tester);
      container.read(activeFiltersProvider.notifier).toggleCuisine('mexican');
      await tester.pump();
      expect(find.byKey(const ValueKey('filter_save_spot')), findsNothing);
    });

    testWidgets('save-spot star is hidden when no filters are active', (
      tester,
    ) async {
      await pump(tester, onSaveSpot: () {});
      expect(find.byKey(const ValueKey('filter_save_spot')), findsNothing);
    });

    testWidgets('save-spot star appears and fires when filters active', (
      tester,
    ) async {
      var saved = false;
      final container = await pump(tester, onSaveSpot: () => saved = true);
      expect(find.byKey(const ValueKey('filter_save_spot')), findsNothing);

      container.read(activeFiltersProvider.notifier).toggleCuisine('mexican');
      await tester.pump();

      expect(find.byKey(const ValueKey('filter_save_spot')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('filter_save_spot')));
      await tester.pump();
      expect(saved, isTrue);
    });
  });
}
