import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:randoeats/models/rating_type.dart';

part 'user_rating.g.dart';

/// A user's rating of a restaurant.
@HiveType(typeId: 2)
class UserRating extends Equatable {
  /// Creates a new [UserRating] instance.
  const UserRating({
    required this.placeId,
    required this.rating,
    required this.ratedAt,
  });

  /// Creates a thumbs up rating for the given place.
  factory UserRating.thumbsUp(String placeId) {
    return UserRating(
      placeId: placeId,
      rating: RatingType.thumbsUp,
      ratedAt: DateTime.now(),
    );
  }

  /// Creates a thumbs down rating for the given place.
  factory UserRating.thumbsDown(String placeId) {
    return UserRating(
      placeId: placeId,
      rating: RatingType.thumbsDown,
      ratedAt: DateTime.now(),
    );
  }

  /// The Google Places ID of the rated restaurant.
  @HiveField(0)
  final String placeId;

  /// The rating type (thumbs up or thumbs down).
  @HiveField(1)
  final RatingType rating;

  /// When the rating was made.
  @HiveField(2)
  final DateTime ratedAt;

  /// Whether this is a positive rating.
  bool get isPositive => rating == RatingType.thumbsUp;

  /// Whether this is a negative rating.
  bool get isNegative => rating == RatingType.thumbsDown;

  @override
  List<Object?> get props => [placeId, rating, ratedAt];
}
