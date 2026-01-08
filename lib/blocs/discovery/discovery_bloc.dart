import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/services/services.dart';

part 'discovery_event.dart';
part 'discovery_state.dart';

/// BLoC for managing restaurant discovery.
class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  /// Creates a [DiscoveryBloc].
  DiscoveryBloc({
    PlacesService? placesService,
    LocationService? locationService,
    StorageService? storageService,
  }) : _placesService = placesService ?? PlacesService.instance,
       _locationService = locationService ?? LocationService.instance,
       _storageService = storageService ?? StorageService.instance,
       super(const DiscoveryState()) {
    on<DiscoveryStarted>(_onStarted);
    on<DiscoveryRefreshed>(_onRefreshed);
    on<DiscoveryRestaurantSelected>(_onRestaurantSelected);
    on<DiscoveryReset>(_onReset);
  }

  final PlacesService _placesService;
  final LocationService _locationService;
  final StorageService _storageService;

  Future<void> _onStarted(
    DiscoveryStarted event,
    Emitter<DiscoveryState> emit,
  ) async {
    emit(
      state.copyWith(
        status: DiscoveryStatus.loading,
        mood: event.mood,
        clearErrorMessage: true,
      ),
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

      emit(
        state.copyWith(
          status: DiscoveryStatus.failure,
          errorMessage: message,
        ),
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
      mood: event.mood,
      excludePlaceIds: excludedIds,
      radiusMeters: settings.searchRadiusMeters,
      maxResultCount: settings.maxResults,
    );

    if (placesResult is PlacesError) {
      emit(
        state.copyWith(
          status: DiscoveryStatus.failure,
          errorMessage: placesResult.message,
        ),
      );
      return;
    }

    var restaurants = (placesResult as PlacesSuccess).restaurants;

    // Filter to only open restaurants (if setting enabled)
    if (settings.includeOpenOnly) {
      restaurants = restaurants.where((r) => r.isOpen ?? false).toList();
    }

    if (restaurants.isEmpty) {
      final message = settings.includeOpenOnly
          ? 'No open restaurants found nearby. '
                'Try disabling "Open Only" in settings.'
          : 'No restaurants found nearby. Try a different mood!';
      emit(
        state.copyWith(
          status: DiscoveryStatus.failure,
          errorMessage: message,
        ),
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

    emit(
      state.copyWith(
        status: DiscoveryStatus.success,
        restaurants: restaurants,
        shownPlaceIds: restaurants.map((r) => r.placeId).toSet(),
        clearSelectedRestaurant: true,
      ),
    );
  }

  Future<void> _onRefreshed(
    DiscoveryRefreshed event,
    Emitter<DiscoveryState> emit,
  ) async {
    // Re-fetch restaurants with current settings
    emit(state.copyWith(status: DiscoveryStatus.loading));

    final locationResult = await _locationService.getCurrentLocation();

    if (locationResult is! LocationSuccess) {
      emit(
        state.copyWith(
          status: DiscoveryStatus.failure,
          errorMessage: 'Unable to determine location for refresh.',
        ),
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
      emit(
        state.copyWith(
          status: DiscoveryStatus.failure,
          errorMessage: placesResult.message,
        ),
      );
      return;
    }

    var restaurants = (placesResult as PlacesSuccess).restaurants;

    // Filter to only open restaurants (if setting enabled)
    if (settings.includeOpenOnly) {
      restaurants = restaurants.where((r) => r.isOpen ?? false).toList();
    }

    if (restaurants.isEmpty) {
      final message = settings.includeOpenOnly
          ? 'No open restaurants found nearby. '
                'Try disabling "Open Only" in settings.'
          : "No restaurants found. That's all in your area!";
      emit(
        state.copyWith(
          status: DiscoveryStatus.failure,
          errorMessage: message,
        ),
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

    emit(
      state.copyWith(
        status: DiscoveryStatus.success,
        restaurants: restaurants,
        shownPlaceIds: restaurants.map((r) => r.placeId).toSet(),
        clearSelectedRestaurant: true,
      ),
    );
  }

  Future<void> _onRestaurantSelected(
    DiscoveryRestaurantSelected event,
    Emitter<DiscoveryState> emit,
  ) async {
    // Increment visit count for selected restaurant
    await _storageService.incrementVisitCount(event.restaurant.placeId);

    emit(
      state.copyWith(
        status: DiscoveryStatus.selected,
        selectedRestaurant: event.restaurant,
      ),
    );
  }

  void _onReset(
    DiscoveryReset event,
    Emitter<DiscoveryState> emit,
  ) {
    emit(const DiscoveryState());
  }
}
