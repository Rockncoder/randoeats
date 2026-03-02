import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/screens/screens.dart';

void main() {
  group('DetailScreen', () {
    // DetailScreen uses StorageService.instance and PlacesService.instance
    // directly (singletons). Since Hive is not initialized in widget tests,
    // we test the widget construction and model data used by it.

    test('can be constructed with restaurant', () {
      const restaurant = Restaurant(
        placeId: 'place_1',
        name: 'Test Restaurant',
        address: '123 Main St',
        latitude: 34.0522,
        longitude: -118.2437,
      );

      const screen = DetailScreen(restaurant: restaurant);
      expect(screen.restaurant, restaurant);
    });

    test('restaurant property is accessible', () {
      const restaurant = Restaurant(
        placeId: 'place_2',
        name: 'Another Place',
        address: '456 Oak Ave',
        latitude: 34.1,
        longitude: -118.1,
        rating: 4.5,
        priceLevel: r'$$',
        isOpen: true,
        totalRatings: 100,
        types: ['restaurant', 'mexican_restaurant'],
      );

      const screen = DetailScreen(restaurant: restaurant);
      expect(screen.restaurant.name, 'Another Place');
      expect(screen.restaurant.placeId, 'place_2');
      expect(screen.restaurant.rating, 4.5);
      expect(screen.restaurant.priceLevel, r'$$');
      expect(screen.restaurant.isOpen, isTrue);
      expect(screen.restaurant.totalRatings, 100);
      expect(screen.restaurant.types, hasLength(2));
    });
  });
}
