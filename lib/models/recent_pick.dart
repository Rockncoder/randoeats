import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'recent_pick.g.dart';

/// A restaurant that was recently picked by the user.
@HiveType(typeId: 3)
class RecentPick extends Equatable {
  /// Creates a new [RecentPick] instance.
  const RecentPick({
    required this.placeId,
    required this.pickedAt,
  });

  /// Creates a new recent pick for the given place ID.
  factory RecentPick.now(String placeId) {
    return RecentPick(
      placeId: placeId,
      pickedAt: DateTime.now(),
    );
  }

  /// The Google Places ID of the picked restaurant.
  @HiveField(0)
  final String placeId;

  /// When the restaurant was picked.
  @HiveField(1)
  final DateTime pickedAt;

  /// Returns true if this pick should be hidden based on [hideDays].
  ///
  /// Restaurants are hidden for a configurable number of days after picking.
  bool shouldHide({required int hideDays}) {
    final hideUntil = pickedAt.add(Duration(days: hideDays));
    return DateTime.now().isBefore(hideUntil);
  }

  /// Returns the number of days since this pick was made.
  int get daysSincePick {
    return DateTime.now().difference(pickedAt).inDays;
  }

  @override
  List<Object?> get props => [placeId, pickedAt];
}
