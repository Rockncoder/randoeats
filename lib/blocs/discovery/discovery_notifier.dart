import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randoeats/blocs/discovery/discovery_state.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/providers/active_region_provider.dart';
import 'package:randoeats/services/services.dart';

/// Riverpod provider for restaurant discovery.
final discoveryProvider = NotifierProvider<DiscoveryNotifier, DiscoveryState>(
  DiscoveryNotifier.new,
);

/// The resolved area to search: a center point and radius in meters.
typedef _SearchArea = ({double lat, double lng, int radiusMeters});

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

  /// Starts a new discovery, optionally filtered by [mood].
  Future<void> start({String? mood}) => _discover(mood: mood);

  /// Re-runs discovery, preserving the current mood.
  Future<void> refresh() => _discover(mood: state.mood);

  /// Shared discovery pipeline used by both [start] and [refresh].
  ///
  /// The search is scoped to the active region (a polygon) when one is set,
  /// otherwise to the device's GPS location. The body reads as a linear
  /// pipeline: resolve area → fetch → filter → sort → emit, with guard-clause
  /// early returns for each failure mode.
  Future<void> _discover({String? mood}) async {
    state = state.copyWith(
      status: DiscoveryStatus.loading,
      mood: mood,
      clearErrorMessage: true,
    );

    final region = _activeRegion();

    // Resolve the area first so a location failure short-circuits before any
    // further work (and before touching settings).
    final area = await _resolveSearchArea(region);
    if (area == null) return; // failure state already emitted

    final settings = _storageService.getSettings();
    final placesResult = await _placesService.getNearbyRestaurants(
      latitude: area.lat,
      longitude: area.lng,
      mood: mood,
      excludePlaceIds: _storageService.getExcludedPlaceIds(),
      radiusMeters: area.radiusMeters,
      maxResultCount: settings.maxResults,
    );

    if (placesResult is PlacesError) {
      state = state.copyWith(
        status: DiscoveryStatus.failure,
        errorMessage: placesResult.message,
      );
      return;
    }

    var restaurants = (placesResult as PlacesSuccess).restaurants;
    if (region != null) {
      restaurants = _filterToPolygon(restaurants, region.vertices);
    }
    restaurants = _applyFilters(restaurants, settings);

    if (restaurants.isEmpty) {
      state = state.copyWith(
        status: DiscoveryStatus.failure,
        errorMessage: _emptyMessage(settings, region),
      );
      return;
    }

    restaurants = _sortByVisits(restaurants);

    state = state.copyWith(
      status: DiscoveryStatus.success,
      restaurants: restaurants,
      shownPlaceIds: restaurants.map((r) => r.placeId).toSet(),
      clearSelectedRestaurant: true,
    );
  }

  /// The active region, or `null` for GPS ("Near Me"). A region with too few
  /// vertices to form a polygon is treated as `null` (defensive).
  SavedRegion? _activeRegion() {
    final region = ref.read(activeRegionProvider);
    if (region == null || region.vertices.length < 3) return null;
    return region;
  }

  /// Resolves where to search. For a region this is its bounding circle; for
  /// GPS it is the device location + configured radius. Emits a failure state
  /// and returns `null` when the device location can not be determined.
  Future<_SearchArea?> _resolveSearchArea(SavedRegion? region) async {
    if (region != null) {
      final circle = GeoUtils.boundingCircle(region.vertices);
      return (
        lat: circle.lat,
        lng: circle.lng,
        radiusMeters: circle.radiusMeters.round(),
      );
    }

    final locationResult = await _locationService.getCurrentLocation();
    if (locationResult is! LocationSuccess) {
      state = state.copyWith(
        status: DiscoveryStatus.failure,
        errorMessage: _locationErrorMessage(locationResult),
      );
      return null;
    }

    final position = locationResult.position;
    return (
      lat: position.latitude,
      lng: position.longitude,
      radiusMeters: _storageService.getSettings().searchRadiusMeters,
    );
  }

  List<Restaurant> _filterToPolygon(
    List<Restaurant> restaurants,
    List<({double lat, double lng})> vertices,
  ) {
    return restaurants
        .where(
          (r) => GeoUtils.isPointInPolygon(r.latitude, r.longitude, vertices),
        )
        .toList();
  }

  List<Restaurant> _applyFilters(
    List<Restaurant> restaurants,
    UserSettings settings,
  ) {
    var result = restaurants;
    if (settings.includeOpenOnly) {
      result = result.where((r) => r.isOpen ?? false).toList();
    }
    if (settings.bannedCategories.isNotEmpty) {
      result = result
          .where((r) => !r.types.any(settings.bannedCategories.contains))
          .toList();
    }
    return result;
  }

  /// Sorts unvisited first, then by ascending visit count.
  List<Restaurant> _sortByVisits(List<Restaurant> restaurants) {
    final visitCounts = _storageService.getVisitCountMap();
    return List<Restaurant>.of(restaurants)..sort((a, b) {
      final countA = visitCounts[a.placeId] ?? 0;
      final countB = visitCounts[b.placeId] ?? 0;
      return countA.compareTo(countB);
    });
  }

  String _emptyMessage(UserSettings settings, SavedRegion? region) {
    if (region != null) {
      return 'No restaurants found in ${region.name}. '
          'Try a bigger area or different settings.';
    }
    if (settings.includeOpenOnly) {
      return 'No open restaurants found nearby. '
          'Try disabling "Open Only" in settings.';
    }
    return 'No restaurants found nearby. Try adjusting your settings!';
  }

  String _locationErrorMessage(LocationResult result) => switch (result) {
    LocationPermissionDenied(isPermanent: true) =>
      'Location permission denied. Please enable in settings.',
    LocationPermissionDenied() =>
      'Location permission required to find nearby restaurants.',
    LocationServicesDisabled() =>
      'Please enable location services on your device.',
    LocationError(:final message) => 'Location error: $message',
    _ => 'Unable to determine location.',
  };

  /// Records a direct selection and marks the restaurant as visited.
  Future<void> selectRestaurant(Restaurant restaurant) async {
    await _storageService.incrementVisitCount(restaurant.placeId);
    state = state.copyWith(
      status: DiscoveryStatus.selected,
      selectedRestaurant: restaurant,
    );
  }

  /// Resets discovery to its initial state.
  void reset() {
    state = const DiscoveryState();
  }

  /// Marks the slot machine as spinning.
  void startSpin() {
    state = state.copyWith(status: DiscoveryStatus.spinning);
  }

  /// Records the slot-machine winner and marks it as visited.
  Future<void> selectWinner(Restaurant restaurant) async {
    await _storageService.incrementVisitCount(restaurant.placeId);
    state = state.copyWith(
      status: DiscoveryStatus.winner,
      selectedRestaurant: restaurant,
    );
  }

  /// Transitions from the winner celebration to the selected state.
  void completeCelebration() {
    state = state.copyWith(status: DiscoveryStatus.selected);
  }

  /// Removes a restaurant from the current results (e.g. after a thumbs-down).
  void removeRestaurant(String placeId) {
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
