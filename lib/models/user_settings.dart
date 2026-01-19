import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'user_settings.g.dart';

/// Distance unit for displaying distances.
@HiveType(typeId: 6)
enum DistanceUnit {
  /// Distance in miles.
  @HiveField(0)
  miles,

  /// Distance in kilometers.
  @HiveField(1)
  kilometers;

  /// The abbreviation for this unit.
  String get abbreviation => switch (this) {
    DistanceUnit.miles => 'mi',
    DistanceUnit.kilometers => 'km',
  };

  /// Formats a distance in meters to this unit.
  String format(double meters) {
    final value = switch (this) {
      DistanceUnit.miles => meters / 1609.34,
      DistanceUnit.kilometers => meters / 1000,
    };
    return '${value.toStringAsFixed(1)} $abbreviation';
  }
}

/// User settings for the app.
@HiveType(typeId: 4)
class UserSettings extends Equatable {
  /// Creates a new [UserSettings] instance.
  const UserSettings({
    this.hideDaysAfterPick = defaultHideDays,
    this.searchRadiusMeters = defaultSearchRadius,
    this.includeOpenOnly = true,
    this.maxResults = defaultMaxResults,
    this.distanceUnit = DistanceUnit.miles,
    this.bannedCategories = const {},
  });

  /// Default number of days to hide a restaurant after picking.
  static const int defaultHideDays = 7;

  /// Minimum hide days allowed.
  static const int minHideDays = 1;

  /// Maximum hide days allowed.
  static const int maxHideDays = 30;

  /// Default search radius in meters (1.5 km).
  static const int defaultSearchRadius = 1500;

  /// Minimum search radius in meters (500 m).
  static const int minSearchRadius = 500;

  /// Maximum search radius in meters (10 km).
  static const int maxSearchRadius = 10000;

  /// Default maximum results to show.
  static const int defaultMaxResults = 20;

  /// Minimum results to show.
  static const int minMaxResults = 5;

  /// Maximum results to show.
  static const int maxMaxResults = 50;

  /// Number of days to hide a restaurant after picking it.
  @HiveField(0)
  final int hideDaysAfterPick;

  /// Search radius for nearby restaurants in meters.
  @HiveField(1)
  final int searchRadiusMeters;

  /// Whether to only show restaurants that are currently open.
  @HiveField(2)
  final bool includeOpenOnly;

  /// Maximum number of results to display.
  @HiveField(3)
  final int maxResults;

  /// The unit to display distances in.
  @HiveField(4)
  final DistanceUnit distanceUnit;

  /// Set of banned restaurant category types (Google Places types).
  @HiveField(5)
  final Set<String> bannedCategories;

  /// Creates a copy with the given fields replaced.
  UserSettings copyWith({
    int? hideDaysAfterPick,
    int? searchRadiusMeters,
    bool? includeOpenOnly,
    int? maxResults,
    DistanceUnit? distanceUnit,
    Set<String>? bannedCategories,
  }) {
    return UserSettings(
      hideDaysAfterPick: hideDaysAfterPick ?? this.hideDaysAfterPick,
      searchRadiusMeters: searchRadiusMeters ?? this.searchRadiusMeters,
      includeOpenOnly: includeOpenOnly ?? this.includeOpenOnly,
      maxResults: maxResults ?? this.maxResults,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      bannedCategories: bannedCategories ?? this.bannedCategories,
    );
  }

  @override
  List<Object?> get props => [
    hideDaysAfterPick,
    searchRadiusMeters,
    includeOpenOnly,
    maxResults,
    distanceUnit,
    bannedCategories,
  ];
}
