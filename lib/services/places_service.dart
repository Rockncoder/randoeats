import 'package:dio/dio.dart';
import 'package:randoeats/models/models.dart';

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

/// Service for interacting with Google Places API (New).
class PlacesService {
  /// Creates a [PlacesService] with optional custom Dio client.
  PlacesService({Dio? client}) : _client = client ?? Dio();

  PlacesService._internal() : _client = Dio();

  /// Singleton instance.
  static final PlacesService instance = PlacesService._internal();

  final Dio _client;

  /// Google Places API key from dart-define.
  static const _apiKey = String.fromEnvironment('GOOGLE_PLACES_API_KEY');

  /// Base URL for Places API (New).
  static const _baseUrl = 'https://places.googleapis.com/v1';

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
      'places.nationalPhoneNumber,'
      'places.currentOpeningHours,'
      'places.editorialSummary';

  /// Extra ("atmosphere") fields, requested only when an atmosphere filter is
  /// active — these push the request into Google's pricier SKU.
  static const _atmosphereFields =
      'places.servesBeer,'
      'places.servesWine,'
      'places.outdoorSeating,'
      'places.goodForGroups,'
      'places.parkingOptions';

  static String _fieldMaskFor(SpotFilters filters) =>
      filters.usesAtmosphere ? '$_fieldMask,$_atmosphereFields' : _fieldMask;

  static List<String> _priceLevelEnums(Set<int> levels) {
    const names = {
      1: 'PRICE_LEVEL_INEXPENSIVE',
      2: 'PRICE_LEVEL_MODERATE',
      3: 'PRICE_LEVEL_EXPENSIVE',
      4: 'PRICE_LEVEL_VERY_EXPENSIVE',
    };
    return levels.map((l) => names[l]).whereType<String>().toList();
  }

  /// Fetches nearby restaurants based on location and optional mood.
  ///
  /// [latitude] and [longitude] specify the search center.
  /// [mood] is optional natural language input for filtering.
  /// [excludePlaceIds] are places to exclude from results.
  /// [radiusMeters] is the search radius in meters (default 5000).
  /// [maxResultCount] is the maximum number of results to return (default 50).
  Future<PlacesResult> getNearbyRestaurants({
    required double latitude,
    required double longitude,
    String? mood,
    Set<String> excludePlaceIds = const {},
    int radiusMeters = 5000,
    int maxResultCount = 50,
    SpotFilters filters = const SpotFilters(),
  }) async {
    if (_apiKey.isEmpty) {
      return const PlacesError(
        'Google Places API key not configured. '
        'Please set GOOGLE_PLACES_API_KEY.',
      );
    }

    try {
      // Cuisine chips drive the text query when there's no typed mood.
      final keyword =
          _extractKeyword(mood) ??
          (filters.cuisines.isNotEmpty ? filters.cuisines.join(' ') : null);
      final fieldMask = _fieldMaskFor(filters);

      // Always use Text Search: it supports pagination (up to ~60 results),
      // whereas Nearby Search caps at 20 with no page token. An empty keyword
      // browses all nearby restaurants.
      final restaurants = await _textSearchRestaurants(
        latitude: latitude,
        longitude: longitude,
        query: keyword ?? '',
        radiusMeters: radiusMeters,
        maxResultCount: maxResultCount,
        fieldMask: fieldMask,
        filters: filters,
      );

      // Filter out excluded places, then apply the atmosphere facets
      // client-side — the Places API can't filter these server-side, so we
      // keep only places it confirms match (a null/unknown value is excluded).
      var filtered = restaurants.where(
        (r) => !excludePlaceIds.contains(r.placeId),
      );
      if (filters.servesBeer) {
        filtered = filtered.where((r) => r.servesBeer ?? false);
      }
      if (filters.servesWine) {
        filtered = filtered.where((r) => r.servesWine ?? false);
      }
      if (filters.outdoorSeating) {
        filtered = filtered.where((r) => r.outdoorSeating ?? false);
      }
      if (filters.goodForGroups) {
        filtered = filtered.where((r) => r.goodForGroups ?? false);
      }
      if (filters.hasParking) {
        filtered = filtered.where((r) => r.hasParking ?? false);
      }

      return PlacesSuccess(filtered.toList());
    } on Exception catch (e) {
      return PlacesError('Failed to fetch restaurants: $e');
    }
  }

  /// Searches for restaurants using text query via Places API (New).
  Future<List<Restaurant>> _textSearchRestaurants({
    required double latitude,
    required double longitude,
    required String query,
    required int radiusMeters,
    required int maxResultCount,
    required String fieldMask,
    required SpotFilters filters,
  }) async {
    final baseData = <String, dynamic>{
      'textQuery': query.trim().isEmpty ? 'restaurant' : '$query restaurant',
      'includedType': 'restaurant',
      'locationBias': {
        'circle': {
          'center': {'latitude': latitude, 'longitude': longitude},
          'radius': radiusMeters.toDouble(),
        },
      },
    };
    // Cheap server-side filters supported by Text Search.
    if (filters.openNow) baseData['openNow'] = true;
    if (filters.minRating != null) baseData['minRating'] = filters.minRating;
    if (filters.priceLevels.isNotEmpty) {
      baseData['priceLevels'] = _priceLevelEnums(filters.priceLevels);
    }

    // Text Search returns at most 20 results per page. Page through with
    // nextPageToken until we have enough or Google stops returning a token
    // (it allows up to ~60 total). pageSize must stay constant across pages
    // when a pageToken is supplied, so trim any overflow at the end.
    final pageSize = maxResultCount.clamp(1, 20);
    final pagedMask = '$fieldMask,nextPageToken';
    final results = <Restaurant>[];
    String? pageToken;
    var firstPage = true;
    do {
      // A freshly issued page token can take a moment to become valid.
      if (!firstPage) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      final data = <String, dynamic>{
        ...baseData,
        'pageSize': pageSize,
        'pageToken': ?pageToken,
      };
      try {
        final response = await _client.post<Map<String, dynamic>>(
          '$_baseUrl/places:searchText',
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': _apiKey,
              'X-Goog-FieldMask': pagedMask,
            },
          ),
          data: data,
        );
        results.addAll(_parseResponse(response));
        pageToken = response.data?['nextPageToken'] as String?;
      } on Exception {
        // A failed first page is a real error worth surfacing; a failed later
        // page just ends pagination with whatever we already collected.
        if (results.isEmpty) rethrow;
        break;
      }
      firstPage = false;
    } while (pageToken != null && results.length < maxResultCount);

    return results.length > maxResultCount
        ? results.sublist(0, maxResultCount)
        : results;
  }

  /// Fetches atmosphere flags (parking, beer, wine) for a single place via
  /// Place Details (New).
  ///
  /// Called from the detail screen so those chips appear even when the search
  /// didn't request the (pricier) atmosphere fields — one cheap lookup per
  /// opened place rather than atmosphere fields on every result.
  Future<PlaceAtmosphere> fetchAtmosphere(String placeId) async {
    const empty = (hasParking: null, servesBeer: null, servesWine: null);
    if (placeId.isEmpty || _apiKey.isEmpty) return empty;
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '$_baseUrl/places/$placeId',
        options: Options(
          headers: {
            'X-Goog-Api-Key': _apiKey,
            'X-Goog-FieldMask': 'parkingOptions,servesBeer,servesWine',
          },
        ),
      );
      final data = response.data;
      final parking = data?['parkingOptions'] as Map<String, dynamic>?;
      return (
        hasParking: parking?.values.any((v) => v == true),
        servesBeer: data?['servesBeer'] as bool?,
        servesWine: data?['servesWine'] as bool?,
      );
    } on DioException {
      return empty;
    }
  }

  /// Parses the API response and returns a list of restaurants.
  List<Restaurant> _parseResponse(Response<Map<String, dynamic>> response) {
    if (response.statusCode != 200) {
      throw Exception(
        'HTTP ${response.statusCode}: ${response.data}',
      );
    }

    final data = response.data!;

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

  /// Disposes the Dio client.
  void dispose() {
    _client.close();
  }
}
