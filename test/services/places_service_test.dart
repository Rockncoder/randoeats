import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:randoeats/services/services.dart';

class MockDio extends Mock implements Dio {}

Response<Map<String, dynamic>> _ok(Map<String, dynamic> data) => Response(
  requestOptions: RequestOptions(path: '/nearby'),
  statusCode: 200,
  data: data,
);

void main() {
  group('PlacesService', () {
    late MockDio mockClient;
    late PlacesService service;

    setUp(() {
      mockClient = MockDio();
      service = PlacesService(client: mockClient);
    });

    tearDown(() {
      when(() => mockClient.close(force: any(named: 'force'))).thenReturn(null);
      service.dispose();
    });

    group('getNearbyRestaurants', () {
      test('parses restaurants from the BFF response', () async {
        when(
          () => mockClient.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => _ok({
            'restaurants': [
              {
                'id': 'abc',
                'name': 'Test Diner',
                'address': '1 Main St',
                'location': {'lat': 34.0, 'lng': -118.0},
                'rating': 4.5,
                'ratingCount': 12,
                'priceLevel': 2,
                'type': 'restaurant',
                'openNow': true,
                'photoRefs': ['places/abc/photos/xyz'],
              },
            ],
          }),
        );

        final result = await service.getNearbyRestaurants(
          latitude: 34,
          longitude: -118,
        );

        expect(result, isA<PlacesSuccess>());
        final restaurants = (result as PlacesSuccess).restaurants;
        expect(restaurants, hasLength(1));
        expect(restaurants.first.placeId, 'abc');
        expect(restaurants.first.name, 'Test Diner');
        expect(restaurants.first.priceLevel, r'$$');
        expect(restaurants.first.photoReference, 'places/abc/photos/xyz');
      });

      test('drops places in excludePlaceIds', () async {
        when(
          () => mockClient.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => _ok({
            'restaurants': [
              {
                'id': 'keep',
                'name': 'Keep',
                'address': '',
                'location': {'lat': 0, 'lng': 0},
                'photoRefs': <String>[],
              },
              {
                'id': 'drop',
                'name': 'Drop',
                'address': '',
                'location': {'lat': 0, 'lng': 0},
                'photoRefs': <String>[],
              },
            ],
          }),
        );

        final result = await service.getNearbyRestaurants(
          latitude: 34,
          longitude: -118,
          excludePlaceIds: {'drop'},
        );

        expect(result, isA<PlacesSuccess>());
        final restaurants = (result as PlacesSuccess).restaurants;
        expect(restaurants, hasLength(1));
        expect(restaurants.first.placeId, 'keep');
      });

      test('returns PlacesError when the request throws', () async {
        when(
          () => mockClient.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenThrow(
          DioException(requestOptions: RequestOptions(path: '/nearby')),
        );

        final result = await service.getNearbyRestaurants(
          latitude: 34,
          longitude: -118,
        );

        expect(result, isA<PlacesError>());
      });
    });

    group('getPhotoUrl', () {
      test('returns null when photoName is null', () {
        expect(service.getPhotoUrl(null), isNull);
      });

      test('builds a BFF photo URL from the photo name', () {
        final url = service.getPhotoUrl('places/abc/photos/xyz', maxWidth: 200);

        expect(url, isNotNull);
        expect(url, contains('/restaurants/abc/photo'));
        final parsed = Uri.parse(url!);
        expect(parsed.queryParameters['photo_ref'], 'places/abc/photos/xyz');
        expect(parsed.queryParameters['max_width'], '200');
      });
    });

    group('dispose', () {
      test('closes the Dio client', () {
        when(
          () => mockClient.close(force: any(named: 'force')),
        ).thenReturn(null);

        service.dispose();

        verify(() => mockClient.close()).called(1);
      });
    });
  });

  group('PlacesResult types', () {
    test('PlacesSuccess holds restaurants', () {
      const result = PlacesSuccess([]);
      expect(result.restaurants, isEmpty);
    });

    test('PlacesError holds message', () {
      const result = PlacesError('test error');
      expect(result.message, 'test error');
    });
  });
}
