import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/widgets/widgets.dart';

import '../helpers/helpers.dart';

const _testRestaurant = Restaurant(
  placeId: 'place_1',
  name: 'Test Restaurant',
  address: '123 Main St, Los Angeles, CA',
  latitude: 34.0522,
  longitude: -118.2437,
  rating: 4.5,
  priceLevel: r'$$',
  types: ['restaurant'],
  isOpen: true,
  totalRatings: 100,
);

const _closedRestaurant = Restaurant(
  placeId: 'place_2',
  name: 'Closed Place',
  address: '456 Oak Ave',
  latitude: 34.1,
  longitude: -118.1,
  isOpen: false,
);

const _minimalRestaurant = Restaurant(
  placeId: 'place_3',
  name: 'Minimal Place',
  address: '789 Pine Rd',
  latitude: 34.2,
  longitude: -118.2,
);

void main() {
  group('RestaurantCard', () {
    testWidgets('renders restaurant name', (tester) async {
      await tester.pumpApp(
        RestaurantCard(
          restaurant: _testRestaurant,
          onTap: () {},
        ),
      );

      expect(find.text('Test Restaurant'), findsOneWidget);
    });

    testWidgets('renders restaurant address', (tester) async {
      await tester.pumpApp(
        RestaurantCard(
          restaurant: _testRestaurant,
          onTap: () {},
        ),
      );

      expect(find.text('123 Main St, Los Angeles, CA'), findsOneWidget);
    });

    testWidgets('renders rating when available', (tester) async {
      await tester.pumpApp(
        RestaurantCard(
          restaurant: _testRestaurant,
          onTap: () {},
        ),
      );

      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('(100)'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('renders price level when available', (tester) async {
      await tester.pumpApp(
        RestaurantCard(
          restaurant: _testRestaurant,
          onTap: () {},
        ),
      );

      expect(find.text(r'$$'), findsOneWidget);
    });

    testWidgets('renders open status when open', (tester) async {
      await tester.pumpApp(
        RestaurantCard(
          restaurant: _testRestaurant,
          onTap: () {},
        ),
      );

      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('renders closed status when closed', (tester) async {
      await tester.pumpApp(
        RestaurantCard(
          restaurant: _closedRestaurant,
          onTap: () {},
        ),
      );

      expect(find.text('Closed'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpApp(
        RestaurantCard(
          restaurant: _testRestaurant,
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('renders placeholder when no photo', (tester) async {
      await tester.pumpApp(
        RestaurantCard(
          restaurant: _minimalRestaurant,
          onTap: () {},
        ),
      );

      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });

    testWidgets('does not render rating when null', (tester) async {
      await tester.pumpApp(
        RestaurantCard(
          restaurant: _minimalRestaurant,
          onTap: () {},
        ),
      );

      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('does not render price level when null', (tester) async {
      await tester.pumpApp(
        RestaurantCard(
          restaurant: _minimalRestaurant,
          onTap: () {},
        ),
      );

      // The price level text would be in a specific style; verify no
      // price-like text appears
      expect(find.text(r'$'), findsNothing);
      expect(find.text(r'$$'), findsNothing);
    });

    testWidgets('does not render open status when null', (tester) async {
      await tester.pumpApp(
        RestaurantCard(
          restaurant: _minimalRestaurant,
          onTap: () {},
        ),
      );

      expect(find.text('Open'), findsNothing);
      expect(find.text('Closed'), findsNothing);
    });

    testWidgets('renders as a Card widget', (tester) async {
      await tester.pumpApp(
        RestaurantCard(
          restaurant: _testRestaurant,
          onTap: () {},
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('accepts index parameter', (tester) async {
      await tester.pumpApp(
        RestaurantCard(
          restaurant: _testRestaurant,
          onTap: () {},
          index: 3,
        ),
      );

      expect(find.byType(RestaurantCard), findsOneWidget);
    });

    testWidgets('renders rating without totalRatings', (tester) async {
      const restaurantNoCount = Restaurant(
        placeId: 'p1',
        name: 'Test',
        address: 'Addr',
        latitude: 0,
        longitude: 0,
        rating: 3.8,
      );

      await tester.pumpApp(
        RestaurantCard(
          restaurant: restaurantNoCount,
          onTap: () {},
        ),
      );

      expect(find.text('3.8'), findsOneWidget);
    });
  });
}
