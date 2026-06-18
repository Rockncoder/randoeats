import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:randoeats/models/models.dart';

void main() {
  group('SpotFilters', () {
    test('defaults to empty / no filtering', () {
      const f = SpotFilters();
      expect(f.isEmpty, isTrue);
      expect(f.usesAtmosphere, isFalse);
      expect(f.activeCount, 0);
    });

    test('activeCount counts each active facet', () {
      const f = SpotFilters(
        cuisines: {'mexican'},
        servesBeer: true,
        openNow: true,
        minRating: 4,
        priceLevels: {1, 2},
      );
      expect(f.isEmpty, isFalse);
      expect(f.activeCount, 5); // cuisines, beer, open, rating, price
    });

    test('summaryLabel renders a short, ordered summary', () {
      expect(const SpotFilters().summaryLabel, '');
      const f = SpotFilters(
        cuisines: {'mexican'},
        servesBeer: true,
        minRating: 4,
        priceLevels: {1, 2},
      );
      expect(f.summaryLabel, r'Mexican · Beer · 4.0+ · $ · $$');
      // Known cuisine code maps to a friendly label.
      expect(
        const SpotFilters(cuisines: {'hamburger'}).summaryLabel,
        'Burgers',
      );
    });

    test('usesAtmosphere is true only for atmosphere facets', () {
      expect(const SpotFilters(openNow: true).usesAtmosphere, isFalse);
      expect(const SpotFilters(minRating: 4).usesAtmosphere, isFalse);
      expect(const SpotFilters(servesBeer: true).usesAtmosphere, isTrue);
      expect(const SpotFilters(outdoorSeating: true).usesAtmosphere, isTrue);
      expect(const SpotFilters(goodForGroups: true).usesAtmosphere, isTrue);
      expect(const SpotFilters(hasParking: true).usesAtmosphere, isTrue);
    });

    test('copyWith replaces fields; clearMinRating nulls it', () {
      const f = SpotFilters(minRating: 4, servesBeer: true);
      expect(f.copyWith(servesBeer: false).servesBeer, isFalse);
      expect(f.copyWith(minRating: 4.5).minRating, 4.5);
      expect(f.copyWith(clearMinRating: true).minRating, isNull);
      // unchanged fields persist
      expect(f.copyWith(openNow: true).servesBeer, isTrue);
    });

    test('supports value equality', () {
      expect(
        const SpotFilters(cuisines: {'a'}, servesBeer: true),
        const SpotFilters(cuisines: {'a'}, servesBeer: true),
      );
      expect(
        const SpotFilters(cuisines: {'a'}),
        isNot(const SpotFilters(cuisines: {'b'})),
      );
    });

    group('SpotFiltersAdapter', () {
      late Directory tempDir;

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('spot_filters_test');
        Hive.init(tempDir.path);
        if (!Hive.isAdapterRegistered(8)) {
          Hive.registerAdapter(SpotFiltersAdapter());
        }
      });

      tearDown(() async {
        await Hive.deleteFromDisk();
        await tempDir.delete(recursive: true);
      });

      test('round-trips a populated filter set', () async {
        const filters = SpotFilters(
          cuisines: {'mexican', 'hamburger'},
          servesBeer: true,
          outdoorSeating: true,
          goodForGroups: true,
          hasParking: true,
          openNow: true,
          minRating: 4.2,
          priceLevels: {1, 2, 3},
        );
        final box = await Hive.openBox<SpotFilters>('f');
        await box.put('k', filters);
        await box.close();

        final reopened = await Hive.openBox<SpotFilters>('f');
        expect(reopened.get('k'), filters);
      });

      test('round-trips defaults', () async {
        final box = await Hive.openBox<SpotFilters>('f');
        await box.put('k', const SpotFilters());
        await box.close();
        final reopened = await Hive.openBox<SpotFilters>('f');
        expect(reopened.get('k'), const SpotFilters());
      });
    });
  });
}
