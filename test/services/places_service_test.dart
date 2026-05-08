import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:randoeats/services/services.dart';

class MockDio extends Mock implements Dio {}

void main() {
  group('PlacesService', () {
    late MockDio mockClient;
    late PlacesService service;

    setUp(() {
      mockClient = MockDio();
      service = PlacesService(client: mockClient);
    });

    tearDown(() {
      when(() => mockClient.close(force: any(named: 'force')))
          .thenReturn(null);
      service.dispose();
    });

    group('getNearbyRestaurants', () {
      test('returns PlacesError when API key is empty', () async {
        // API key is empty by default in tests (no --dart-define)
        final result = await service.getNearbyRestaurants(
          latitude: 34,
          longitude: -118,
        );

        expect(result, isA<PlacesError>());
        expect(
          (result as PlacesError).message,
          contains('API key not configured'),
        );
      });
    });

    group('getPhotoUrl', () {
      test('returns null when photoName is null', () {
        final url = service.getPhotoUrl(null);
        expect(url, isNull);
      });

      test('returns null when API key is empty', () {
        // API key is empty in test environment
        final url = service.getPhotoUrl('places/abc/photos/xyz');
        expect(url, isNull);
      });
    });

    group('dispose', () {
      test('closes the Dio client', () {
        when(() => mockClient.close(force: any(named: 'force')))
            .thenReturn(null);

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
