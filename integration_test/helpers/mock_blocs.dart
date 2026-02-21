import 'package:bloc/bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:randoeats/blocs/blocs.dart';
import 'package:randoeats/models/models.dart';

/// Mock [DiscoveryBloc] that emits a fixed state for screenshot tests.
class MockDiscoveryBloc extends Mock implements DiscoveryBloc {
  MockDiscoveryBloc(this._state) {
    // Allow any event to be added without throwing.
    when(() => add(any())).thenReturn(null);
    when(close).thenAnswer((_) async {});
  }

  final DiscoveryState _state;

  @override
  DiscoveryState get state => _state;

  @override
  Stream<DiscoveryState> get stream => Stream.value(_state);

  @override
  bool get isClosed => false;
}

/// Sample restaurants for screenshots.
List<Restaurant> sampleRestaurants = const [
  Restaurant(
    placeId: '1',
    name: "Rosie's Diner",
    address: '123 Atomic Ave, Retroville, CA',
    latitude: 34.0522,
    longitude: -118.2437,
    rating: 4.5,
    priceLevel: r'$$',
    types: ['restaurant', 'american_restaurant'],
    isOpen: true,
    totalRatings: 256,
  ),
  Restaurant(
    placeId: '2',
    name: 'The Space Bar',
    address: '456 Orbit Blvd, Cosmopolis, CA',
    latitude: 34.0530,
    longitude: -118.2450,
    rating: 4.2,
    priceLevel: r'$$$',
    types: ['restaurant', 'bar'],
    isOpen: true,
    totalRatings: 189,
  ),
  Restaurant(
    placeId: '3',
    name: 'Taco Nebula',
    address: '789 Stardust Ln, Galaxytown, CA',
    latitude: 34.0540,
    longitude: -118.2460,
    rating: 4.8,
    priceLevel: r'$',
    types: ['restaurant', 'mexican_restaurant'],
    isOpen: true,
    totalRatings: 342,
  ),
  Restaurant(
    placeId: '4',
    name: 'Lunar Noodle House',
    address: '321 Crater Way, Moonbase, CA',
    latitude: 34.0550,
    longitude: -118.2470,
    rating: 4.0,
    priceLevel: r'$$',
    types: ['restaurant', 'chinese_restaurant'],
    isOpen: true,
    totalRatings: 128,
  ),
  Restaurant(
    placeId: '5',
    name: 'Jet Age Pizza',
    address: '654 Rocket Rd, Futuretown, CA',
    latitude: 34.0560,
    longitude: -118.2480,
    rating: 4.6,
    priceLevel: r'$$',
    types: ['restaurant', 'pizza_restaurant'],
    isOpen: true,
    totalRatings: 415,
  ),
];

/// Pre-built discovery states for screenshots.
DiscoveryState homeState() => const DiscoveryState();

DiscoveryState resultsState() => DiscoveryState(
      status: DiscoveryStatus.success,
      restaurants: sampleRestaurants,
    );

DiscoveryState detailState() => DiscoveryState(
      status: DiscoveryStatus.selected,
      restaurants: sampleRestaurants,
      selectedRestaurant: sampleRestaurants[2],
    );
