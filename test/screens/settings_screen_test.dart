import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/screens/settings/settings_screen.dart';

void main() {
  group('SettingsScreen', () {
    // Note: SettingsScreen uses StorageService.instance directly, so
    // full integration testing requires Hive initialization. These tests
    // verify the widget structure exists. The StorageService singleton
    // will throw in test if not initialized, so we only test what we can
    // without the service.

    testWidgets('constructs without error', (tester) async {
      // Verify the widget can be instantiated
      const widget = SettingsScreen();
      expect(widget, isA<SettingsScreen>());
    });
  });

  group('restaurantCategories', () {
    test('contains expected category entries', () {
      expect(restaurantCategories, isNotEmpty);
      expect(restaurantCategories.length, 26);
    });

    test('contains mexican_restaurant', () {
      expect(restaurantCategories['mexican_restaurant'], 'Mexican');
    });

    test('contains fast_food_restaurant', () {
      expect(restaurantCategories['fast_food_restaurant'], 'Fast Food');
    });

    test('contains bakery', () {
      expect(restaurantCategories['bakery'], 'Bakery');
    });

    test('contains all expected keys', () {
      final expectedKeys = [
        'mexican_restaurant',
        'chinese_restaurant',
        'italian_restaurant',
        'japanese_restaurant',
        'thai_restaurant',
        'indian_restaurant',
        'vietnamese_restaurant',
        'korean_restaurant',
        'american_restaurant',
        'pizza_restaurant',
        'burger_restaurant',
        'seafood_restaurant',
        'steak_house',
        'sushi_restaurant',
        'mediterranean_restaurant',
        'greek_restaurant',
        'french_restaurant',
        'barbecue_restaurant',
        'cafe',
        'fast_food_restaurant',
        'fine_dining_restaurant',
        'breakfast_restaurant',
        'brunch_restaurant',
        'sandwich_shop',
        'ice_cream_shop',
        'bakery',
      ];

      for (final key in expectedKeys) {
        expect(restaurantCategories.containsKey(key), isTrue,
            reason: 'Missing key: $key');
      }
    });
  });
}
