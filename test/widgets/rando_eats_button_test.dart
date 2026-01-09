// Ignore for testing purposes
// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/widgets/widgets.dart';

import '../helpers/helpers.dart';

void main() {
  group('RandoEatsButton', () {
    testWidgets('renders button with logo image when not spinning', (
      tester,
    ) async {
      await tester.pumpApp(
        RandoEatsButton(onPressed: () {}),
      );

      // Now uses logo image instead of text
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('RAND-O-EATS!'), findsNothing);
    });

    testWidgets('renders spinning state with rotating circular button', (
      tester,
    ) async {
      await tester.pumpApp(
        RandoEatsButton(onPressed: () {}, isSpinning: true),
      );

      // Spinning state shows a circular rotating button with image
      expect(find.byType(RotationTransition), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      // No longer shows text or progress indicator
      expect(find.text('SPINNING...'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('calls onPressed when tapped and not spinning', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpApp(
        RandoEatsButton(onPressed: () => tapped = true),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('spinning button is not tappable', (
      tester,
    ) async {
      await tester.pumpApp(
        RandoEatsButton(onPressed: () {}, isSpinning: true),
      );

      // Spinning state has no InkWell - button is not tappable
      expect(find.byType(InkWell), findsNothing);
      expect(find.byType(RotationTransition), findsOneWidget);
    });

    testWidgets('does not call onPressed when onPressed is null', (
      tester,
    ) async {
      await tester.pumpApp(
        RandoEatsButton(onPressed: null),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      // No error should occur
    });

    testWidgets('has pulse animation when not spinning', (tester) async {
      await tester.pumpApp(
        RandoEatsButton(onPressed: () {}),
      );

      // Verify AnimatedBuilder exists for the pulse animation
      expect(find.byType(AnimatedBuilder), findsWidgets);
    });

    testWidgets('renders starburst decorations when not spinning', (
      tester,
    ) async {
      await tester.pumpApp(
        RandoEatsButton(onPressed: () {}),
      );

      // CustomPaint widgets are used for starburst decorations
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('changes appearance when spinning', (tester) async {
      await tester.pumpApp(
        RandoEatsButton(onPressed: () {}, isSpinning: true),
      );

      // When spinning, shows circular rotating button with logo
      expect(find.byType(RotationTransition), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      // No starburst decorations when spinning (different layout)
      expect(find.byType(InkWell), findsNothing);
    });
  });
}
