# Claude Code Instructions: Migrate to Places API (New)

## Problem
RandoEats is failing with error:
```
Places API error: You're calling a legacy API, which is not enabled for your project.
To get newer features and more functionality, switch to the Places API (New) or Routes API.
```

## Root Cause
The app is using the **legacy** Places API endpoints which are no longer available for new projects. Must migrate to **Places API (New)**.

---

## Step 1: Enable Places API (New) in Google Cloud Console

**Manual step required by developer:**

1. Go to: https://console.cloud.google.com/apis/library
2. Search for "Places API (New)"
3. Click **Enable**
4. Verify the API key has access to Places API (New)

> **Note:** This is separate from the legacy "Places API" - you need the one explicitly labeled "(New)"

---

## Step 2: Migrate Text Search API

### Legacy Endpoint (OLD - Remove This)
```
GET https://maps.googleapis.com/maps/api/place/textsearch/json?query=tacos&location=33.7,-117.9&radius=5000&type=restaurant&key=API_KEY
```

### New Endpoint (REPLACE WITH)
```
POST https://places.googleapis.com/v1/places:searchText
```

### New Request Format

```dart
// Example Dart/Flutter implementation
Future<List<Restaurant>> searchRestaurants({
  required String query,
  required double latitude,
  required double longitude,
  int radiusMeters = 5000,
}) async {
  final url = Uri.parse('https://places.googleapis.com/v1/places:searchText');
  
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
      'X-Goog-FieldMask': [
        'places.id',
        'places.displayName',
        'places.formattedAddress',
        'places.location',
        'places.rating',
        'places.userRatingCount',
        'places.priceLevel',
        'places.photos',
        'places.primaryType',
        'places.primaryTypeDisplayName',
        'places.currentOpeningHours',
        'places.regularOpeningHours',
      ].join(','),
    },
    body: jsonEncode({
      'textQuery': query,
      'includedType': 'restaurant',
      'locationBias': {
        'circle': {
          'center': {
            'latitude': latitude,
            'longitude': longitude,
          },
          'radius': radiusMeters.toDouble(),
        },
      },
      'pageSize': 5, // RandoEats shows exactly 5 options
    }),
  );
  
  if (response.statusCode != 200) {
    throw Exception('Places API error: ${response.body}');
  }
  
  final data = jsonDecode(response.body);
  return _parseRestaurants(data['places'] ?? []);
}
```

---

## Step 3: Migrate Nearby Search API (If Used)

### Legacy Endpoint (OLD)
```
GET https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=33.7,-117.9&radius=5000&type=restaurant&key=API_KEY
```

### New Endpoint (REPLACE WITH)
```
POST https://places.googleapis.com/v1/places:searchNearby
```

### New Request Format

```dart
Future<List<Restaurant>> nearbyRestaurants({
  required double latitude,
  required double longitude,
  int radiusMeters = 5000,
}) async {
  final url = Uri.parse('https://places.googleapis.com/v1/places:searchNearby');
  
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
      'X-Goog-FieldMask': [
        'places.id',
        'places.displayName',
        'places.formattedAddress',
        'places.location',
        'places.rating',
        'places.userRatingCount',
        'places.priceLevel',
        'places.photos',
        'places.primaryType',
      ].join(','),
    },
    body: jsonEncode({
      'includedTypes': ['restaurant'],
      'locationRestriction': {
        'circle': {
          'center': {
            'latitude': latitude,
            'longitude': longitude,
          },
          'radius': radiusMeters.toDouble(),
        },
      },
      'maxResultCount': 5,
    }),
  );
  
  if (response.statusCode != 200) {
    throw Exception('Places API error: ${response.body}');
  }
  
  final data = jsonDecode(response.body);
  return _parseRestaurants(data['places'] ?? []);
}
```

---

## Step 4: Update Response Parsing

### Key Field Name Changes

| Legacy Field | New Field | Notes |
|-------------|-----------|-------|
| `name` | `displayName.text` | Now nested object with `text` and `languageCode` |
| `place_id` | `id` | Direct field |
| `formatted_address` | `formattedAddress` | camelCase |
| `geometry.location.lat` | `location.latitude` | Different structure |
| `geometry.location.lng` | `location.longitude` | Different structure |
| `rating` | `rating` | Same |
| `user_ratings_total` | `userRatingCount` | camelCase |
| `price_level` | `priceLevel` | camelCase, returns enum string |
| `photos[].photo_reference` | `photos[].name` | Resource name for photo API |
| `types` | `types` | Same, but also has `primaryType` |
| `opening_hours` | `regularOpeningHours` | Different structure |

### Example Response Parser

```dart
class Restaurant {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? rating;
  final int? userRatingCount;
  final String? priceLevel;
  final String? photoName; // For fetching photos
  final String? primaryType;

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.rating,
    this.userRatingCount,
    this.priceLevel,
    this.photoName,
    this.primaryType,
  });

  factory Restaurant.fromPlacesApiNew(Map<String, dynamic> json) {
    final displayName = json['displayName'] as Map<String, dynamic>?;
    final location = json['location'] as Map<String, dynamic>?;
    final photos = json['photos'] as List<dynamic>?;

    return Restaurant(
      id: json['id'] as String,
      name: displayName?['text'] as String? ?? 'Unknown',
      address: json['formattedAddress'] as String? ?? '',
      latitude: (location?['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (location?['longitude'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingCount: json['userRatingCount'] as int?,
      priceLevel: json['priceLevel'] as String?,
      photoName: photos?.isNotEmpty == true 
          ? photos!.first['name'] as String? 
          : null,
      primaryType: json['primaryType'] as String?,
    );
  }
}

List<Restaurant> _parseRestaurants(List<dynamic> places) {
  return places
      .map((p) => Restaurant.fromPlacesApiNew(p as Map<String, dynamic>))
      .toList();
}
```

---

## Step 5: Update Photo Fetching

### Legacy Photo URL (OLD)
```
https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=PHOTO_REF&key=API_KEY
```

### New Photo URL (REPLACE WITH)
```
https://places.googleapis.com/v1/{PHOTO_NAME}/media?maxWidthPx=400&key=API_KEY
```

### Example Implementation

```dart
String getPhotoUrl(String photoName, {int maxWidth = 400}) {
  // photoName comes from response, e.g.: "places/ChIJ.../photos/AWU5..."
  return 'https://places.googleapis.com/v1/$photoName/media'
      '?maxWidthPx=$maxWidth'
      '&key=$apiKey';
}
```

---

## Step 6: Update Place Details (If Used)

### Legacy Endpoint (OLD)
```
GET https://maps.googleapis.com/maps/api/place/details/json?place_id=PLACE_ID&key=API_KEY
```

### New Endpoint (REPLACE WITH)
```
GET https://places.googleapis.com/v1/places/{PLACE_ID}
```

### Example Implementation

```dart
Future<Restaurant> getPlaceDetails(String placeId) async {
  final url = Uri.parse('https://places.googleapis.com/v1/places/$placeId');
  
  final response = await http.get(
    url,
    headers: {
      'X-Goog-Api-Key': apiKey,
      'X-Goog-FieldMask': [
        'id',
        'displayName',
        'formattedAddress',
        'location',
        'rating',
        'userRatingCount',
        'priceLevel',
        'photos',
        'regularOpeningHours',
        'websiteUri',
        'nationalPhoneNumber',
      ].join(','),
    },
  );
  
  if (response.statusCode != 200) {
    throw Exception('Places API error: ${response.body}');
  }
  
  return Restaurant.fromPlacesApiNew(jsonDecode(response.body));
}
```

> **Note:** For Place Details, field mask uses direct field names (not `places.` prefix)

---

## Field Mask Reference (By Pricing Tier)

### Essentials Tier (Lowest Cost)
```
places.id
places.displayName
places.formattedAddress
places.location
places.addressComponents
places.types
places.primaryType
places.viewport
```

### Pro Tier
```
places.rating
places.userRatingCount
places.priceLevel
places.photos
places.currentOpeningHours
places.regularOpeningHours
places.businessStatus
places.googleMapsUri
```

### Enterprise Tier
```
places.reviews
places.websiteUri
places.nationalPhoneNumber
places.internationalPhoneNumber
```

**Recommendation for RandoEats:** Use Pro tier fields for restaurant discovery:
```
places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.priceLevel,places.photos,places.primaryType
```

---

## Common Errors and Fixes

### Error: "FieldMask is a required parameter"
**Fix:** Add `X-Goog-FieldMask` header to all requests

### Error: "API key not valid"
**Fix:** Ensure API key has "Places API (New)" enabled, not just legacy "Places API"

### Error: "INVALID_ARGUMENT" on type filter
**Fix:** Use `includedType` (singular) for Text Search, `includedTypes` (array) for Nearby Search

### Error: Empty results
**Fix:** Check `locationBias` vs `locationRestriction`:
- `locationBias`: Prefers results in area but can return outside
- `locationRestriction`: Only returns results within area

---

## Testing Checklist

- [ ] Enable "Places API (New)" in Google Cloud Console
- [ ] Update all API calls to use POST with new endpoints
- [ ] Add X-Goog-FieldMask header to all requests
- [ ] Update response parsing for new field names
- [ ] Update photo URL construction
- [ ] Test with various search queries ("tacos", "pizza", "sushi", etc.)
- [ ] Verify 5 restaurants returned for RandoEats display
- [ ] Test error handling for API failures
- [ ] Run `flutter analyze --fatal-infos --fatal-warnings`
- [ ] Run `flutter test --coverage`

---

## Quick Reference: Before/After

### Before (Legacy - BROKEN)
```dart
final url = Uri.parse(
  'https://maps.googleapis.com/maps/api/place/textsearch/json'
  '?query=$query'
  '&location=$lat,$lng'
  '&radius=5000'
  '&type=restaurant'
  '&key=$apiKey'
);
final response = await http.get(url);
final results = jsonDecode(response.body)['results'];
```

### After (New - WORKING)
```dart
final url = Uri.parse('https://places.googleapis.com/v1/places:searchText');
final response = await http.post(
  url,
  headers: {
    'Content-Type': 'application/json',
    'X-Goog-Api-Key': apiKey,
    'X-Goog-FieldMask': 'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.photos',
  },
  body: jsonEncode({
    'textQuery': query,
    'includedType': 'restaurant',
    'locationBias': {
      'circle': {
        'center': {'latitude': lat, 'longitude': lng},
        'radius': 5000.0,
      },
    },
    'pageSize': 5,
  }),
);
final places = jsonDecode(response.body)['places'];
```

---

## Files to Modify

Search the codebase for these patterns and update:

```bash
# Find legacy API usage
grep -r "maps.googleapis.com/maps/api/place" --include="*.dart" lib/
grep -r "nearbysearch" --include="*.dart" lib/
grep -r "textsearch" --include="*.dart" lib/
grep -r "photo_reference" --include="*.dart" lib/
grep -r "place_id" --include="*.dart" lib/
```

Typical files to update:
- `lib/services/places_service.dart` or similar
- `lib/repositories/restaurant_repository.dart`
- `lib/data/datasources/places_api_datasource.dart`
- Any model classes parsing Places API responses

---

## Summary

1. **Enable API:** Places API (New) in Cloud Console
2. **Change method:** GET → POST (for search endpoints)
3. **Change endpoints:** 
   - Text Search: `places.googleapis.com/v1/places:searchText`
   - Nearby Search: `places.googleapis.com/v1/places:searchNearby`
   - Place Details: `places.googleapis.com/v1/places/{id}`
   - Photos: `places.googleapis.com/v1/{photoName}/media`
4. **Add headers:** `X-Goog-Api-Key` and `X-Goog-FieldMask`
5. **Update parsing:** `name` → `displayName.text`, `place_id` → `id`, etc.
