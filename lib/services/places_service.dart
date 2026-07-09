import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randoeats/models/models.dart';

/// Provides the shared [PlacesService]. Injected (rather than referenced as a
/// singleton) so widgets/providers can be given a fake in tests and avoid live
/// network calls.
final placesServiceProvider = Provider<PlacesService>(
  (ref) => PlacesService.instance,
);

/// Atmosphere flags fetched for a single place on its detail view. Each is
/// true/false when Google reports it, or null when unknown.
typedef PlaceAtmosphere = ({
  bool? hasParking,
  bool? servesBeer,
  bool? servesWine,
});

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

/// Client for the RandoEats BFF (`api.randoeats.com`).
///
/// The app no longer talks to Google Places directly: the BFF holds the
/// (IP-restricted) API key, requests the right field masks, normalizes the
/// response, and caches nearby/details lookups. This class just shapes the
/// query, calls the BFF, and maps its normalized JSON back into [Restaurant]s.
class PlacesService {
  /// Creates a [PlacesService] with optional custom Dio client.
  PlacesService({Dio? client}) : _client = client ?? Dio();

  PlacesService._internal() : _client = Dio();

  /// Singleton instance.
  static final PlacesService instance = PlacesService._internal();

  final Dio _client;

  /// Base URL for the RandoEats BFF restaurant routes. Overridable at build
  /// time (e.g. for staging) via `--dart-define=RANDOEATS_API_URL=...`.
  static const _baseUrl = String.fromEnvironment(
    'RANDOEATS_API_URL',
    defaultValue: 'https://api.randoeats.com/api/v1/restaurants',
  );

  /// Fetches nearby restaurants based on location and optional mood.
  ///
  /// [latitude] and [longitude] specify the search center.
  /// [mood] is optional natural language input for filtering.
  /// [excludePlaceIds] are places to exclude from results.
  /// [radiusMeters] is the search radius in meters (default 5000).
  /// [maxResultCount] is the maximum number of results to return (default 50).
  ///
  /// The BFF applies the server-side facets (open now, rating, price) and the
  /// pricier atmosphere facets (beer/wine/patio/groups/parking); only
  /// [excludePlaceIds] is applied here, since it's driven by local history.
  Future<PlacesResult> getNearbyRestaurants({
    required double latitude,
    required double longitude,
    String? mood,
    Set<String> excludePlaceIds = const {},
    int radiusMeters = 5000,
    int maxResultCount = 50,
    SpotFilters filters = const SpotFilters(),
  }) async {
    try {
      // Cuisine chips drive the text query when there's no typed mood.
      final keyword =
          _extractKeyword(mood) ??
          (filters.cuisines.isNotEmpty ? filters.cuisines.join(' ') : null);

      final query = <String, dynamic>{
        'lat': latitude,
        'lng': longitude,
        'radius': radiusMeters,
        'max': maxResultCount,
        if (keyword != null && keyword.trim().isNotEmpty) 'q': keyword.trim(),
        if (filters.openNow) 'open': 'true',
        if (filters.minRating != null) 'min_rating': filters.minRating,
        if (filters.priceLevels.isNotEmpty)
          'price': (filters.priceLevels.toList()..sort()).join(','),
        if (filters.servesBeer) 'beer': 'true',
        if (filters.servesWine) 'wine': 'true',
        if (filters.outdoorSeating) 'patio': 'true',
        if (filters.goodForGroups) 'group': 'true',
        if (filters.hasParking) 'parking': 'true',
      };

      final response = await _client.get<Map<String, dynamic>>(
        '$_baseUrl/nearby',
        queryParameters: query,
      );

      if (response.statusCode != 200) {
        return PlacesError('HTTP ${response.statusCode}: ${response.data}');
      }
      final data = response.data;
      if (data == null) {
        return const PlacesError('Empty response from server.');
      }
      if (data.containsKey('error')) {
        return PlacesError('Server error: ${data['error']}');
      }

      final restaurants = (data['restaurants'] as List<dynamic>? ?? [])
          .map((e) => Restaurant.fromBff(e as Map<String, dynamic>))
          .where((r) => !excludePlaceIds.contains(r.placeId))
          .toList();
      return PlacesSuccess(restaurants);
    } on DioException catch (e) {
      return PlacesError('Failed to fetch restaurants: ${e.message}');
    } on Exception catch (e) {
      return PlacesError('Failed to fetch restaurants: $e');
    }
  }

  /// Fetches atmosphere flags (parking, beer, wine) for a single place.
  ///
  /// Called from the detail screen so those chips appear even when the search
  /// didn't request the atmosphere fields — one cheap BFF details lookup per
  /// opened place. The BFF caches details, so repeat opens are free.
  Future<PlaceAtmosphere> fetchAtmosphere(String placeId) async {
    const empty = (hasParking: null, servesBeer: null, servesWine: null);
    if (placeId.isEmpty) return empty;
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '$_baseUrl/$placeId',
      );
      final data = response.data;
      if (data == null || data.containsKey('error')) return empty;
      return (
        hasParking: data['hasParking'] as bool?,
        servesBeer: data['servesBeer'] as bool?,
        servesWine: data['servesWine'] as bool?,
      );
    } on DioException {
      return empty;
    }
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

  /// Builds a BFF photo URL for a given photo name.
  ///
  /// [photoName] is the full Places resource name from a [Restaurant], e.g.
  /// "places/ChIJ.../photos/AWU5...". The BFF proxies the image bytes (and
  /// holds the API key), so this URL can be loaded directly by the UI.
  ///
  /// Returns null when there's no photo name.
  String? getPhotoUrl(String? photoName, {int maxWidth = 400}) {
    if (photoName == null || photoName.isEmpty) return null;

    // photoName is "places/{placeId}/photos/{ref}"; the BFF photo route lives
    // under the place and takes the full name as the photo_ref query param.
    final segments = photoName.split('/');
    final placeId = segments.length > 1 && segments.first == 'places'
        ? segments[1]
        : 'x';

    return Uri.parse('$_baseUrl/$placeId/photo')
        .replace(
          queryParameters: {
            'photo_ref': photoName,
            'max_width': '$maxWidth',
          },
        )
        .toString();
  }

  /// Disposes the Dio client.
  void dispose() {
    _client.close();
  }
}
