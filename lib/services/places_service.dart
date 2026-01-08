import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:randoeats/models/models.dart';

/// Result types for Places API operations.
sealed class PlacesResult {
  const PlacesResult();
}

/// Successful restaurant fetch.
class PlacesSuccess extends PlacesResult {
  /// Creates a successful result with restaurants.
  const PlacesSuccess(this.restaurants);

  /// The list of restaurants found.
  final List<Restaurant> restaurants;
}

/// Error during Places API call.
class PlacesError extends PlacesResult {
  /// Creates an error result.
  const PlacesError(this.message);

  /// Error description.
  final String message;
}

/// Service for interacting with Google Places API (New).
class PlacesService {
  /// Creates a [PlacesService] with optional custom HTTP client.
  PlacesService({http.Client? client}) : _client = client ?? http.Client();

  PlacesService._internal() : _client = http.Client();

  /// Singleton instance.
  static final PlacesService instance = PlacesService._internal();

  final http.Client _client;

  /// Google Places API key from dart-define.
  static const _apiKey = String.fromEnvironment('GOOGLE_PLACES_API_KEY');

  /// Base URL for Places API (New).
  static const _baseUrl = 'https://places.googleapis.com/v1';

  /// Default search radius in meters (5km).
  static const _defaultRadius = 5000.0;

  /// Field mask for restaurant search - Pro tier fields.
  static const _fieldMask =
      'places.id,'
      'places.displayName,'
      'places.formattedAddress,'
      'places.location,'
      'places.rating,'
      'places.userRatingCount,'
      'places.priceLevel,'
      'places.photos,'
      'places.primaryType,'
      'places.currentOpeningHours';

  /// Fetches nearby restaurants based on location and optional mood.
  ///
  /// [latitude] and [longitude] specify the search center.
  /// [mood] is optional natural language input for filtering.
  /// [excludePlaceIds] are places to exclude from results.
  Future<PlacesResult> getNearbyRestaurants({
    required double latitude,
    required double longitude,
    String? mood,
    Set<String> excludePlaceIds = const {},
  }) async {
    if (_apiKey.isEmpty) {
      return const PlacesError(
        'Google Places API key not configured. '
        'Please set GOOGLE_PLACES_API_KEY.',
      );
    }

    try {
      final keyword = _extractKeyword(mood);
      final List<Restaurant> restaurants;

      // Use text search if there's a keyword, otherwise use nearby search
      if (keyword != null && keyword.isNotEmpty) {
        restaurants = await _textSearchRestaurants(
          latitude: latitude,
          longitude: longitude,
          query: keyword,
        );
      } else {
        restaurants = await _nearbySearchRestaurants(
          latitude: latitude,
          longitude: longitude,
        );
      }

      // Filter out excluded places
      final filtered = restaurants
          .where((r) => !excludePlaceIds.contains(r.placeId))
          .toList();

      return PlacesSuccess(filtered);
    } on Exception catch (e) {
      return PlacesError('Failed to fetch restaurants: $e');
    }
  }

  /// Searches for restaurants using text query via Places API (New).
  Future<List<Restaurant>> _textSearchRestaurants({
    required double latitude,
    required double longitude,
    required String query,
  }) async {
    final uri = Uri.parse('$_baseUrl/places:searchText');

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask': _fieldMask,
      },
      body: json.encode({
        'textQuery': '$query restaurant',
        'includedType': 'restaurant',
        'locationBias': {
          'circle': {
            'center': {
              'latitude': latitude,
              'longitude': longitude,
            },
            'radius': _defaultRadius,
          },
        },
        'pageSize': 10, // Fetch more to allow for filtering
      }),
    );

    return _parseResponse(response);
  }

  /// Searches for nearby restaurants via Places API (New).
  Future<List<Restaurant>> _nearbySearchRestaurants({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse('$_baseUrl/places:searchNearby');

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask': _fieldMask,
      },
      body: json.encode({
        'includedTypes': ['restaurant'],
        'locationRestriction': {
          'circle': {
            'center': {
              'latitude': latitude,
              'longitude': longitude,
            },
            'radius': _defaultRadius,
          },
        },
        'maxResultCount': 10, // Fetch more to allow for filtering
      }),
    );

    return _parseResponse(response);
  }

  /// Parses the API response and returns a list of restaurants.
  List<Restaurant> _parseResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;

    // Check for API errors
    if (data.containsKey('error')) {
      final error = data['error'] as Map<String, dynamic>;
      throw Exception('Places API error: ${error['message']}');
    }

    final places = data['places'] as List<dynamic>? ?? [];

    return places
        .map((p) => Restaurant.fromPlacesApiNew(p as Map<String, dynamic>))
        .toList();
  }

  /// Extracts a search keyword from mood input.
  ///
  /// Handles common phrases and negations.
  String? _extractKeyword(String? mood) {
    if (mood == null || mood.trim().isEmpty) return null;

    final text = mood.toLowerCase().trim();

    // Handle "I want X" patterns
    final wantMatch = RegExp(r'i want\s+(.+)').firstMatch(text);
    if (wantMatch != null) {
      return wantMatch.group(1)?.trim();
    }

    // Handle "craving X" patterns
    final cravingMatch = RegExp(r'craving\s+(.+)').firstMatch(text);
    if (cravingMatch != null) {
      return cravingMatch.group(1)?.trim();
    }

    // Handle "feeling like X" patterns
    final feelingMatch = RegExp(r'feeling like\s+(.+)').firstMatch(text);
    if (feelingMatch != null) {
      return feelingMatch.group(1)?.trim();
    }

    // If it's a simple phrase, use it directly
    // (negations like "no fast food" won't work well, but we try)
    if (!text.startsWith('no ') && !text.startsWith("don't")) {
      return text;
    }

    // For negations, we can't do much with the basic API
    // Just return null and get generic results
    return null;
  }

  /// Builds a photo URL for a given photo name (new API format).
  ///
  /// [photoName] is the full resource name from the API response,
  /// e.g., "places/ChIJ.../photos/AWU5..."
  ///
  /// Returns null if no API key or photo name.
  String? getPhotoUrl(String? photoName, {int maxWidth = 400}) {
    if (_apiKey.isEmpty || photoName == null) return null;

    return '$_baseUrl/$photoName/media'
        '?maxWidthPx=$maxWidth'
        '&key=$_apiKey';
  }

  /// Disposes the HTTP client.
  void dispose() {
    _client.close();
  }
}
