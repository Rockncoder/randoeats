// Ignore for testing purposes
// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/widgets/widgets.dart';

import '../helpers/helpers.dart';

void main() {
  group('RandoEatsButton', () {
    testWidgets('renders the round badge logo when not spinning', (
      tester,
    ) async {
      await tester.pumpApp(
        RandoEatsButton(onPressed: () {}),
      );

      // Idle state is the round badge logo (clipped to a circle), not text.
      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as AssetImage).assetName,
        'assets/images/rand-o-eats-badge.png',
      );
      // Logo is the single oval; the frosted blur sits in a scalloped ClipPath.
      expect(find.byType(ClipOval), findsOneWidget);
      expect(find.byType(ClipPath), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.text('RAND-O-EATS!'), findsNothing);
    });

    testWidgets('renders spinning state with rotating circular button', (
      tester,
    ) async {
      await tester.pumpApp(
        RandoEatsButton(onPressed: () {}, isSpinning: true),
      );

      // Two rotations now: the always-on scallop and the spinning logo.
      expect(find.byType(RotationTransition), findsNWidgets(2));
      expect(find.byType(Image), findsOneWidget);
      // No longer shows text or progress indicator
      expect(find.text('SPINNING...'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('spins the round badge logo (clipped to a circle)', (
      tester,
    ) async {
      await tester.pumpApp(
        RandoEatsButton(onPressed: () {}, isSpinning: true),
      );

      // The spinning image is the new round badge, clipped to a circle.
      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as AssetImage;
      expect(provider.assetName, 'assets/images/rand-o-eats-badge.png');
      expect(
        find.descendant(
          of: find.byType(RotationTransition),
          matching: find.byType(ClipOval),
        ),
        findsOneWidget,
      );
    });

    testWidgets('calls onPressed when tapped and not spinning', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpApp(
        RandoEatsButton(onPressed: () => tapped = true),
      );

      await tester.tap(find.byType(RandoEatsButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('spinning button is not tappable', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpApp(
        RandoEatsButton(onPressed: () => tapped = true, isSpinning: true),
      );

      // Spinning state has no gesture handler - tapping does nothing.
      await tester.tap(find.byType(RandoEatsButton), warnIfMissed: false);
      await tester.pump();
      expect(tapped, isFalse);
      expect(find.byType(GestureDetector), findsNothing);
      expect(find.byType(RotationTransition), findsNWidgets(2));
    });

    testWidgets('does not call onPressed when onPressed is null', (
      tester,
    ) async {
      await tester.pumpApp(
        RandoEatsButton(onPressed: null),
      );

      await tester.tap(find.byType(RandoEatsButton));
      await tester.pump();

      // No error should occur
    });

    testWidgets('pulses (scale animation) when not spinning', (tester) async {
      await tester.pumpApp(
        RandoEatsButton(onPressed: () {}),
      );

      // The idle badge gently pulses via a ScaleTransition.
      expect(find.byType(ScaleTransition), findsOneWidget);
    });

    testWidgets('changes appearance when spinning', (tester) async {
      await tester.pumpApp(
        RandoEatsButton(onPressed: () {}, isSpinning: true),
      );

      // When spinning, shows the rotating badge and is no longer tappable.
      expect(find.byType(RotationTransition), findsNWidgets(2));
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(GestureDetector), findsNothing);
    });
  });
}
