import 'package:equatable/equatable.dart';
import 'package:randoeats/models/models.dart';

/// Status of the discovery process.
enum DiscoveryStatus {
  /// Initial state, waiting for user action.
  initial,

  /// Searching for restaurants.
  loading,

  /// Restaurants found and displayed.
  success,

  /// Slot machine is spinning.
  spinning,

  /// Winner selected, showing celebration.
  winner,

  /// A restaurant has been selected.
  selected,

  /// An error occurred.
  failure,
}

/// State for restaurant discovery.
class DiscoveryState extends Equatable {
  /// Creates a new discovery state.
  const DiscoveryState({
    this.status = DiscoveryStatus.initial,
    this.restaurants = const [],
    this.selectedRestaurant,
    this.mood,
    this.errorMessage,
    this.notice,
    this.shownPlaceIds = const {},
  });

  /// Current status of discovery.
  final DiscoveryStatus status;

  /// List of discovered restaurants (max 5).
  final List<Restaurant> restaurants;

  /// Currently selected restaurant, if any.
  final Restaurant? selectedRestaurant;

  /// Current mood/preference input.
  final String? mood;

  /// Error message if status is failure.
  final String? errorMessage;

  /// A non-blocking advisory shown as a banner alongside (low) results — e.g.
  /// "most restaurants are closed right now". Null when there's nothing to say.
  final String? notice;

  /// Set of place IDs that have been shown in this session.
  /// Used to avoid showing the same restaurants on refresh.
  final Set<String> shownPlaceIds;

  /// Creates a copy with updated values.
  DiscoveryState copyWith({
    DiscoveryStatus? status,
    List<Restaurant>? restaurants,
    Restaurant? selectedRestaurant,
    String? mood,
    String? errorMessage,
    String? notice,
    Set<String>? shownPlaceIds,
    bool clearSelectedRestaurant = false,
    bool clearErrorMessage = false,
    bool clearNotice = false,
  }) {
    return DiscoveryState(
      status: status ?? this.status,
      restaurants: restaurants ?? this.restaurants,
      selectedRestaurant: clearSelectedRestaurant
          ? null
          : (selectedRestaurant ?? this.selectedRestaurant),
      mood: mood ?? this.mood,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      notice: clearNotice ? null : (notice ?? this.notice),
      shownPlaceIds: shownPlaceIds ?? this.shownPlaceIds,
    );
  }

  @override
  List<Object?> get props => [
    status,
    restaurants,
    selectedRestaurant,
    mood,
    errorMessage,
    notice,
    shownPlaceIds,
  ];
}
