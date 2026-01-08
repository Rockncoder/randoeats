import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'visited_place.g.dart';

/// Tracks a place the user has visited (tapped/selected).
@HiveType(typeId: 5)
class VisitedPlace extends Equatable {
  /// Creates a new [VisitedPlace] instance.
  const VisitedPlace({
    required this.placeId,
    required this.visitCount,
    required this.lastVisitedAt,
  });

  /// Creates a new visited place with count of 1.
  factory VisitedPlace.firstVisit(String placeId) {
    return VisitedPlace(
      placeId: placeId,
      visitCount: 1,
      lastVisitedAt: DateTime.now(),
    );
  }

  /// Google Places ID.
  @HiveField(0)
  final String placeId;

  /// Number of times the user has selected this place.
  @HiveField(1)
  final int visitCount;

  /// Timestamp of the most recent visit.
  @HiveField(2)
  final DateTime lastVisitedAt;

  /// Returns a new instance with incremented visit count.
  VisitedPlace incrementVisit() {
    return VisitedPlace(
      placeId: placeId,
      visitCount: visitCount + 1,
      lastVisitedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [placeId, visitCount, lastVisitedAt];
}
