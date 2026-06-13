import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/providers/active_region_provider.dart';
import 'package:randoeats/widgets/region_chip_bar.dart';

void main() {
  group('RegionChipBar', () {
    SavedRegion region(String id, String name) => SavedRegion(
      id: id,
      name: name,
      points: const [0, 0, 0, 1, 1, 1],
      createdAt: DateTime(2026),
    );

    final regions = [region('r1', 'Orange Circle'), region('r2', 'Downtown')];

    Future<ProviderContainer> pumpBar(
      WidgetTester tester, {
      void Function(SavedRegion)? onRename,
      void Function(SavedRegion)? onDelete,
      VoidCallback? onCreate,
    }) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: RegionChipBar(
                regions: regions,
                onCreate: onCreate ?? () {},
                onRename: onRename ?? (_) {},
                onDelete: onDelete ?? (_) {},
              ),
            ),
          ),
        ),
      );
      return container;
    }

    testWidgets('renders Near Me, each region, and New Area', (tester) async {
      await pumpBar(tester);
      expect(find.text('Near Me'), findsOneWidget);
      expect(find.text('Orange Circle'), findsOneWidget);
      expect(find.text('Downtown'), findsOneWidget);
      expect(find.text('New Area'), findsOneWidget);
    });

    testWidgets('Near Me is selected when no region is active', (tester) async {
      await pumpBar(tester);
      final chip = tester.widget<ChoiceChip>(
        find.descendant(
          of: find.byKey(const ValueKey('region_chip_near_me')),
          matching: find.byType(ChoiceChip),
        ),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('tapping a region chip activates it', (tester) async {
      final container = await pumpBar(tester);
      await tester.tap(find.byKey(const ValueKey('region_chip_r1')));
      await tester.pump();
      expect(container.read(activeRegionProvider)?.id, 'r1');
    });

    testWidgets('tapping Near Me clears the active region', (tester) async {
      final container = await pumpBar(tester);
      container.read(activeRegionProvider.notifier).select(regions.first);
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('region_chip_near_me')));
      await tester.pump();
      expect(container.read(activeRegionProvider), isNull);
    });

    testWidgets('tapping New Area invokes onCreate', (tester) async {
      var created = false;
      await pumpBar(tester, onCreate: () => created = true);
      await tester.tap(find.byKey(const ValueKey('region_chip_add')));
      await tester.pump();
      expect(created, isTrue);
    });

    testWidgets('long-press then Delete invokes onDelete', (tester) async {
      SavedRegion? deleted;
      await pumpBar(tester, onDelete: (r) => deleted = r);

      await tester.longPress(find.byKey(const ValueKey('region_chip_r1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('region_menu_delete')));
      await tester.pumpAndSettle();

      expect(deleted?.id, 'r1');
    });

    testWidgets('long-press then Rename invokes onRename', (tester) async {
      SavedRegion? renamed;
      await pumpBar(tester, onRename: (r) => renamed = r);

      await tester.longPress(find.byKey(const ValueKey('region_chip_r2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('region_menu_rename')));
      await tester.pumpAndSettle();

      expect(renamed?.id, 'r2');
    });
  });
}
