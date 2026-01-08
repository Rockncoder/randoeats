import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'user_settings.g.dart';

/// User settings for the app.
@HiveType(typeId: 4)
class UserSettings extends Equatable {
  /// Creates a new [UserSettings] instance.
  const UserSettings({
    this.hideDaysAfterPick = defaultHideDays,
    this.searchRadiusMeters = defaultSearchRadius,
    this.includeOpenOnly = true,
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

  /// Number of days to hide a restaurant after picking it.
  @HiveField(0)
  final int hideDaysAfterPick;

  /// Search radius for nearby restaurants in meters.
  @HiveField(1)
  final int searchRadiusMeters;

  /// Whether to only show restaurants that are currently open.
  @HiveField(2)
  final bool includeOpenOnly;

  /// Creates a copy with the given fields replaced.
  UserSettings copyWith({
    int? hideDaysAfterPick,
    int? searchRadiusMeters,
    bool? includeOpenOnly,
  }) {
    return UserSettings(
      hideDaysAfterPick: hideDaysAfterPick ?? this.hideDaysAfterPick,
      searchRadiusMeters: searchRadiusMeters ?? this.searchRadiusMeters,
      includeOpenOnly: includeOpenOnly ?? this.includeOpenOnly,
    );
  }

  @override
  List<Object?> get props => [
    hideDaysAfterPick,
    searchRadiusMeters,
    includeOpenOnly,
  ];
}
