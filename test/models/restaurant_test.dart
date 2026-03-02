import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/models/models.dart';

void main() {
  group('Restaurant', () {
    const restaurant = Restaurant(
      placeId: 'place_1',
      name: 'Test Restaurant',
      address: '123 Main St',
      latitude: 34.0522,
      longitude: -118.2437,
      rating: 4.5,
      priceLevel: r'$$',
      types: ['restaurant', 'cafe'],
      photoReference: 'photo_ref_123',
      isOpen: true,
      totalRatings: 100,
    );

    test('supports value equality', () {
      const other = Restaurant(
        placeId: 'place_1',
        name: 'Test Restaurant',
        address: '123 Main St',
        latitude: 34.0522,
        longitude: -118.2437,
        rating: 4.5,
        priceLevel: r'$$',
        types: ['restaurant', 'cafe'],
        photoReference: 'photo_ref_123',
        isOpen: true,
        totalRatings: 100,
      );

      expect(restaurant, equals(other));
    });

    test('props are correct', () {
      expect(restaurant.props, [
        'place_1',
        'Test Restaurant',
        '123 Main St',
        34.0522,
        -118.2437,
        4.5,
        r'$$',
        ['restaurant', 'cafe'],
        'photo_ref_123',
        true,
        100,
      ]);
    });

    test('has correct default values for optional fields', () {
      const minimal = Restaurant(
        placeId: 'p1',
        name: 'Name',
        address: 'Addr',
        latitude: 0,
        longitude: 0,
      );

      expect(minimal.rating, isNull);
      expect(minimal.priceLevel, isNull);
      expect(minimal.types, isEmpty);
      expect(minimal.photoReference, isNull);
      expect(minimal.isOpen, isNull);
      expect(minimal.totalRatings, isNull);
    });

    group('fromPlacesApiNew', () {
      test('parses complete response correctly', () {
        final json = <String, dynamic>{
          'id': 'test_place_id',
          'displayName': {'text': 'Great Place'},
          'formattedAddress': '456 Oak Ave',
          'location': {'latitude': 34.05, 'longitude': -118.24},
          'rating': 4.2,
          'userRatingCount': 250,
          'priceLevel': 'PRICE_LEVEL_MODERATE',
          'photos': [
            {'name': 'places/abc/photos/xyz'},
          ],
          'primaryType': 'restaurant',
          'types': ['restaurant', 'food', 'establishment'],
          'currentOpeningHours': {'openNow': true},
        };

        final result = Restaurant.fromPlacesApiNew(json);

        expect(result.placeId, 'test_place_id');
        expect(result.name, 'Great Place');
        expect(result.address, '456 Oak Ave');
        expect(result.latitude, 34.05);
        expect(result.longitude, -118.24);
        expect(result.rating, 4.2);
        expect(result.totalRatings, 250);
        expect(result.priceLevel, r'$$');
        expect(result.photoReference, 'places/abc/photos/xyz');
        expect(result.types, contains('restaurant'));
        expect(result.isOpen, true);
      });

      test('handles missing optional fields', () {
        final json = <String, dynamic>{
          'id': 'place_2',
          'displayName': {'text': 'Simple Place'},
          'formattedAddress': '789 Pine Rd',
          'location': {'latitude': 34.1, 'longitude': -118.1},
        };

        final result = Restaurant.fromPlacesApiNew(json);

        expect(result.placeId, 'place_2');
        expect(result.name, 'Simple Place');
        expect(result.rating, isNull);
        expect(result.priceLevel, isNull);
        expect(result.photoReference, isNull);
        expect(result.isOpen, isNull);
        expect(result.totalRatings, isNull);
      });

      test('handles null id', () {
        final json = <String, dynamic>{
          'displayName': {'text': 'No ID'},
          'formattedAddress': 'Some St',
          'location': {'latitude': 0.0, 'longitude': 0.0},
        };

        final result = Restaurant.fromPlacesApiNew(json);
        expect(result.placeId, '');
      });

      test('handles null displayName', () {
        final json = <String, dynamic>{
          'id': 'p1',
          'formattedAddress': 'Some St',
          'location': {'latitude': 0.0, 'longitude': 0.0},
        };

        final result = Restaurant.fromPlacesApiNew(json);
        expect(result.name, 'Unknown');
      });

      test('handles null location', () {
        final json = <String, dynamic>{
          'id': 'p1',
          'displayName': {'text': 'Test'},
          'formattedAddress': 'Some St',
        };

        final result = Restaurant.fromPlacesApiNew(json);
        expect(result.latitude, 0);
        expect(result.longitude, 0);
      });

      test('parses all price levels correctly', () {
        final levels = {
          'PRICE_LEVEL_FREE': 'Free',
          'PRICE_LEVEL_INEXPENSIVE': r'$',
          'PRICE_LEVEL_MODERATE': r'$$',
          'PRICE_LEVEL_EXPENSIVE': r'$$$',
          'PRICE_LEVEL_VERY_EXPENSIVE': r'$$$$',
          'UNKNOWN_LEVEL': null,
        };

        for (final entry in levels.entries) {
          final json = <String, dynamic>{
            'id': 'p1',
            'displayName': {'text': 'Test'},
            'formattedAddress': 'Addr',
            'location': {'latitude': 0.0, 'longitude': 0.0},
            'priceLevel': entry.key,
          };

          final result = Restaurant.fromPlacesApiNew(json);
          expect(result.priceLevel, entry.value,
              reason: '${entry.key} should map to ${entry.value}');
        }
      });

      test('handles empty photos array', () {
        final json = <String, dynamic>{
          'id': 'p1',
          'displayName': {'text': 'Test'},
          'formattedAddress': 'Addr',
          'location': {'latitude': 0.0, 'longitude': 0.0},
          'photos': <dynamic>[],
        };

        final result = Restaurant.fromPlacesApiNew(json);
        expect(result.photoReference, isNull);
      });

      test('parses types with primaryType', () {
        final json = <String, dynamic>{
          'id': 'p1',
          'displayName': {'text': 'Test'},
          'formattedAddress': 'Addr',
          'location': {'latitude': 0.0, 'longitude': 0.0},
          'primaryType': 'mexican_restaurant',
          'types': ['mexican_restaurant', 'restaurant', 'food'],
        };

        final result = Restaurant.fromPlacesApiNew(json);
        expect(result.types, ['mexican_restaurant', 'restaurant', 'food']);
        // Primary type is first, no duplicates
        expect(result.types.where((t) => t == 'mexican_restaurant').length, 1);
      });

      test('parses types without primaryType', () {
        final json = <String, dynamic>{
          'id': 'p1',
          'displayName': {'text': 'Test'},
          'formattedAddress': 'Addr',
          'location': {'latitude': 0.0, 'longitude': 0.0},
          'types': ['restaurant', 'food'],
        };

        final result = Restaurant.fromPlacesApiNew(json);
        expect(result.types, ['restaurant', 'food']);
      });
    });

    test('two restaurants with different placeIds are not equal', () {
      const a = Restaurant(
        placeId: 'a',
        name: 'Same',
        address: 'Same',
        latitude: 0,
        longitude: 0,
      );
      const b = Restaurant(
        placeId: 'b',
        name: 'Same',
        address: 'Same',
        latitude: 0,
        longitude: 0,
      );

      expect(a, isNot(equals(b)));
    });
  });
}
