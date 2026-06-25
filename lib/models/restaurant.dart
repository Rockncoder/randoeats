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
    this.photoReferences = const [],
    this.isOpen,
    this.totalRatings,
    this.servesBeer,
    this.servesWine,
    this.outdoorSeating,
    this.goodForGroups,
    this.hasParking,
    this.phoneNumber,
    this.weekdayHours,
    this.editorialSummary,
  });

  /// Creates a [Restaurant] from Places API (New) response.
  factory Restaurant.fromPlacesApiNew(Map<String, dynamic> json) {
    final displayName = json['displayName'] as Map<String, dynamic>?;
    final location = json['location'] as Map<String, dynamic>?;
    final photos = json['photos'] as List<dynamic>?;
    final openingHours = json['currentOpeningHours'] as Map<String, dynamic>?;

    return Restaurant(
      placeId: json['id'] as String? ?? '',
      name: displayName?['text'] as String? ?? 'Unknown',
      address: json['formattedAddress'] as String? ?? '',
      latitude: (location?['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (location?['longitude'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble(),
      priceLevel: _parsePriceLevelNew(json['priceLevel'] as String?),
      types: _parseTypes(json),
      photoReference: _extractPhotoName(photos),
      photoReferences: _extractPhotoNames(photos),
      isOpen: openingHours?['openNow'] as bool?,
      totalRatings: json['userRatingCount'] as int?,
      servesBeer: json['servesBeer'] as bool?,
      servesWine: json['servesWine'] as bool?,
      outdoorSeating: json['outdoorSeating'] as bool?,
      goodForGroups: json['goodForGroups'] as bool?,
      hasParking: _parseParking(
        json['parkingOptions'] as Map<String, dynamic>?,
      ),
      phoneNumber: json['nationalPhoneNumber'] as String?,
      weekdayHours: _parseWeekdayHours(openingHours),
      editorialSummary:
          (json['editorialSummary'] as Map<String, dynamic>?)?['text']
              as String?,
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

  /// Photo name for fetching images from Places API (New format).
  @HiveField(8)
  final String? photoReference;

  /// Whether the restaurant is currently open.
  @HiveField(9)
  final bool? isOpen;

  /// Total number of user ratings.
  @HiveField(10)
  final int? totalRatings;

  /// Serves beer — a Places "atmosphere" field (null = unknown).
  @HiveField(11)
  final bool? servesBeer;

  /// Serves wine — a Places "atmosphere" field (null = unknown).
  @HiveField(19)
  final bool? servesWine;

  /// Whether the place has outdoor seating / a patio (null = unknown).
  @HiveField(12)
  final bool? outdoorSeating;

  /// Whether the place is good for groups (null = unknown).
  @HiveField(13)
  final bool? goodForGroups;

  /// Whether the place has any parking option (null = unknown).
  @HiveField(14)
  final bool? hasParking;

  /// National-format phone number (e.g. "(415) 555-0123"); null = unknown.
  @HiveField(15)
  final String? phoneNumber;

  /// Human-readable opening hours, one localized line per day from Places
  /// `currentOpeningHours.weekdayDescriptions` (e.g. "Monday: 9:00 AM –
  /// 5:00 PM"); null/empty = unknown.
  @HiveField(16)
  final List<String>? weekdayHours;

  /// All photo references for the place (Places `photos[].name`), in Google's
  /// order, for the swipeable gallery. [photoReference] is the first of these.
  @HiveField(17)
  final List<String> photoReferences;

  /// Short editorial description of the place from Places `editorialSummary`;
  /// null when Google has none.
  @HiveField(18)
  final String? editorialSummary;

  /// Parses price level from new API enum string format.
  static String? _parsePriceLevelNew(String? level) {
    if (level == null) return null;

    // New API returns: PRICE_LEVEL_FREE, PRICE_LEVEL_INEXPENSIVE,
    // PRICE_LEVEL_MODERATE, PRICE_LEVEL_EXPENSIVE, PRICE_LEVEL_VERY_EXPENSIVE
    return switch (level) {
      'PRICE_LEVEL_FREE' => 'Free',
      'PRICE_LEVEL_INEXPENSIVE' => r'$',
      'PRICE_LEVEL_MODERATE' => r'$$',
      'PRICE_LEVEL_EXPENSIVE' => r'$$$',
      'PRICE_LEVEL_VERY_EXPENSIVE' => r'$$$$',
      _ => null,
    };
  }

  /// Pulls the per-day opening-hours strings from a Places opening-hours map.
  static List<String>? _parseWeekdayHours(Map<String, dynamic>? hours) {
    final descriptions = hours?['weekdayDescriptions'] as List<dynamic>?;
    if (descriptions == null || descriptions.isEmpty) return null;
    return descriptions.map((e) => e.toString()).toList();
  }

  /// True if any parking option is available (Places `parkingOptions` is a map
  /// of booleans like freeParkingLot/paidParkingLot/freeStreetParking).
  static bool? _parseParking(Map<String, dynamic>? parking) {
    if (parking == null) return null;
    return parking.values.any((v) => v == true);
  }

  /// Extracts photo name from new API photos array.
  static String? _extractPhotoName(List<dynamic>? photos) {
    if (photos == null || photos.isEmpty) return null;
    final firstPhoto = photos[0] as Map<String, dynamic>?;
    return firstPhoto?['name'] as String?;
  }

  /// Extracts all photo names (capped at 10) from the new API photos array.
  static List<String> _extractPhotoNames(List<dynamic>? photos) {
    if (photos == null) return const [];
    return photos
        .take(10)
        .map((p) => (p as Map<String, dynamic>?)?['name'] as String?)
        .whereType<String>()
        .toList();
  }

  /// Parses types from new API response.
  static List<String> _parseTypes(Map<String, dynamic> json) {
    // New API has primaryType and types array
    final types = <String>[];

    final primaryType = json['primaryType'] as String?;
    if (primaryType != null) {
      types.add(primaryType);
    }

    final typesArray = json['types'] as List<dynamic>?;
    if (typesArray != null) {
      types.addAll(
        typesArray
            .map((e) => e as String)
            .where((t) => t != primaryType), // Avoid duplicates
      );
    }

    return types;
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
    photoReferences,
    isOpen,
    totalRatings,
    servesBeer,
    servesWine,
    outdoorSeating,
    goodForGroups,
    hasParking,
    phoneNumber,
    weekdayHours,
    editorialSummary,
  ];
}
