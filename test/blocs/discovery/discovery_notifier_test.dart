import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:randoeats/blocs/blocs.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/providers/active_filters_provider.dart';
import 'package:randoeats/providers/active_region_provider.dart';
import 'package:randoeats/services/services.dart';

class MockPlacesService extends Mock implements PlacesService {}

class MockLocationService extends Mock implements LocationService {}

class MockStorageService extends Mock implements StorageService {}

const _restaurant1 = Restaurant(
  placeId: 'place_1',
  name: 'Restaurant One',
  address: '123 Main St',
  latitude: 34,
  longitude: -118,
  rating: 4.5,
  isOpen: true,
  types: ['restaurant'],
);

const _restaurant2 = Restaurant(
  placeId: 'place_2',
  name: 'Restaurant Two',
  address: '456 Oak Ave',
  latitude: 34.1,
  longitude: -118.1,
  rating: 4,
  isOpen: true,
  types: ['restaurant'],
);

const _restaurant3 = Restaurant(
  placeId: 'place_3',
  name: 'Restaurant Three',
  address: '789 Pine Rd',
  latitude: 34.2,
  longitude: -118.2,
  rating: 4.8,
  isOpen: false,
  types: ['cafe'],
);

const List<Restaurant> _testRestaurants = [
  _restaurant1,
  _restaurant2,
  _restaurant3,
];

void main() {
  group('DiscoveryNotifier', () {
    late MockPlacesService mockPlacesService;
    late MockLocationService mockLocationService;
    late MockStorageService mockStorageService;
    late Position testPosition;

    setUpAll(() {
      registerFallbackValue(const SpotFilters());
    });

    setUp(() {
      mockPlacesService = MockPlacesService();
      mockLocationService = MockLocationService();
      mockStorageService = MockStorageService();

      testPosition = Position(
        latitude: 34.0522,
        longitude: -118.2437,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      // Default stubs
      when(
        () => mockStorageService.getSettings(),
      ).thenReturn(const UserSettings());
      when(
        () => mockStorageService.getExcludedPlaceIds(),
      ).thenReturn(<String>{});
      when(
        () => mockStorageService.getVisitCountMap(),
      ).thenReturn(<String, int>{});
      when(
        () => mockStorageService.incrementVisitCount(any()),
      ).thenAnswer((_) async {});
    });

    ProviderContainer buildContainer() {
      final notifier = DiscoveryNotifier(
        placesService: mockPlacesService,
        locationService: mockLocationService,
        storageService: mockStorageService,
      );
      final container = ProviderContainer(
        overrides: [
          discoveryProvider.overrideWith(() => notifier),
        ],
      );
      addTearDown(container.dispose);
      // Read the provider to initialize it
      container.read(discoveryProvider);
      return container;
    }

    test('initial state is correct', () {
      final container = buildContainer();
      final state = container.read(discoveryProvider);
      expect(state, const DiscoveryState());
      expect(state.status, DiscoveryStatus.initial);
      expect(state.restaurants, isEmpty);
      expect(state.selectedRestaurant, isNull);
      expect(state.mood, isNull);
      expect(state.errorMessage, isNull);
    });

    group('start', () {
      test(
        'emits [loading, success] when location and places succeed',
        () async {
          when(
            () => mockLocationService.getCurrentLocation(),
          ).thenAnswer((_) async => LocationSuccess(testPosition));
          when(
            () => mockPlacesService.getNearbyRestaurants(
              latitude: any(named: 'latitude'),
              longitude: any(named: 'longitude'),
              mood: any(named: 'mood'),
              excludePlaceIds: any(named: 'excludePlaceIds'),
              radiusMeters: any(named: 'radiusMeters'),
              maxResultCount: any(named: 'maxResultCount'),
            ),
          ).thenAnswer((_) async => const PlacesSuccess(_testRestaurants));

          final container = buildContainer();
          final states = <DiscoveryState>[];
          container.listen(
            discoveryProvider,
            (_, next) => states.add(next),
          );

          await container.read(discoveryProvider.notifier).start();

          expect(states.length, 2);
          expect(states[0].status, DiscoveryStatus.loading);
          expect(states[1].status, DiscoveryStatus.success);
          // Only open restaurants when includeOpenOnly is true (default)
          expect(states[1].restaurants.length, 2);
        },
      );

      test('emits [loading, success] with mood parameter', () async {
        when(
          () => mockLocationService.getCurrentLocation(),
        ).thenAnswer((_) async => LocationSuccess(testPosition));
        when(
          () => mockPlacesService.getNearbyRestaurants(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            mood: any(named: 'mood'),
            excludePlaceIds: any(named: 'excludePlaceIds'),
            radiusMeters: any(named: 'radiusMeters'),
            maxResultCount: any(named: 'maxResultCount'),
          ),
        ).thenAnswer((_) async => const PlacesSuccess(_testRestaurants));

        final container = buildContainer();
        final states = <DiscoveryState>[];
        container.listen(
          discoveryProvider,
          (_, next) => states.add(next),
        );

        await container.read(discoveryProvider.notifier).start(mood: 'tacos');

        expect(states.length, 2);
        expect(states[0].status, DiscoveryStatus.loading);
        expect(states[0].mood, 'tacos');
        expect(states[1].status, DiscoveryStatus.success);
      });

      test('emits [loading, failure] when location is denied', () async {
        when(
          () => mockLocationService.getCurrentLocation(),
        ).thenAnswer((_) async => const LocationPermissionDenied());

        final container = buildContainer();
        final states = <DiscoveryState>[];
        container.listen(
          discoveryProvider,
          (_, next) => states.add(next),
        );

        await container.read(discoveryProvider.notifier).start();

        expect(states.length, 2);
        expect(states[0].status, DiscoveryStatus.loading);
        expect(states[1].status, DiscoveryStatus.failure);
        expect(
          states[1].errorMessage,
          contains('Location permission required'),
        );
      });

      test(
        'emits [loading, failure] when location is permanently denied',
        () async {
          when(() => mockLocationService.getCurrentLocation()).thenAnswer(
            (_) async => const LocationPermissionDenied(isPermanent: true),
          );

          final container = buildContainer();
          final states = <DiscoveryState>[];
          container.listen(
            discoveryProvider,
            (_, next) => states.add(next),
          );

          await container.read(discoveryProvider.notifier).start();

          expect(states.length, 2);
          expect(states[0].status, DiscoveryStatus.loading);
          expect(states[1].status, DiscoveryStatus.failure);
          expect(states[1].errorMessage, contains('enable in settings'));
        },
      );

      test(
        'emits [loading, failure] when location services disabled',
        () async {
          when(
            () => mockLocationService.getCurrentLocation(),
          ).thenAnswer((_) async => const LocationServicesDisabled());

          final container = buildContainer();
          final states = <DiscoveryState>[];
          container.listen(
            discoveryProvider,
            (_, next) => states.add(next),
          );

          await container.read(discoveryProvider.notifier).start();

          expect(states.length, 2);
          expect(states[0].status, DiscoveryStatus.loading);
          expect(states[1].status, DiscoveryStatus.failure);
          expect(
            states[1].errorMessage,
            contains('enable location services'),
          );
        },
      );

      test('emits [loading, failure] when location error occurs', () async {
        when(
          () => mockLocationService.getCurrentLocation(),
        ).thenAnswer((_) async => const LocationError('GPS failed'));

        final container = buildContainer();
        final states = <DiscoveryState>[];
        container.listen(
          discoveryProvider,
          (_, next) => states.add(next),
        );

        await container.read(discoveryProvider.notifier).start();

        expect(states.length, 2);
        expect(states[0].status, DiscoveryStatus.loading);
        expect(states[1].status, DiscoveryStatus.failure);
        expect(states[1].errorMessage, contains('GPS failed'));
      });

      test('emits [loading, failure] when places API fails', () async {
        when(
          () => mockLocationService.getCurrentLocation(),
        ).thenAnswer((_) async => LocationSuccess(testPosition));
        when(
          () => mockPlacesService.getNearbyRestaurants(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            mood: any(named: 'mood'),
            excludePlaceIds: any(named: 'excludePlaceIds'),
            radiusMeters: any(named: 'radiusMeters'),
            maxResultCount: any(named: 'maxResultCount'),
          ),
        ).thenAnswer((_) async => const PlacesError('API error'));

        final container = buildContainer();
        final states = <DiscoveryState>[];
        container.listen(
          discoveryProvider,
          (_, next) => states.add(next),
        );

        await container.read(discoveryProvider.notifier).start();

        expect(states.length, 2);
        expect(states[0].status, DiscoveryStatus.loading);
        expect(states[1].status, DiscoveryStatus.failure);
        expect(states[1].errorMessage, 'API error');
      });

      test(
        'emits [loading, failure] when no restaurants found',
        () async {
          when(
            () => mockLocationService.getCurrentLocation(),
          ).thenAnswer((_) async => LocationSuccess(testPosition));
          when(
            () => mockPlacesService.getNearbyRestaurants(
              latitude: any(named: 'latitude'),
              longitude: any(named: 'longitude'),
              mood: any(named: 'mood'),
              excludePlaceIds: any(named: 'excludePlaceIds'),
              radiusMeters: any(named: 'radiusMeters'),
              maxResultCount: any(named: 'maxResultCount'),
            ),
          ).thenAnswer((_) async => const PlacesSuccess([]));

          final container = buildContainer();
          final states = <DiscoveryState>[];
          container.listen(
            discoveryProvider,
            (_, next) => states.add(next),
          );

          await container.read(discoveryProvider.notifier).start();

          expect(states.length, 2);
          expect(states[0].status, DiscoveryStatus.loading);
          expect(states[1].status, DiscoveryStatus.failure);
          expect(
            states[1].errorMessage,
            contains('No open restaurants'),
          );
        },
      );

      test('filters out banned categories', () async {
        when(() => mockStorageService.getSettings()).thenReturn(
          const UserSettings(
            includeOpenOnly: false,
            bannedCategories: {'cafe'},
          ),
        );
        when(
          () => mockLocationService.getCurrentLocation(),
        ).thenAnswer((_) async => LocationSuccess(testPosition));
        when(
          () => mockPlacesService.getNearbyRestaurants(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            mood: any(named: 'mood'),
            excludePlaceIds: any(named: 'excludePlaceIds'),
            radiusMeters: any(named: 'radiusMeters'),
            maxResultCount: any(named: 'maxResultCount'),
          ),
        ).thenAnswer((_) async => const PlacesSuccess(_testRestaurants));

        final container = buildContainer();
        final states = <DiscoveryState>[];
        container.listen(
          discoveryProvider,
          (_, next) => states.add(next),
        );

        await container.read(discoveryProvider.notifier).start();

        expect(states.length, 2);
        expect(states[0].status, DiscoveryStatus.loading);
        expect(states[1].status, DiscoveryStatus.success);
        expect(states[1].restaurants.length, 2);
      });

      test('sorts restaurants by visit count ascending', () async {
        when(() => mockStorageService.getSettings()).thenReturn(
          const UserSettings(includeOpenOnly: false),
        );
        when(() => mockStorageService.getVisitCountMap()).thenReturn({
          'place_1': 5,
          'place_2': 1,
          'place_3': 0,
        });
        when(
          () => mockLocationService.getCurrentLocation(),
        ).thenAnswer((_) async => LocationSuccess(testPosition));
        when(
          () => mockPlacesService.getNearbyRestaurants(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            mood: any(named: 'mood'),
            excludePlaceIds: any(named: 'excludePlaceIds'),
            radiusMeters: any(named: 'radiusMeters'),
            maxResultCount: any(named: 'maxResultCount'),
          ),
        ).thenAnswer((_) async => const PlacesSuccess(_testRestaurants));

        final container = buildContainer();
        final states = <DiscoveryState>[];
        container.listen(
          discoveryProvider,
          (_, next) => states.add(next),
        );

        await container.read(discoveryProvider.notifier).start();

        expect(states.length, 2);
        expect(states[0].status, DiscoveryStatus.loading);
        expect(states[1].status, DiscoveryStatus.success);
        expect(states[1].restaurants.first.placeId, 'place_3');
      });
    });

    group('region scope', () {
      const inside = Restaurant(
        placeId: 'inside',
        name: 'Inside Diner',
        address: '1 In St',
        latitude: 34,
        longitude: -118.05,
        isOpen: true,
        types: ['restaurant'],
      );
      const outside = Restaurant(
        placeId: 'outside',
        name: 'Outside Cafe',
        address: '2 Out Rd',
        latitude: 35,
        longitude: -119,
        isOpen: true,
        types: ['restaurant'],
      );
      // A square covering lat [33.9, 34.1], lng [-118.1, -118.0].
      final region = SavedRegion(
        id: 'r1',
        name: 'Orange Circle',
        points: const [
          33.9, -118.1, //
          33.9, -118.0, //
          34.1, -118.0, //
          34.1, -118.1, //
        ],
        createdAt: DateTime(2026),
      );

      void stubPlaces(List<Restaurant> results) {
        when(
          () => mockPlacesService.getNearbyRestaurants(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            mood: any(named: 'mood'),
            excludePlaceIds: any(named: 'excludePlaceIds'),
            radiusMeters: any(named: 'radiusMeters'),
            maxResultCount: any(named: 'maxResultCount'),
          ),
        ).thenAnswer((_) async => PlacesSuccess(results));
      }

      test('keeps only restaurants inside the polygon', () async {
        stubPlaces(const [inside, outside]);
        final container = buildContainer();
        container.read(activeRegionProvider.notifier).select(region);

        await container.read(discoveryProvider.notifier).start();

        final state = container.read(discoveryProvider);
        expect(state.status, DiscoveryStatus.success);
        expect(state.restaurants.map((r) => r.placeId), ['inside']);
      });

      test('does not request the device location', () async {
        stubPlaces(const [inside]);
        final container = buildContainer();
        container.read(activeRegionProvider.notifier).select(region);

        await container.read(discoveryProvider.notifier).start();

        verifyNever(() => mockLocationService.getCurrentLocation());
      });

      test('searches the region bounding circle (centroid), not GPS', () async {
        stubPlaces(const [inside]);
        final container = buildContainer();
        container.read(activeRegionProvider.notifier).select(region);

        await container.read(discoveryProvider.notifier).start();

        final captured = verify(
          () => mockPlacesService.getNearbyRestaurants(
            latitude: captureAny(named: 'latitude'),
            longitude: captureAny(named: 'longitude'),
            mood: any(named: 'mood'),
            excludePlaceIds: any(named: 'excludePlaceIds'),
            radiusMeters: any(named: 'radiusMeters'),
            maxResultCount: any(named: 'maxResultCount'),
          ),
        ).captured;
        expect(captured[0] as double, closeTo(34, 0.001));
        expect(captured[1] as double, closeTo(-118.05, 0.001));
      });

      test('emits region-specific failure when nothing is inside', () async {
        stubPlaces(const [outside]);
        final container = buildContainer();
        container.read(activeRegionProvider.notifier).select(region);

        await container.read(discoveryProvider.notifier).start();

        final state = container.read(discoveryProvider);
        expect(state.status, DiscoveryStatus.failure);
        expect(state.errorMessage, contains('Orange Circle'));
      });
    });

    group('filters', () {
      const beerMex = Restaurant(
        placeId: 'beer_mex',
        name: 'Beer Mex',
        address: 'a',
        latitude: 34,
        longitude: -118,
        rating: 4.6,
        priceLevel: r'$',
        isOpen: true,
        types: ['restaurant', 'mexican_restaurant'],
        servesBeer: true,
        outdoorSeating: true,
        goodForGroups: true,
        hasParking: true,
      );
      const sushiNoBeer = Restaurant(
        placeId: 'sushi',
        name: 'Sushi',
        address: 'b',
        latitude: 34,
        longitude: -118,
        rating: 3.9,
        priceLevel: r'$$$',
        isOpen: true,
        types: ['restaurant', 'sushi_restaurant'],
        servesBeer: false,
        outdoorSeating: false,
      );
      const burgerBeer = Restaurant(
        placeId: 'burger',
        name: 'Burger',
        address: 'c',
        latitude: 34,
        longitude: -118,
        rating: 4.2,
        priceLevel: r'$$',
        isOpen: true,
        types: ['restaurant', 'hamburger_restaurant'],
        servesBeer: true,
        outdoorSeating: false,
      );
      const all = [beerMex, sushiNoBeer, burgerBeer];

      void stubPlaces() {
        when(
          () => mockPlacesService.getNearbyRestaurants(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            mood: any(named: 'mood'),
            excludePlaceIds: any(named: 'excludePlaceIds'),
            radiusMeters: any(named: 'radiusMeters'),
            maxResultCount: any(named: 'maxResultCount'),
            filters: any(named: 'filters'),
          ),
        ).thenAnswer((_) async => const PlacesSuccess(all));
        when(
          () => mockLocationService.getCurrentLocation(),
        ).thenAnswer((_) async => LocationSuccess(testPosition));
      }

      Future<Set<String>> runWith(SpotFilters filters) async {
        stubPlaces();
        final container = buildContainer();
        container.read(activeFiltersProvider.notifier).set(filters);
        await container.read(discoveryProvider.notifier).start();
        return container
            .read(discoveryProvider)
            .restaurants
            .map((r) => r.placeId)
            .toSet();
      }

      test('cuisine keeps only matching types', () async {
        expect(await runWith(const SpotFilters(cuisines: {'mexican'})), {
          'beer_mex',
        });
      });

      test('minRating keeps only high-rated', () async {
        expect(await runWith(const SpotFilters(minRating: 4.5)), {'beer_mex'});
      });

      test('servesBeer keeps only beer places', () async {
        expect(await runWith(const SpotFilters(servesBeer: true)), {
          'beer_mex',
          'burger',
        });
      });

      test('priceLevels keeps only matching price', () async {
        final ids = await runWith(const SpotFilters(priceLevels: {1}));
        expect(ids, {'beer_mex'});
      });

      test('outdoorSeating excludes unknown/false', () async {
        expect(await runWith(const SpotFilters(outdoorSeating: true)), {
          'beer_mex',
        });
      });

      test('combined filters intersect', () async {
        final ids = await runWith(
          const SpotFilters(servesBeer: true, minRating: 4.5),
        );
        expect(ids, {'beer_mex'}); // beer AND >=4.5
      });
    });

    group('refresh', () {
      test('emits [loading, success] on refresh', () async {
        when(
          () => mockLocationService.getCurrentLocation(),
        ).thenAnswer((_) async => LocationSuccess(testPosition));
        when(
          () => mockPlacesService.getNearbyRestaurants(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            mood: any(named: 'mood'),
            excludePlaceIds: any(named: 'excludePlaceIds'),
            radiusMeters: any(named: 'radiusMeters'),
            maxResultCount: any(named: 'maxResultCount'),
          ),
        ).thenAnswer((_) async => const PlacesSuccess(_testRestaurants));

        final container = buildContainer();
        final states = <DiscoveryState>[];
        container.listen(
          discoveryProvider,
          (_, next) => states.add(next),
        );

        await container.read(discoveryProvider.notifier).refresh();

        expect(states.length, 2);
        expect(states[0].status, DiscoveryStatus.loading);
        expect(states[1].status, DiscoveryStatus.success);
      });

      test(
        'emits [loading, failure] when location fails on refresh',
        () async {
          when(
            () => mockLocationService.getCurrentLocation(),
          ).thenAnswer((_) async => const LocationServicesDisabled());

          final container = buildContainer();
          final states = <DiscoveryState>[];
          container.listen(
            discoveryProvider,
            (_, next) => states.add(next),
          );

          await container.read(discoveryProvider.notifier).refresh();

          expect(states.length, 2);
          expect(states[0].status, DiscoveryStatus.loading);
          expect(states[1].status, DiscoveryStatus.failure);
          // refresh now surfaces the same specific location messages as start.
          expect(
            states[1].errorMessage,
            contains('enable location services'),
          );
        },
      );

      test(
        'emits [loading, failure] when places API fails on refresh',
        () async {
          when(
            () => mockLocationService.getCurrentLocation(),
          ).thenAnswer((_) async => LocationSuccess(testPosition));
          when(
            () => mockPlacesService.getNearbyRestaurants(
              latitude: any(named: 'latitude'),
              longitude: any(named: 'longitude'),
              mood: any(named: 'mood'),
              excludePlaceIds: any(named: 'excludePlaceIds'),
              radiusMeters: any(named: 'radiusMeters'),
              maxResultCount: any(named: 'maxResultCount'),
            ),
          ).thenAnswer((_) async => const PlacesError('Network error'));

          final container = buildContainer();
          final states = <DiscoveryState>[];
          container.listen(
            discoveryProvider,
            (_, next) => states.add(next),
          );

          await container.read(discoveryProvider.notifier).refresh();

          expect(states.length, 2);
          expect(states[0].status, DiscoveryStatus.loading);
          expect(states[1].status, DiscoveryStatus.failure);
          expect(states[1].errorMessage, 'Network error');
        },
      );

      test(
        'emits failure when no restaurants found on refresh with open only',
        () async {
          when(
            () => mockLocationService.getCurrentLocation(),
          ).thenAnswer((_) async => LocationSuccess(testPosition));
          when(
            () => mockPlacesService.getNearbyRestaurants(
              latitude: any(named: 'latitude'),
              longitude: any(named: 'longitude'),
              mood: any(named: 'mood'),
              excludePlaceIds: any(named: 'excludePlaceIds'),
              radiusMeters: any(named: 'radiusMeters'),
              maxResultCount: any(named: 'maxResultCount'),
            ),
          ).thenAnswer((_) async => const PlacesSuccess([]));

          final container = buildContainer();
          final states = <DiscoveryState>[];
          container.listen(
            discoveryProvider,
            (_, next) => states.add(next),
          );

          await container.read(discoveryProvider.notifier).refresh();

          expect(states.length, 2);
          expect(states[0].status, DiscoveryStatus.loading);
          expect(states[1].status, DiscoveryStatus.failure);
          expect(
            states[1].errorMessage,
            contains('No open restaurants'),
          );
        },
      );

      test(
        'emits failure when no restaurants found on refresh without open only',
        () async {
          when(() => mockStorageService.getSettings()).thenReturn(
            const UserSettings(includeOpenOnly: false),
          );
          when(
            () => mockLocationService.getCurrentLocation(),
          ).thenAnswer((_) async => LocationSuccess(testPosition));
          when(
            () => mockPlacesService.getNearbyRestaurants(
              latitude: any(named: 'latitude'),
              longitude: any(named: 'longitude'),
              mood: any(named: 'mood'),
              excludePlaceIds: any(named: 'excludePlaceIds'),
              radiusMeters: any(named: 'radiusMeters'),
              maxResultCount: any(named: 'maxResultCount'),
            ),
          ).thenAnswer((_) async => const PlacesSuccess([]));

          final container = buildContainer();
          final states = <DiscoveryState>[];
          container.listen(
            discoveryProvider,
            (_, next) => states.add(next),
          );

          await container.read(discoveryProvider.notifier).refresh();

          expect(states.length, 2);
          expect(states[0].status, DiscoveryStatus.loading);
          expect(states[1].status, DiscoveryStatus.failure);
          expect(
            states[1].errorMessage,
            contains('No restaurants found'),
          );
        },
      );
    });

    group('selectRestaurant', () {
      test('emits selected state with restaurant', () async {
        final container = buildContainer();
        final states = <DiscoveryState>[];
        container.listen(
          discoveryProvider,
          (_, next) => states.add(next),
        );

        await container
            .read(discoveryProvider.notifier)
            .selectRestaurant(_restaurant1);

        expect(states.length, 1);
        expect(states[0].status, DiscoveryStatus.selected);
        expect(states[0].selectedRestaurant, _restaurant1);
        verify(
          () => mockStorageService.incrementVisitCount('place_1'),
        ).called(1);
      });
    });

    group('reset', () {
      test('emits initial state', () {
        final container = buildContainer();
        // Set non-initial state first
        container.read(discoveryProvider.notifier).startSpin();

        final states = <DiscoveryState>[];
        container.listen(
          discoveryProvider,
          (_, next) => states.add(next),
        );

        container.read(discoveryProvider.notifier).reset();

        expect(states.length, 1);
        expect(states[0], const DiscoveryState());
      });
    });

    group('startSpin', () {
      test('emits spinning state', () {
        final container = buildContainer();
        final states = <DiscoveryState>[];
        container.listen(
          discoveryProvider,
          (_, next) => states.add(next),
        );

        container.read(discoveryProvider.notifier).startSpin();

        expect(states.length, 1);
        expect(states[0].status, DiscoveryStatus.spinning);
      });
    });

    group('selectWinner', () {
      test('emits winner state with restaurant', () async {
        final container = buildContainer();
        final states = <DiscoveryState>[];
        container.listen(
          discoveryProvider,
          (_, next) => states.add(next),
        );

        await container
            .read(discoveryProvider.notifier)
            .selectWinner(_restaurant2);

        expect(states.length, 1);
        expect(states[0].status, DiscoveryStatus.winner);
        expect(states[0].selectedRestaurant, _restaurant2);
        verify(
          () => mockStorageService.incrementVisitCount('place_2'),
        ).called(1);
      });
    });

    group('completeCelebration', () {
      test('emits selected state from winner state', () async {
        final container = buildContainer();
        // Set up winner state first
        await container
            .read(discoveryProvider.notifier)
            .selectWinner(_restaurant1);

        final states = <DiscoveryState>[];
        container.listen(
          discoveryProvider,
          (_, next) => states.add(next),
        );

        container.read(discoveryProvider.notifier).completeCelebration();

        expect(states.length, 1);
        expect(states[0].status, DiscoveryStatus.selected);
      });
    });

    group('removeRestaurant', () {
      test('removes restaurant from list', () async {
        final container = buildContainer();
        // Set up success state with restaurants first
        when(
          () => mockLocationService.getCurrentLocation(),
        ).thenAnswer((_) async => LocationSuccess(testPosition));
        when(() => mockStorageService.getSettings()).thenReturn(
          const UserSettings(includeOpenOnly: false),
        );
        when(
          () => mockPlacesService.getNearbyRestaurants(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            mood: any(named: 'mood'),
            excludePlaceIds: any(named: 'excludePlaceIds'),
            radiusMeters: any(named: 'radiusMeters'),
            maxResultCount: any(named: 'maxResultCount'),
          ),
        ).thenAnswer((_) async => const PlacesSuccess(_testRestaurants));

        await container.read(discoveryProvider.notifier).start();

        final states = <DiscoveryState>[];
        container.listen(
          discoveryProvider,
          (_, next) => states.add(next),
        );

        container.read(discoveryProvider.notifier).removeRestaurant('place_2');

        expect(states.length, 1);
        expect(states[0].status, DiscoveryStatus.success);
        expect(states[0].restaurants.length, 2);
        expect(
          states[0].restaurants.any((r) => r.placeId == 'place_2'),
          isFalse,
        );
        expect(states[0].selectedRestaurant, isNull);
      });
    });
  });

  group('DiscoveryState', () {
    test('copyWith returns identical when no params', () {
      const state = DiscoveryState(
        status: DiscoveryStatus.success,
        restaurants: _testRestaurants,
        mood: 'pizza',
        errorMessage: 'err',
      );

      final copy = state.copyWith();
      expect(copy, equals(state));
    });

    test('copyWith clearSelectedRestaurant works', () {
      const state = DiscoveryState(
        status: DiscoveryStatus.selected,
        selectedRestaurant: _restaurant1,
      );

      final copy = state.copyWith(clearSelectedRestaurant: true);
      expect(copy.selectedRestaurant, isNull);
    });

    test('copyWith clearErrorMessage works', () {
      const state = DiscoveryState(
        status: DiscoveryStatus.failure,
        errorMessage: 'some error',
      );

      final copy = state.copyWith(clearErrorMessage: true);
      expect(copy.errorMessage, isNull);
    });

    test('copyWith updates individual fields', () {
      const state = DiscoveryState();
      final copy = state.copyWith(
        status: DiscoveryStatus.loading,
        mood: 'sushi',
        shownPlaceIds: {'p1', 'p2'},
      );

      expect(copy.status, DiscoveryStatus.loading);
      expect(copy.mood, 'sushi');
      expect(copy.shownPlaceIds, {'p1', 'p2'});
    });
  });
}
