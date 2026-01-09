part of 'discovery_bloc.dart';

/// Base class for all discovery events.
sealed class DiscoveryEvent extends Equatable {
  const DiscoveryEvent();

  @override
  List<Object?> get props => [];
}

/// Event to start discovering restaurants.
///
/// Triggers a search for nearby restaurants based on current location
/// and optional mood input.
class DiscoveryStarted extends DiscoveryEvent {
  /// Creates a discovery started event.
  const DiscoveryStarted({this.mood});

  /// Optional mood/preference input from user.
  final String? mood;

  @override
  List<Object?> get props => [mood];
}

/// Event to refresh restaurant results.
///
/// Fetches a new set of restaurants, excluding previously shown ones.
class DiscoveryRefreshed extends DiscoveryEvent {
  const DiscoveryRefreshed();
}

/// Event when a restaurant is selected from the list.
class DiscoveryRestaurantSelected extends DiscoveryEvent {
  /// Creates a restaurant selected event.
  const DiscoveryRestaurantSelected(this.restaurant);

  /// The selected restaurant.
  final Restaurant restaurant;

  @override
  List<Object?> get props => [restaurant];
}

/// Event to reset discovery and return to initial state.
class DiscoveryReset extends DiscoveryEvent {
  const DiscoveryReset();
}

/// Event to start the slot machine spin animation.
class DiscoverySpinStarted extends DiscoveryEvent {
  const DiscoverySpinStarted();
}

/// Event when the slot machine spin completes with a winner.
class DiscoveryWinnerSelected extends DiscoveryEvent {
  /// Creates a winner selected event.
  const DiscoveryWinnerSelected(this.restaurant);

  /// The winning restaurant.
  final Restaurant restaurant;

  @override
  List<Object?> get props => [restaurant];
}

/// Event when the winner celebration completes.
class DiscoveryCelebrationComplete extends DiscoveryEvent {
  const DiscoveryCelebrationComplete();
}

/// Event to remove a restaurant from the current list (after thumbs down).
class DiscoveryRestaurantRemoved extends DiscoveryEvent {
  /// Creates a restaurant removed event.
  const DiscoveryRestaurantRemoved(this.placeId);

  /// The place ID of the restaurant to remove.
  final String placeId;

  @override
  List<Object?> get props => [placeId];
}
