import 'package:hive/hive.dart';

part 'rating_type.g.dart';

/// Type of rating a user can give to a restaurant.
@HiveType(typeId: 1)
enum RatingType {
  /// User liked the restaurant.
  @HiveField(0)
  thumbsUp('thumbs_up'),

  /// User disliked the restaurant.
  @HiveField(1)
  thumbsDown('thumbs_down');

  const RatingType(this.storageValue);

  /// Value used for storage and serialization.
  final String storageValue;

  /// Creates a [RatingType] from a storage value.
  static RatingType fromStorage(String value) {
    return RatingType.values.firstWhere(
      (e) => e.storageValue == value,
      orElse: () => throw ArgumentError('Invalid rating type: $value'),
    );
  }

  /// Converts to storage value.
  String toStorage() => storageValue;
}
