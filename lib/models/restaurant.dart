import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'restaurant.g.dart';

/// Restaurant data from Google Places API.
@HiveType(typeId: 0)
class Restaurant extends Equatable {
  /// Creates a new [Restaurant] instance.
  const Restaurant({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.rating,
    this.priceLevel,
    this.types = const [],
    this.photoReference,
    this.isOpen,
    this.totalRatings,
  });

  /// Creates a [Restaurant] from a Google Places API response.
  factory Restaurant.fromPlacesApi(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;

    return Restaurant(
      placeId: json['place_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['vicinity'] as String? ?? '',
      latitude: (location?['lat'] as num?)?.toDouble() ?? 0,
      longitude: (location?['lng'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble(),
      priceLevel: _parsePriceLevel(json['price_level'] as int?),
      types:
          (json['types'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      photoReference: _extractPhotoReference(json['photos']),
      isOpen: _parseOpenStatus(json['opening_hours']),
      totalRatings: json['user_ratings_total'] as int?,
    );
  }

  /// Unique identifier from Google Places.
  @HiveField(0)
  final String placeId;

  /// Restaurant name.
  @HiveField(1)
  final String name;

  /// Street address or vicinity.
  @HiveField(2)
  final String address;

  /// Latitude coordinate.
  @HiveField(3)
  final double latitude;

  /// Longitude coordinate.
  @HiveField(4)
  final double longitude;

  /// Google rating (1.0 - 5.0).
  @HiveField(5)
  final double? rating;

  /// Price level indicator ($, $$, $$$, $$$$).
  @HiveField(6)
  final String? priceLevel;

  /// Restaurant type tags (e.g., 'restaurant', 'cafe', 'bar').
  @HiveField(7)
  final List<String> types;

  /// Photo reference for fetching images from Places API.
  @HiveField(8)
  final String? photoReference;

  /// Whether the restaurant is currently open.
  @HiveField(9)
  final bool? isOpen;

  /// Total number of user ratings.
  @HiveField(10)
  final int? totalRatings;

  static String? _parsePriceLevel(int? level) {
    if (level == null) return null;
    return List.filled(level, r'$').join();
  }

  static String? _extractPhotoReference(dynamic photos) {
    if (photos == null || photos is! List || photos.isEmpty) return null;
    final firstPhoto = photos[0] as Map<String, dynamic>?;
    return firstPhoto?['photo_reference'] as String?;
  }

  static bool? _parseOpenStatus(dynamic openingHours) {
    if (openingHours == null || openingHours is! Map) return null;
    return openingHours['open_now'] as bool?;
  }

  @override
  List<Object?> get props => [
    placeId,
    name,
    address,
    latitude,
    longitude,
    rating,
    priceLevel,
    types,
    photoReference,
    isOpen,
    totalRatings,
  ];
}
