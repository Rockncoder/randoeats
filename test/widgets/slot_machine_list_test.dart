// Ignore for testing purposes
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/widgets/widgets.dart';

import '../helpers/helpers.dart';

void main() {
  group('SlotMachineList', () {
    late List<Restaurant> testRestaurants;

    setUp(() {
      testRestaurants = [
        Restaurant(
          placeId: 'place_1',
          name: 'Restaurant One',
          address: '123 Main St',
          latitude: 34,
          longitude: -118,
          rating: 4.5,
          priceLevel: r'$$',
          isOpen: true,
        ),
        Restaurant(
          placeId: 'place_2',
          name: 'Restaurant Two',
          address: '456 Oak Ave',
          latitude: 34.1,
          longitude: -118.1,
          rating: 4,
          priceLevel: r'$',
          isOpen: true,
        ),
        Restaurant(
          placeId: 'place_3',
          name: 'Restaurant Three',
          address: '789 Pine Rd',
          latitude: 34.2,
          longitude: -118.2,
          rating: 4.8,
          priceLevel: r'$$$',
          isOpen: false,
        ),
      ];
    });

    testWidgets('renders ListView with restaurant cards', (tester) async {
      await tester.pumpApp(
        SlotMachineList(
          restaurants: testRestaurants,
          onRestaurantTap: (_) {},
          onSpinComplete: (_) {},
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(RestaurantCard), findsNWidgets(3));
    });

    testWidgets('displays restaurant names', (tester) async {
      await tester.pumpApp(
        SlotMachineList(
          restaurants: testRestaurants,
          onRestaurantTap: (_) {},
          onSpinComplete: (_) {},
        ),
      );

      expect(find.text('Restaurant One'), findsOneWidget);
      expect(find.text('Restaurant Two'), findsOneWidget);
      expect(find.text('Restaurant Three'), findsOneWidget);
    });

    testWidgets('calls onRestaurantTap when card is tapped', (tester) async {
      Restaurant? tappedRestaurant;
      await tester.pumpApp(
        SlotMachineList(
          restaurants: testRestaurants,
          onRestaurantTap: (r) => tappedRestaurant = r,
          onSpinComplete: (_) {},
        ),
      );

      await tester.tap(find.text('Restaurant One'));
      await tester.pump();

      expect(tappedRestaurant?.placeId, equals('place_1'));
    });

    testWidgets('renders with empty list', (tester) async {
      await tester.pumpApp(
        SlotMachineList(
          restaurants: [],
          onRestaurantTap: (_) {},
          onSpinComplete: (_) {},
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(RestaurantCard), findsNothing);
    });

    testWidgets('exposes isSpinning property via state', (tester) async {
      final key = GlobalKey<SlotMachineListState>();
      await tester.pumpApp(
        SlotMachineList(
          key: key,
          restaurants: testRestaurants,
          onRestaurantTap: (_) {},
          onSpinComplete: (_) {},
        ),
      );

      expect(key.currentState?.isSpinning, isFalse);
    });

    testWidgets('spin method triggers spinning state', (tester) async {
      final key = GlobalKey<SlotMachineListState>();
      await tester.pumpApp(
        SlotMachineList(
          key: key,
          restaurants: testRestaurants,
          onRestaurantTap: (_) {},
          onSpinComplete: (_) {},
        ),
      );

      key.currentState?.spin();
      await tester.pump();

      expect(key.currentState?.isSpinning, isTrue);
    });

    testWidgets('spin does nothing with empty list', (tester) async {
      final key = GlobalKey<SlotMachineListState>();
      await tester.pumpApp(
        SlotMachineList(
          key: key,
          restaurants: [],
          onRestaurantTap: (_) {},
          onSpinComplete: (_) {},
        ),
      );

      key.currentState?.spin();
      await tester.pump();

      // Should not throw and should not be spinning
      expect(key.currentState?.isSpinning, isFalse);
    });

    testWidgets('disables tap during spin', (tester) async {
      final key = GlobalKey<SlotMachineListState>();
      Restaurant? tappedRestaurant;
      await tester.pumpApp(
        SlotMachineList(
          key: key,
          restaurants: testRestaurants,
          onRestaurantTap: (r) => tappedRestaurant = r,
          onSpinComplete: (_) {},
        ),
      );

      key.currentState?.spin();
      await tester.pump();

      await tester.tap(find.text('Restaurant One'));
      await tester.pump();

      // Should not have been tapped during spin
      expect(tappedRestaurant, isNull);
    });

    testWidgets('calls onSpinComplete when animation finishes', (
      tester,
    ) async {
      final key = GlobalKey<SlotMachineListState>();
      Restaurant? winner;
      await tester.pumpApp(
        SlotMachineList(
          key: key,
          restaurants: testRestaurants,
          onRestaurantTap: (_) {},
          onSpinComplete: (r) => winner = r,
        ),
      );

      key.currentState?.spin();
      // Fast-forward animation to completion (4 seconds + buffer)
      await tester.pumpAndSettle(Duration(seconds: 5));

      expect(winner, isNotNull);
      expect(testRestaurants.contains(winner), isTrue);
    });

    testWidgets('cannot spin while already spinning', (tester) async {
      final key = GlobalKey<SlotMachineListState>();
      var spinCompleteCount = 0;
      await tester.pumpApp(
        SlotMachineList(
          key: key,
          restaurants: testRestaurants,
          onRestaurantTap: (_) {},
          onSpinComplete: (_) => spinCompleteCount++,
        ),
      );

      key.currentState?.spin();
      await tester.pump();

      // Try to spin again while already spinning
      key.currentState?.spin();
      await tester.pump();

      // Wait for animation to complete
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Should only have completed once
      expect(spinCompleteCount, equals(1));
    });

    testWidgets('renders gradient overlay at bottom', (tester) async {
      await tester.pumpApp(
        SlotMachineList(
          restaurants: testRestaurants,
          onRestaurantTap: (_) {},
          onSpinComplete: (_) {},
        ),
      );

      // Check for gradient container at bottom
      final gradientFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).gradient is LinearGradient,
      );
      expect(gradientFinder, findsOneWidget);
    });

    testWidgets('uses NeverScrollableScrollPhysics during spin', (
      tester,
    ) async {
      final key = GlobalKey<SlotMachineListState>();
      await tester.pumpApp(
        SlotMachineList(
          key: key,
          restaurants: testRestaurants,
          onRestaurantTap: (_) {},
          onSpinComplete: (_) {},
        ),
      );

      key.currentState?.spin();
      await tester.pump();

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.physics, isA<NeverScrollableScrollPhysics>());
    });
  });
}
