import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:randoeats/widgets/restaurant_map_sheet.dart';

void main() {
  group('RestaurantMapSheet', () {
    const coordinates = LatLng(37.7749, -122.4194);
    const name = 'Zuni Café';

    Widget host() => MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => RestaurantMapSheet.show(
              context,
              coordinates: coordinates,
              name: name,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    testWidgets('shows the restaurant name as the title and a close button', (
      tester,
    ) async {
      await tester.pumpWidget(host());
      await tester.tap(find.text('open'));
      await tester.pump(); // start the sheet route
      await tester.pump(const Duration(milliseconds: 350)); // finish animation

      expect(find.text(name), findsOneWidget);
      expect(
        find.byKey(const ValueKey('restaurant_map_close')),
        findsOneWidget,
      );
    });

    testWidgets('the close button dismisses the sheet', (tester) async {
      await tester.pumpWidget(host());
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text(name), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('restaurant_map_close')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text(name), findsNothing);
    });
  });
}
