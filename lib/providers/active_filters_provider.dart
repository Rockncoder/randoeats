// `set`/`clear` read better at call sites than assignment setters would.
// ignore_for_file: use_setters_to_change_properties
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randoeats/models/models.dart';

/// The currently active restaurant filters (the "what" of a search).
///
/// Held in memory for the session. The filter chip bar toggles facets here;
/// selecting a saved Spot replaces the whole set via `set`.
final activeFiltersProvider =
    NotifierProvider<ActiveFiltersNotifier, SpotFilters>(
      ActiveFiltersNotifier.new,
    );

/// Notifier backing [activeFiltersProvider].
class ActiveFiltersNotifier extends Notifier<SpotFilters> {
  @override
  SpotFilters build() => const SpotFilters();

  /// Replaces the whole filter set (e.g. when a Spot is selected).
  void set(SpotFilters filters) => state = filters;

  /// Clears all filters.
  void clear() => state = const SpotFilters();

  /// Applies [change] to the current filters.
  void update(SpotFilters Function(SpotFilters current) change) =>
      state = change(state);

  /// Toggles a cuisine code (e.g. 'mexican') on/off.
  void toggleCuisine(String code) {
    final next = {...state.cuisines};
    if (!next.remove(code)) next.add(code);
    state = state.copyWith(cuisines: next);
  }

  /// Toggles a price level (1–4) on/off.
  void togglePriceLevel(int level) {
    final next = {...state.priceLevels};
    if (!next.remove(level)) next.add(level);
    state = state.copyWith(priceLevels: next);
  }
}
