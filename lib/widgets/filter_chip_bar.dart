import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randoeats/config/config.dart';
import 'package:randoeats/providers/active_filters_provider.dart';
import 'package:randoeats/widgets/chip_row_label.dart';
import 'package:randoeats/widgets/horizontal_scroll_fade.dart';

/// A cuisine option: a Places type keyword + a label/icon for the chip.
typedef _Cuisine = ({String code, String label, IconData icon});

const List<_Cuisine> _cuisines = [
  (code: 'mexican', label: 'Mexican', icon: Icons.local_dining),
  (code: 'hamburger', label: 'Burgers', icon: Icons.lunch_dining),
  (code: 'sushi', label: 'Sushi', icon: Icons.set_meal),
  (code: 'pizza', label: 'Pizza', icon: Icons.local_pizza),
  (code: 'coffee', label: 'Coffee', icon: Icons.local_cafe),
];

/// A one-tap, no-typing filter row: cuisine chips + atmosphere/rating/price
/// toggles. All taps drive [activeFiltersProvider].
class FilterChipBar extends ConsumerWidget {
  /// Creates a [FilterChipBar].
  const FilterChipBar({this.onSaveSpot, super.key});

  /// Called when the user taps the trailing "save as Spot" star. The star is
  /// shown only when this is non-null and at least one filter is active.
  final VoidCallback? onSaveSpot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(activeFiltersProvider);
    final notifier = ref.read(activeFiltersProvider.notifier);

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          const ChipRowLabel(icon: Icons.tune, label: 'Filters'),
          Expanded(
            child: HorizontalScrollFade(
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 4, right: 16),
                children: [
                  for (final c in _cuisines)
                    _FacetChip(
                      key: ValueKey('filter_cuisine_${c.code}'),
                      label: c.label,
                      icon: c.icon,
                      selected: filters.cuisines.contains(c.code),
                      onToggle: () => notifier.toggleCuisine(c.code),
                    ),
                  _FacetChip(
                    key: const ValueKey('filter_beer'),
                    label: 'Beer',
                    icon: Icons.sports_bar,
                    selected: filters.servesBeer,
                    onToggle: () => notifier.update(
                      (f) => f.copyWith(servesBeer: !f.servesBeer),
                    ),
                  ),
                  _FacetChip(
                    key: const ValueKey('filter_patio'),
                    label: 'Patio',
                    icon: Icons.deck,
                    selected: filters.outdoorSeating,
                    onToggle: () => notifier.update(
                      (f) => f.copyWith(outdoorSeating: !f.outdoorSeating),
                    ),
                  ),
                  _FacetChip(
                    key: const ValueKey('filter_parking'),
                    label: 'Parking',
                    icon: Icons.local_parking,
                    selected: filters.hasParking,
                    onToggle: () => notifier.update(
                      (f) => f.copyWith(hasParking: !f.hasParking),
                    ),
                  ),
                  _FacetChip(
                    key: const ValueKey('filter_group'),
                    label: 'Group',
                    icon: Icons.groups,
                    selected: filters.goodForGroups,
                    onToggle: () => notifier.update(
                      (f) => f.copyWith(goodForGroups: !f.goodForGroups),
                    ),
                  ),
                  _FacetChip(
                    key: const ValueKey('filter_open'),
                    label: 'Open',
                    icon: Icons.schedule,
                    selected: filters.openNow,
                    onToggle: () =>
                        notifier.update((f) => f.copyWith(openNow: !f.openNow)),
                  ),
                  _FacetChip(
                    key: const ValueKey('filter_rating'),
                    label: '4.0+',
                    icon: Icons.star,
                    selected: filters.minRating != null,
                    onToggle: () => notifier.update(
                      (f) => f.minRating != null
                          ? f.copyWith(clearMinRating: true)
                          : f.copyWith(minRating: 4),
                    ),
                  ),
                  for (final level in const [1, 2, 3])
                    _FacetChip(
                      key: ValueKey('filter_price_$level'),
                      label: r'$' * level,
                      selected: filters.priceLevels.contains(level),
                      onToggle: () => notifier.togglePriceLevel(level),
                    ),
                ],
              ),
            ),
          ),
          // Pinned trailing action (outside the scroll/fade so it stays fully
          // visible): save the current ad-hoc filters as a named Spot.
          if (onSaveSpot != null && !filters.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: ActionChip(
                key: const ValueKey('filter_save_spot'),
                avatar: const Icon(
                  Icons.star,
                  size: 18,
                  color: GoogieColors.deepTeal,
                ),
                label: const Text('Save Spot'),
                labelStyle: const TextStyle(
                  color: GoogieColors.deepTeal,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: GoogieColors.mustard,
                side: const BorderSide(color: GoogieColors.chrome),
                onPressed: onSaveSpot,
              ),
            ),
        ],
      ),
    );
  }
}

class _FacetChip extends StatelessWidget {
  const _FacetChip({
    required this.label,
    required this.selected,
    required this.onToggle,
    this.icon,
    super.key,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? GoogieColors.white : GoogieColors.deepTeal;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: ChoiceChip(
        avatar: icon == null ? null : Icon(icon, size: 18, color: foreground),
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        labelStyle: TextStyle(color: foreground, fontWeight: FontWeight.w600),
        selectedColor: GoogieColors.coral,
        backgroundColor: GoogieColors.cream,
        side: const BorderSide(color: GoogieColors.chrome),
        onSelected: (_) => onToggle(),
      ),
    );
  }
}
