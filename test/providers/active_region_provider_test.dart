import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/providers/active_region_provider.dart';

void main() {
  group('activeRegionProvider', () {
    late ProviderContainer container;

    final region = SavedRegion(
      id: 'r1',
      name: 'Orange Circle',
      points: const [0, 0, 0, 1, 1, 1],
      createdAt: DateTime(2026),
    );

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('defaults to null (Near Me)', () {
      expect(container.read(activeRegionProvider), isNull);
    });

    test('select sets the active region', () {
      container.read(activeRegionProvider.notifier).select(region);
      expect(container.read(activeRegionProvider), region);
    });

    test('clear resets to null', () {
      final notifier = container.read(activeRegionProvider.notifier)
        ..select(region)
        ..clear();
      expect(notifier, isNotNull);
      expect(container.read(activeRegionProvider), isNull);
    });
  });
}
