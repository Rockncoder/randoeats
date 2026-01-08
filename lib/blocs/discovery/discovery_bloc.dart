import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/services/services.dart';

part 'discovery_event.dart';
part 'discovery_state.dart';

/// Number of restaurants to show per discovery.
const int _resultsPerPage = 5;

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

  /// All fetched restaurants from the current search.
  List<Restaurant> _allRestaurants = [];

  /// Index into _allRestaurants for pagination.
  int _currentIndex = 0;

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

    // Get excluded place IDs (thumbs down + recently picked)
    final excludedIds = _storageService.getExcludedPlaceIds();

    // Fetch restaurants
    final placesResult = await _placesService.getNearbyRestaurants(
      latitude: position.latitude,
      longitude: position.longitude,
      mood: event.mood,
      excludePlaceIds: excludedIds,
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

    final restaurants = (placesResult as PlacesSuccess).restaurants;

    if (restaurants.isEmpty) {
      emit(
        state.copyWith(
          status: DiscoveryStatus.failure,
          errorMessage: 'No restaurants found nearby. Try a different mood!',
        ),
      );
      return;
    }

    // Store all results and show first page
    _allRestaurants = restaurants;
    _currentIndex = 0;

    final pageRestaurants = _getNextPage();

    emit(
      state.copyWith(
        status: DiscoveryStatus.success,
        restaurants: pageRestaurants,
        shownPlaceIds: pageRestaurants.map((r) => r.placeId).toSet(),
        clearSelectedRestaurant: true,
      ),
    );
  }

  Future<void> _onRefreshed(
    DiscoveryRefreshed event,
    Emitter<DiscoveryState> emit,
  ) async {
    // Check if we have more restaurants to show
    if (_currentIndex >= _allRestaurants.length) {
      // Need to fetch more - re-trigger search excluding shown restaurants
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

      // Get all excluded IDs (permanent + session-shown)
      final permanentExcluded = _storageService.getExcludedPlaceIds();
      final allExcluded = {...permanentExcluded, ...state.shownPlaceIds};

      final placesResult = await _placesService.getNearbyRestaurants(
        latitude: position.latitude,
        longitude: position.longitude,
        mood: state.mood,
        excludePlaceIds: allExcluded,
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

      final restaurants = (placesResult as PlacesSuccess).restaurants;

      if (restaurants.isEmpty) {
        emit(
          state.copyWith(
            status: DiscoveryStatus.failure,
            errorMessage: "No more restaurants found. That's all in your area!",
          ),
        );
        return;
      }

      _allRestaurants = restaurants;
      _currentIndex = 0;
    }

    final pageRestaurants = _getNextPage();
    final newShownIds = {...state.shownPlaceIds};
    for (final r in pageRestaurants) {
      newShownIds.add(r.placeId);
    }

    emit(
      state.copyWith(
        status: DiscoveryStatus.success,
        restaurants: pageRestaurants,
        shownPlaceIds: newShownIds,
        clearSelectedRestaurant: true,
      ),
    );
  }

  void _onRestaurantSelected(
    DiscoveryRestaurantSelected event,
    Emitter<DiscoveryState> emit,
  ) {
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
    _allRestaurants = [];
    _currentIndex = 0;
    emit(const DiscoveryState());
  }

  /// Gets the next page of restaurants from the cached results.
  List<Restaurant> _getNextPage() {
    final endIndex = (_currentIndex + _resultsPerPage).clamp(
      0,
      _allRestaurants.length,
    );
    final page = _allRestaurants.sublist(_currentIndex, endIndex);
    _currentIndex = endIndex;
    return page;
  }
}
