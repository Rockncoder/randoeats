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

/// Service for interacting with Google Places API.
class PlacesService {
  /// Creates a [PlacesService] with optional custom HTTP client.
  PlacesService({http.Client? client}) : _client = client ?? http.Client();

  PlacesService._internal() : _client = http.Client();

  /// Singleton instance.
  static final PlacesService instance = PlacesService._internal();

  final http.Client _client;

  /// Google Places API key from dart-define.
  static const _apiKey = String.fromEnvironment('GOOGLE_PLACES_API_KEY');

  /// Base URL for Places API.
  static const _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  /// Default search radius in meters (5km).
  static const _defaultRadius = 5000;

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
      final restaurants = await _fetchNearbyRestaurants(
        latitude: latitude,
        longitude: longitude,
        keyword: _extractKeyword(mood),
      );

      // Filter out excluded places
      final filtered = restaurants
          .where((r) => !excludePlaceIds.contains(r.placeId))
          .toList();

      return PlacesSuccess(filtered);
    } on Exception catch (e) {
      return PlacesError('Failed to fetch restaurants: $e');
    }
  }

  /// Fetches restaurants from the Places API.
  Future<List<Restaurant>> _fetchNearbyRestaurants({
    required double latitude,
    required double longitude,
    String? keyword,
  }) async {
    final queryParams = {
      'location': '$latitude,$longitude',
      'radius': '$_defaultRadius',
      'type': 'restaurant',
      'key': _apiKey,
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
    };

    final uri = Uri.parse('$_baseUrl/nearbysearch/json')
        .replace(queryParameters: queryParams);

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final status = data['status'] as String?;

    if (status != 'OK' && status != 'ZERO_RESULTS') {
      final errorMessage = data['error_message'] as String? ?? status;
      throw Exception('Places API error: $errorMessage');
    }

    final results = data['results'] as List<dynamic>? ?? [];

    return results
        .map((r) => Restaurant.fromPlacesApi(r as Map<String, dynamic>))
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

  /// Builds a photo URL for a given photo reference.
  ///
  /// Returns null if no API key or photo reference.
  String? getPhotoUrl(String? photoReference, {int maxWidth = 400}) {
    if (_apiKey.isEmpty || photoReference == null) return null;

    return '$_baseUrl/photo'
        '?maxwidth=$maxWidth'
        '&photo_reference=$photoReference'
        '&key=$_apiKey';
  }

  /// Disposes the HTTP client.
  void dispose() {
    _client.close();
  }
}
