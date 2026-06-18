import 'package:randoeats/blocs/blocs.dart';
import 'package:randoeats/models/models.dart';

/// Fixed-state [DiscoveryNotifier] for screenshot tests.
class MockDiscoveryNotifier extends DiscoveryNotifier {
  MockDiscoveryNotifier(this._state);

  final DiscoveryState _state;

  @override
  DiscoveryState build() => _state;
}

/// Sample restaurants for screenshots.
const List<Restaurant> sampleRestaurants = [
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
    latitude: 34.053,
    longitude: -118.245,
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
    latitude: 34.054,
    longitude: -118.246,
    rating: 4.8,
    priceLevel: r'$',
    types: ['restaurant', 'mexican_restaurant'],
    isOpen: true,
    totalRatings: 342,
    weekdayHours: [
      'Monday: 11:00 AM – 9:00 PM',
      'Tuesday: 11:00 AM – 9:00 PM',
      'Wednesday: 11:00 AM – 9:00 PM',
      'Thursday: 11:00 AM – 10:00 PM',
      'Friday: 11:00 AM – 11:00 PM',
      'Saturday: 10:00 AM – 11:00 PM',
      'Sunday: 10:00 AM – 9:00 PM',
    ],
  ),
  Restaurant(
    placeId: '4',
    name: 'Lunar Noodle House',
    address: '321 Crater Way, Moonbase, CA',
    latitude: 34.055,
    longitude: -118.247,
    rating: 4,
    priceLevel: r'$$',
    types: ['restaurant', 'chinese_restaurant'],
    isOpen: true,
    totalRatings: 128,
  ),
  Restaurant(
    placeId: '5',
    name: 'Jet Age Pizza',
    address: '654 Rocket Rd, Futuretown, CA',
    latitude: 34.056,
    longitude: -118.248,
    rating: 4.6,
    priceLevel: r'$$',
    types: ['restaurant', 'pizza_restaurant'],
    isOpen: true,
    totalRatings: 415,
  ),
];

/// Pre-built discovery states for screenshots.
DiscoveryState homeState() => const DiscoveryState();

DiscoveryState resultsState() => const DiscoveryState(
  status: DiscoveryStatus.success,
  restaurants: sampleRestaurants,
);

DiscoveryState detailState() => DiscoveryState(
  status: DiscoveryStatus.selected,
  restaurants: sampleRestaurants,
  selectedRestaurant: sampleRestaurants[2],
);
