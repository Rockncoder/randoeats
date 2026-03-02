import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:randoeats/blocs/blocs.dart';
import 'package:randoeats/models/models.dart';
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
  group('DiscoveryBloc', () {
    late MockPlacesService mockPlacesService;
    late MockLocationService mockLocationService;
    late MockStorageService mockStorageService;
    late Position testPosition;

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
      when(() => mockStorageService.getSettings())
          .thenReturn(const UserSettings());
      when(() => mockStorageService.getExcludedPlaceIds())
          .thenReturn(<String>{});
      when(() => mockStorageService.getVisitCountMap())
          .thenReturn(<String, int>{});
      when(() => mockStorageService.incrementVisitCount(any()))
          .thenAnswer((_) async {});
    });

    DiscoveryBloc buildBloc() {
      return DiscoveryBloc(
        placesService: mockPlacesService,
        locationService: mockLocationService,
        storageService: mockStorageService,
      );
    }

    test('initial state is correct', () {
      final bloc = buildBloc();
      expect(bloc.state, const DiscoveryState());
      expect(bloc.state.status, DiscoveryStatus.initial);
      expect(bloc.state.restaurants, isEmpty);
      expect(bloc.state.selectedRestaurant, isNull);
      expect(bloc.state.mood, isNull);
      expect(bloc.state.errorMessage, isNull);
    });

    group('DiscoveryStarted', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits [loading, success] when location and places succeed',
        setUp: () {
          when(() => mockLocationService.getCurrentLocation())
              .thenAnswer((_) async => LocationSuccess(testPosition));
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
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const DiscoveryStarted()),
        expect: () => [
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.loading),
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.success)
              .having(
                (s) => s.restaurants.length,
                'restaurants count',
                // Only open restaurants when includeOpenOnly is true (default)
                2,
              ),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits [loading, success] with mood parameter',
        setUp: () {
          when(() => mockLocationService.getCurrentLocation())
              .thenAnswer((_) async => LocationSuccess(testPosition));
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
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const DiscoveryStarted(mood: 'tacos')),
        expect: () => [
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.loading)
              .having((s) => s.mood, 'mood', 'tacos'),
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.success),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits [loading, failure] when location is denied',
        setUp: () {
          when(() => mockLocationService.getCurrentLocation())
              .thenAnswer((_) async => const LocationPermissionDenied());
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const DiscoveryStarted()),
        expect: () => [
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.loading),
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.failure)
              .having(
                (s) => s.errorMessage,
                'error',
                contains('Location permission required'),
              ),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits [loading, failure] when location is permanently denied',
        setUp: () {
          when(() => mockLocationService.getCurrentLocation()).thenAnswer(
            (_) async => const LocationPermissionDenied(isPermanent: true),
          );
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const DiscoveryStarted()),
        expect: () => [
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.loading),
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.failure)
              .having(
                (s) => s.errorMessage,
                'error',
                contains('enable in settings'),
              ),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits [loading, failure] when location services disabled',
        setUp: () {
          when(() => mockLocationService.getCurrentLocation())
              .thenAnswer((_) async => const LocationServicesDisabled());
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const DiscoveryStarted()),
        expect: () => [
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.loading),
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.failure)
              .having(
                (s) => s.errorMessage,
                'error',
                contains('enable location services'),
              ),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits [loading, failure] when location error occurs',
        setUp: () {
          when(() => mockLocationService.getCurrentLocation())
              .thenAnswer((_) async => const LocationError('GPS failed'));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const DiscoveryStarted()),
        expect: () => [
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.loading),
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.failure)
              .having(
                (s) => s.errorMessage,
                'error',
                contains('GPS failed'),
              ),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits [loading, failure] when places API fails',
        setUp: () {
          when(() => mockLocationService.getCurrentLocation())
              .thenAnswer((_) async => LocationSuccess(testPosition));
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
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const DiscoveryStarted()),
        expect: () => [
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.loading),
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.failure)
              .having((s) => s.errorMessage, 'error', 'API error'),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits [loading, failure] when no restaurants found',
        setUp: () {
          when(() => mockLocationService.getCurrentLocation())
              .thenAnswer((_) async => LocationSuccess(testPosition));
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
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const DiscoveryStarted()),
        expect: () => [
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.loading),
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.failure)
              .having(
                (s) => s.errorMessage,
                'error',
                contains('No open restaurants'),
              ),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'filters out banned categories',
        setUp: () {
          when(() => mockStorageService.getSettings()).thenReturn(
            const UserSettings(
              includeOpenOnly: false,
              bannedCategories: {'cafe'},
            ),
          );
          when(() => mockLocationService.getCurrentLocation())
              .thenAnswer((_) async => LocationSuccess(testPosition));
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
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const DiscoveryStarted()),
        expect: () => [
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.loading),
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.success)
              .having(
                (s) => s.restaurants.length,
                'restaurants without cafe',
                2,
              ),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'sorts restaurants by visit count ascending',
        setUp: () {
          when(() => mockStorageService.getSettings()).thenReturn(
            const UserSettings(includeOpenOnly: false),
          );
          when(() => mockStorageService.getVisitCountMap()).thenReturn({
            'place_1': 5,
            'place_2': 1,
            'place_3': 0,
          });
          when(() => mockLocationService.getCurrentLocation())
              .thenAnswer((_) async => LocationSuccess(testPosition));
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
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const DiscoveryStarted()),
        expect: () => [
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.loading),
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.success)
              .having(
                (s) => s.restaurants.first.placeId,
                'first restaurant (least visited)',
                'place_3',
              ),
        ],
      );
    });

    group('DiscoveryRefreshed', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits [loading, success] on refresh',
        setUp: () {
          when(() => mockLocationService.getCurrentLocation())
              .thenAnswer((_) async => LocationSuccess(testPosition));
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
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const DiscoveryRefreshed()),
        expect: () => [
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.loading),
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.success),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits [loading, failure] when location fails on refresh',
        setUp: () {
          when(() => mockLocationService.getCurrentLocation())
              .thenAnswer((_) async => const LocationServicesDisabled());
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const DiscoveryRefreshed()),
        expect: () => [
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.loading),
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.failure)
              .having(
                (s) => s.errorMessage,
                'error',
                contains('Unable to determine location'),
              ),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits [loading, failure] when places API fails on refresh',
        setUp: () {
          when(() => mockLocationService.getCurrentLocation())
              .thenAnswer((_) async => LocationSuccess(testPosition));
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
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const DiscoveryRefreshed()),
        expect: () => [
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.loading),
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.failure)
              .having((s) => s.errorMessage, 'error', 'Network error'),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits failure when no restaurants found on refresh with open only',
        setUp: () {
          when(() => mockLocationService.getCurrentLocation())
              .thenAnswer((_) async => LocationSuccess(testPosition));
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
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const DiscoveryRefreshed()),
        expect: () => [
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.loading),
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.failure)
              .having(
                (s) => s.errorMessage,
                'error',
                contains('No open restaurants'),
              ),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits failure when no restaurants found on refresh without open only',
        setUp: () {
          when(() => mockStorageService.getSettings()).thenReturn(
            const UserSettings(includeOpenOnly: false),
          );
          when(() => mockLocationService.getCurrentLocation())
              .thenAnswer((_) async => LocationSuccess(testPosition));
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
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const DiscoveryRefreshed()),
        expect: () => [
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.loading),
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.failure)
              .having(
                (s) => s.errorMessage,
                'error',
                contains('No restaurants found'),
              ),
        ],
      );
    });

    group('DiscoveryRestaurantSelected', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits selected state with restaurant',
        build: buildBloc,
        act: (bloc) => bloc.add(
          const DiscoveryRestaurantSelected(_restaurant1),
        ),
        expect: () => [
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.selected)
              .having(
                (s) => s.selectedRestaurant,
                'selected',
                _restaurant1,
              ),
        ],
        verify: (_) {
          verify(
            () => mockStorageService.incrementVisitCount('place_1'),
          ).called(1);
        },
      );
    });

    group('DiscoveryReset', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits initial state',
        build: buildBloc,
        seed: () => const DiscoveryState(
          status: DiscoveryStatus.success,
          restaurants: _testRestaurants,
        ),
        act: (bloc) => bloc.add(const DiscoveryReset()),
        expect: () => [const DiscoveryState()],
      );
    });

    group('DiscoverySpinStarted', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits spinning state',
        build: buildBloc,
        seed: () => const DiscoveryState(
          status: DiscoveryStatus.success,
          restaurants: _testRestaurants,
        ),
        act: (bloc) => bloc.add(const DiscoverySpinStarted()),
        expect: () => [
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.spinning)
              .having((s) => s.restaurants, 'restaurants', _testRestaurants),
        ],
      );
    });

    group('DiscoveryWinnerSelected', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits winner state with restaurant',
        build: buildBloc,
        seed: () => const DiscoveryState(
          status: DiscoveryStatus.spinning,
          restaurants: _testRestaurants,
        ),
        act: (bloc) => bloc.add(
          const DiscoveryWinnerSelected(_restaurant2),
        ),
        expect: () => [
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.winner)
              .having(
                (s) => s.selectedRestaurant,
                'selected',
                _restaurant2,
              ),
        ],
        verify: (_) {
          verify(
            () => mockStorageService.incrementVisitCount('place_2'),
          ).called(1);
        },
      );
    });

    group('DiscoveryCelebrationComplete', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits selected state from winner state',
        build: buildBloc,
        seed: () => const DiscoveryState(
          status: DiscoveryStatus.winner,
          restaurants: _testRestaurants,
          selectedRestaurant: _restaurant1,
        ),
        act: (bloc) => bloc.add(const DiscoveryCelebrationComplete()),
        expect: () => [
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.selected),
        ],
      );
    });

    group('DiscoveryRestaurantRemoved', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'removes restaurant from list',
        build: buildBloc,
        seed: () => const DiscoveryState(
          status: DiscoveryStatus.success,
          restaurants: _testRestaurants,
        ),
        act: (bloc) => bloc.add(const DiscoveryRestaurantRemoved('place_2')),
        expect: () => [
          isA<DiscoveryState>()
              .having((s) => s.status, 'status', DiscoveryStatus.success)
              .having((s) => s.restaurants.length, 'count', 2)
              .having(
                (s) => s.restaurants.any((r) => r.placeId == 'place_2'),
                'contains place_2',
                isFalse,
              )
              .having(
                (s) => s.selectedRestaurant,
                'cleared selection',
                isNull,
              ),
        ],
      );
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

  group('DiscoveryEvent', () {
    test('DiscoveryStarted props with mood', () {
      const event = DiscoveryStarted(mood: 'pizza');
      expect(event.props, ['pizza']);
    });

    test('DiscoveryStarted props without mood', () {
      const event = DiscoveryStarted();
      expect(event.props, [null]);
    });

    test('DiscoveryRefreshed props are empty', () {
      const event = DiscoveryRefreshed();
      expect(event.props, isEmpty);
    });

    test('DiscoveryRestaurantSelected props', () {
      const event = DiscoveryRestaurantSelected(_restaurant1);
      expect(event.props, [_restaurant1]);
    });

    test('DiscoveryReset props are empty', () {
      const event = DiscoveryReset();
      expect(event.props, isEmpty);
    });

    test('DiscoverySpinStarted props are empty', () {
      const event = DiscoverySpinStarted();
      expect(event.props, isEmpty);
    });

    test('DiscoveryWinnerSelected props', () {
      const event = DiscoveryWinnerSelected(_restaurant1);
      expect(event.props, [_restaurant1]);
    });

    test('DiscoveryCelebrationComplete props are empty', () {
      const event = DiscoveryCelebrationComplete();
      expect(event.props, isEmpty);
    });

    test('DiscoveryRestaurantRemoved props', () {
      const event = DiscoveryRestaurantRemoved('place_1');
      expect(event.props, ['place_1']);
    });
  });
}
