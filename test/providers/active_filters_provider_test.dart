import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/providers/active_filters_provider.dart';

void main() {
  group('activeFiltersProvider', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    SpotFilters read() => container.read(activeFiltersProvider);
    ActiveFiltersNotifier notifier() =>
        container.read(activeFiltersProvider.notifier);

    test('defaults to empty', () {
      expect(read().isEmpty, isTrue);
    });

    test('set replaces the whole filter set', () {
      notifier().set(const SpotFilters(servesBeer: true, minRating: 4));
      expect(read().servesBeer, isTrue);
      expect(read().minRating, 4);
    });

    test('clear resets to empty', () {
      notifier()
        ..set(const SpotFilters(openNow: true))
        ..clear();
      expect(read().isEmpty, isTrue);
    });

    test('toggleCuisine adds then removes', () {
      notifier().toggleCuisine('tacos');
      expect(read().cuisines, {'tacos'});
      notifier().toggleCuisine('tacos');
      expect(read().cuisines, isEmpty);
    });

    test('togglePriceLevel adds then removes', () {
      notifier().togglePriceLevel(2);
      expect(read().priceLevels, {2});
      notifier().togglePriceLevel(2);
      expect(read().priceLevels, isEmpty);
    });

    test('update applies a copyWith change', () {
      notifier().update((f) => f.copyWith(minRating: 4));
      expect(read().minRating, 4);
    });
  });
}
