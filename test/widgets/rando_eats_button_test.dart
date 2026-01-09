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

    testWidgets('renders spinning state with progress indicator', (
      tester,
    ) async {
      await tester.pumpApp(
        RandoEatsButton(onPressed: () {}, isSpinning: true),
      );

      expect(find.text('SPINNING...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Image), findsNothing);
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

    testWidgets('does not call onPressed when tapped while spinning', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpApp(
        RandoEatsButton(onPressed: () => tapped = true, isSpinning: true),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(tapped, isFalse);
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

      // When spinning, shows different text and no logo
      expect(find.text('SPINNING...'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });
  });
}
