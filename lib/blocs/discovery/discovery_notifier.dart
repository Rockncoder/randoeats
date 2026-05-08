import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randoeats/blocs/discovery/discovery_state.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/services/services.dart';

/// Riverpod provider for restaurant discovery.
final discoveryProvider = NotifierProvider<DiscoveryNotifier, DiscoveryState>(
  DiscoveryNotifier.new,
);

/// Notifier for managing restaurant discovery.
class DiscoveryNotifier extends Notifier<DiscoveryState> {
  /// Creates a [DiscoveryNotifier].
  DiscoveryNotifier({
    PlacesService? placesService,
    LocationService? locationService,
    StorageService? storageService,
  }) : _placesService = placesService ?? PlacesService.instance,
       _locationService = locationService ?? LocationService.instance,
       _storageService = storageService ?? StorageService.instance;

  final PlacesService _placesService;
  final LocationService _locationService;
  final StorageService _storageService;

  @override
  DiscoveryState build() => const DiscoveryState();

  Future<void> start({String? mood}) async {
    state = state.copyWith(
      status: DiscoveryStatus.loading,
      mood: mood,
      clearErrorMessage: true,
    );

    // Get current location
    final locationResult = await _locationService.getCurrentLocation();

    if (locationResult is! LocationSuccess) {
      final message = switch (locationResult) {
        LocationPermissionDenied(isPermanent: true) =>
          'Location permission denied. Please enable in settings.',
        LocationPermissionDenied() =>
          'Location permission required to find nearby restaurants.',
        LocationServicesDisabled() =>
          'Please enable location services on your device.',
        LocationError(:final message) => 'Location error: $message',
        _ => 'Unable to determine location.',
      };

      state = state.copyWith(
        status: DiscoveryStatus.failure,
        errorMessage: message,
      );
      return;
    }

    final position = locationResult.position;

    // Get user settings
    final settings = _storageService.getSettings();

    // Get excluded place IDs (thumbs down + recently picked)
    final excludedIds = _storageService.getExcludedPlaceIds();

    // Fetch restaurants with user-configured radius and max results
    final placesResult = await _placesService.getNearbyRestaurants(
      latitude: position.latitude,
      longitude: position.longitude,
      mood: mood,
      excludePlaceIds: excludedIds,
      radiusMeters: settings.searchRadiusMeters,
      maxResultCount: settings.maxResults,
    );

    if (placesResult is PlacesError) {
      state = state.copyWith(
        status: DiscoveryStatus.failure,
        errorMessage: placesResult.message,
      );
      return;
    }

    // Create mutable copy of results so we can filter and sort in-place
    var restaurants = List<Restaurant>.of(
      (placesResult as PlacesSuccess).restaurants,
    );

    // Filter to only open restaurants (if setting enabled)
    if (settings.includeOpenOnly) {
      restaurants = restaurants.where((r) => r.isOpen ?? false).toList();
    }

    // Filter out banned categories
    if (settings.bannedCategories.isNotEmpty) {
      restaurants = restaurants.where((r) {
        // Keep restaurant if none of its types are in banned categories
        return !r.types.any(settings.bannedCategories.contains);
      }).toList();
    }

    if (restaurants.isEmpty) {
      final message = settings.includeOpenOnly
          ? 'No open restaurants found nearby. '
                'Try disabling "Open Only" in settings.'
          : 'No restaurants found nearby. Try adjusting your settings!';
      state = state.copyWith(
        status: DiscoveryStatus.failure,
        errorMessage: message,
      );
      return;
    }

    // Sort by visit count (unvisited first, then by ascending visit count)
    final visitCounts = _storageService.getVisitCountMap();
    restaurants.sort((a, b) {
      final countA = visitCounts[a.placeId] ?? 0;
      final countB = visitCounts[b.placeId] ?? 0;
      return countA.compareTo(countB);
    });

    state = state.copyWith(
      status: DiscoveryStatus.success,
      restaurants: restaurants,
      shownPlaceIds: restaurants.map((r) => r.placeId).toSet(),
      clearSelectedRestaurant: true,
    );
  }

  Future<void> refresh() async {
    // Re-fetch restaurants with current settings
    state = state.copyWith(status: DiscoveryStatus.loading);

    final locationResult = await _locationService.getCurrentLocation();

    if (locationResult is! LocationSuccess) {
      state = state.copyWith(
        status: DiscoveryStatus.failure,
        errorMessage: 'Unable to determine location for refresh.',
      );
      return;
    }

    final position = locationResult.position;

    // Get user settings
    final settings = _storageService.getSettings();

    // Get excluded place IDs (thumbs down + recently picked)
    final excludedIds = _storageService.getExcludedPlaceIds();

    final placesResult = await _placesService.getNearbyRestaurants(
      latitude: position.latitude,
      longitude: position.longitude,
      mood: state.mood,
      excludePlaceIds: excludedIds,
      radiusMeters: settings.searchRadiusMeters,
      maxResultCount: settings.maxResults,
    );

    if (placesResult is PlacesError) {
      state = state.copyWith(
        status: DiscoveryStatus.failure,
        errorMessage: placesResult.message,
      );
      return;
    }

    // Create mutable copy of results so we can filter and sort in-place
    var restaurants = List<Restaurant>.of(
      (placesResult as PlacesSuccess).restaurants,
    );

    // Filter to only open restaurants (if setting enabled)
    if (settings.includeOpenOnly) {
      restaurants = restaurants.where((r) => r.isOpen ?? false).toList();
    }

    // Filter out banned categories
    if (settings.bannedCategories.isNotEmpty) {
      restaurants = restaurants.where((r) {
        // Keep restaurant if none of its types are in banned categories
        return !r.types.any(settings.bannedCategories.contains);
      }).toList();
    }

    if (restaurants.isEmpty) {
      final message = settings.includeOpenOnly
          ? 'No open restaurants found nearby. '
                'Try disabling "Open Only" in settings.'
          : 'No restaurants found. Try adjusting your settings!';
      state = state.copyWith(
        status: DiscoveryStatus.failure,
        errorMessage: message,
      );
      return;
    }

    // Sort by visit count (unvisited first, then by ascending visit count)
    final visitCounts = _storageService.getVisitCountMap();
    restaurants.sort((a, b) {
      final countA = visitCounts[a.placeId] ?? 0;
      final countB = visitCounts[b.placeId] ?? 0;
      return countA.compareTo(countB);
    });

    state = state.copyWith(
      status: DiscoveryStatus.success,
      restaurants: restaurants,
      shownPlaceIds: restaurants.map((r) => r.placeId).toSet(),
      clearSelectedRestaurant: true,
    );
  }

  Future<void> selectRestaurant(Restaurant restaurant) async {
    // Increment visit count for selected restaurant
    await _storageService.incrementVisitCount(restaurant.placeId);

    state = state.copyWith(
      status: DiscoveryStatus.selected,
      selectedRestaurant: restaurant,
    );
  }

  void reset() {
    state = const DiscoveryState();
  }

  void startSpin() {
    state = state.copyWith(status: DiscoveryStatus.spinning);
  }

  Future<void> selectWinner(Restaurant restaurant) async {
    // Increment visit count for the winning restaurant
    await _storageService.incrementVisitCount(restaurant.placeId);

    state = state.copyWith(
      status: DiscoveryStatus.winner,
      selectedRestaurant: restaurant,
    );
  }

  void completeCelebration() {
    state = state.copyWith(
      status: DiscoveryStatus.selected,
    );
  }

  void removeRestaurant(String placeId) {
    // Remove the restaurant from the current list
    final updatedRestaurants = state.restaurants
        .where((r) => r.placeId != placeId)
        .toList();

    state = state.copyWith(
      status: DiscoveryStatus.success,
      restaurants: updatedRestaurants,
      clearSelectedRestaurant: true,
    );
  }
}
