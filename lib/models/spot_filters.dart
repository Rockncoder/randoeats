import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'spot_filters.g.dart';

/// The "what" half of a Spot: a tappable set of restaurant filters.
///
/// An all-default [SpotFilters] (everything off/empty) means "no filtering" and
/// reproduces today's behavior. Filters split into cheap ones (cuisine, open,
/// rating, price) and pricier "atmosphere" ones (beer, patio, groups, parking)
/// — see [usesAtmosphere].
@HiveType(typeId: 8)
class SpotFilters extends Equatable {
  /// Creates a [SpotFilters]. All fields default to "no filter".
  const SpotFilters({
    this.cuisines = const {},
    this.servesBeer = false,
    this.outdoorSeating = false,
    this.goodForGroups = false,
    this.hasParking = false,
    this.openNow = false,
    this.minRating,
    this.priceLevels = const {},
  });

  /// Google Places type keywords to match (e.g. `{'mexican', 'hamburger'}`).
  @HiveField(0)
  final Set<String> cuisines;

  /// Only places that serve beer (atmosphere field).
  @HiveField(1)
  final bool servesBeer;

  /// Only places with outdoor seating / a patio (atmosphere field).
  @HiveField(2)
  final bool outdoorSeating;

  /// Only places that are good for groups (atmosphere field).
  @HiveField(3)
  final bool goodForGroups;

  /// Only places with parking (atmosphere field).
  @HiveField(4)
  final bool hasParking;

  /// Only places open now.
  @HiveField(5)
  final bool openNow;

  /// Minimum star rating (e.g. 4.0 = "above average"); null = any.
  @HiveField(6)
  final double? minRating;

  /// Allowed price levels (1–4); empty = any.
  @HiveField(7)
  final Set<int> priceLevels;

  /// Whether any filter is active (all-default = empty = no filtering).
  bool get isEmpty =>
      cuisines.isEmpty &&
      !servesBeer &&
      !outdoorSeating &&
      !goodForGroups &&
      !hasParking &&
      !openNow &&
      minRating == null &&
      priceLevels.isEmpty;

  /// Whether any atmosphere filter is active (these need the pricier Places
  /// field mask — request those fields only when this is true).
  bool get usesAtmosphere =>
      servesBeer || outdoorSeating || goodForGroups || hasParking;

  /// Display labels for known cuisine codes; unknown codes are title-cased.
  static const _cuisineLabels = <String, String>{
    'mexican': 'Mexican',
    'hamburger': 'Burgers',
    'sushi': 'Sushi',
    'pizza': 'Pizza',
    'coffee': 'Coffee',
  };

  /// A short, human-friendly summary of the active filters, e.g.
  /// `Mexican · Beer · 4.0+`. Empty string when no filters are active.
  String get summaryLabel {
    final sortedCuisines = cuisines.toList()..sort();
    final sortedPrices = priceLevels.toList()..sort();
    final parts = <String>[
      for (final c in sortedCuisines)
        _cuisineLabels[c] ??
            (c.isEmpty ? c : '${c[0].toUpperCase()}${c.substring(1)}'),
      if (servesBeer) 'Beer',
      if (outdoorSeating) 'Patio',
      if (hasParking) 'Parking',
      if (goodForGroups) 'Group',
      if (openNow) 'Open',
      if (minRating != null) '${minRating!.toStringAsFixed(1)}+',
      for (final level in sortedPrices) r'$' * level,
    ];
    return parts.join(' · ');
  }

  /// Count of active filter facets (for a chip-bar badge).
  int get activeCount {
    var n = 0;
    if (cuisines.isNotEmpty) n++;
    if (servesBeer) n++;
    if (outdoorSeating) n++;
    if (goodForGroups) n++;
    if (hasParking) n++;
    if (openNow) n++;
    if (minRating != null) n++;
    if (priceLevels.isNotEmpty) n++;
    return n;
  }

  /// Returns a copy with the given fields replaced. Pass `clearMinRating: true`
  /// to set [minRating] back to null.
  SpotFilters copyWith({
    Set<String>? cuisines,
    bool? servesBeer,
    bool? outdoorSeating,
    bool? goodForGroups,
    bool? hasParking,
    bool? openNow,
    double? minRating,
    bool clearMinRating = false,
    Set<int>? priceLevels,
  }) {
    return SpotFilters(
      cuisines: cuisines ?? this.cuisines,
      servesBeer: servesBeer ?? this.servesBeer,
      outdoorSeating: outdoorSeating ?? this.outdoorSeating,
      goodForGroups: goodForGroups ?? this.goodForGroups,
      hasParking: hasParking ?? this.hasParking,
      openNow: openNow ?? this.openNow,
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      priceLevels: priceLevels ?? this.priceLevels,
    );
  }

  @override
  List<Object?> get props => [
    cuisines,
    servesBeer,
    outdoorSeating,
    goodForGroups,
    hasParking,
    openNow,
    minRating,
    priceLevels,
  ];
}
