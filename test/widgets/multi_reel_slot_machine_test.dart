import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/widgets/multi_reel_slot_machine.dart';

void main() {
  List<Restaurant> makeRestaurants(int n) => List.generate(
    n,
    (i) => Restaurant(
      placeId: 'p$i',
      name: 'R$i',
      address: 'addr $i',
      latitude: 0,
      longitude: 0,
      isOpen: true,
    ),
  );

  Future<void> pumpMachine(
    WidgetTester tester, {
    required Size size,
    required GlobalKey<MultiReelSlotMachineState> machineKey,
    required List<Restaurant> restaurants,
    void Function(Restaurant)? onWin,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiReelSlotMachine(
            key: machineKey,
            restaurants: restaurants,
            onRestaurantTap: (_) {},
            onSpinComplete: onWin ?? (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows 1 reel on a phone-width surface', (tester) async {
    await pumpMachine(
      tester,
      size: const Size(390, 844),
      machineKey: GlobalKey<MultiReelSlotMachineState>(),
      restaurants: makeRestaurants(10),
    );
    expect(find.byType(ListView), findsOneWidget); // one reel = one ListView
  });

  testWidgets('shows 3 reels on a wide (landscape iPad) surface', (
    tester,
  ) async {
    await pumpMachine(
      tester,
      size: const Size(1366, 1024),
      machineKey: GlobalKey<MultiReelSlotMachineState>(),
      restaurants: makeRestaurants(20),
    );
    expect(find.byType(ListView), findsNWidgets(3));
  });

  testWidgets('shows 2 reels on iPad portrait', (tester) async {
    await pumpMachine(
      tester,
      size: const Size(834, 1112),
      machineKey: GlobalKey<MultiReelSlotMachineState>(),
      restaurants: makeRestaurants(20),
    );
    expect(find.byType(ListView), findsNWidgets(2));
  });

  testWidgets('spin reports a winner drawn from the list', (tester) async {
    final machineKey = GlobalKey<MultiReelSlotMachineState>();
    final restaurants = makeRestaurants(20);
    Restaurant? winner;

    await pumpMachine(
      tester,
      size: const Size(1100, 900),
      machineKey: machineKey,
      restaurants: restaurants,
      onWin: (r) => winner = r,
    );

    machineKey.currentState!.spin();
    expect(machineKey.currentState!.isSpinning, isTrue);

    await tester.pumpAndSettle(const Duration(seconds: 12));

    expect(winner, isNotNull);
    expect(
      restaurants.map((r) => r.placeId),
      contains(winner!.placeId),
    );
    expect(machineKey.currentState!.isSpinning, isFalse);
  });

  testWidgets('does nothing on spin with no restaurants', (tester) async {
    final machineKey = GlobalKey<MultiReelSlotMachineState>();
    await pumpMachine(
      tester,
      size: const Size(800, 800),
      machineKey: machineKey,
      restaurants: const [],
    );
    machineKey.currentState!.spin();
    expect(machineKey.currentState!.isSpinning, isFalse);
  });
}
