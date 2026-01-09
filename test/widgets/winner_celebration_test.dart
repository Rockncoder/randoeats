// Ignore for testing purposes
// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/widgets/widgets.dart';

import '../helpers/helpers.dart';

void main() {
  group('WinnerCelebration', () {
    testWidgets('renders winner text', (tester) async {
      await tester.pumpApp(
        WinnerCelebration(onComplete: () {}),
      );

      expect(find.text('WINNER!'), findsOneWidget);
    });

    testWidgets('renders starburst decoration', (tester) async {
      await tester.pumpApp(
        WinnerCelebration(onComplete: () {}),
      );

      // CustomPaint widgets are used for starburst and particles
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('calls onComplete when animation finishes', (tester) async {
      var completed = false;
      await tester.pumpApp(
        WinnerCelebration(onComplete: () => completed = true),
      );

      // Animation duration is 1500ms
      // Don't use pumpAndSettle as starburst has repeating animation
      await tester.pump(Duration(milliseconds: 1600));

      expect(completed, isTrue);
    });

    testWidgets('is wrapped in IgnorePointer', (tester) async {
      await tester.pumpApp(
        WinnerCelebration(onComplete: () {}),
      );

      // Find IgnorePointer that is set to ignore (ignoring: true)
      final ignorePointerFinder = find.byWidgetPredicate(
        (widget) => widget is IgnorePointer && widget.ignoring,
      );
      expect(ignorePointerFinder, findsOneWidget);
    });

    testWidgets('renders AnimatedBuilder for animations', (tester) async {
      await tester.pumpApp(
        WinnerCelebration(onComplete: () {}),
      );

      // Multiple AnimatedBuilders may exist for various animations
      expect(find.byType(AnimatedBuilder), findsWidgets);
    });

    testWidgets('renders multiple particles', (tester) async {
      await tester.pumpApp(
        WinnerCelebration(onComplete: () {}),
      );

      // Particles are positioned widgets with transforms
      final positionedWidgets = find.byType(Positioned);
      expect(positionedWidgets, findsWidgets);
    });

    testWidgets('uses Stack for layered effects', (tester) async {
      await tester.pumpApp(
        WinnerCelebration(onComplete: () {}),
      );

      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('renders background gradient flash', (tester) async {
      await tester.pumpApp(
        WinnerCelebration(onComplete: () {}),
      );

      // Look for container with RadialGradient
      final gradientFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).gradient is RadialGradient,
      );
      expect(gradientFinder, findsOneWidget);
    });

    testWidgets('winner text has correct styling', (tester) async {
      await tester.pumpApp(
        WinnerCelebration(onComplete: () {}),
      );

      final textWidget = tester.widget<Text>(find.text('WINNER!'));
      expect(textWidget.style?.fontSize, equals(32));
      expect(textWidget.style?.fontWeight, equals(FontWeight.bold));
      expect(textWidget.style?.letterSpacing, equals(4));
    });

    testWidgets('disposes animation controllers properly', (tester) async {
      var completed = false;
      await tester.pumpApp(
        WinnerCelebration(onComplete: () => completed = true),
      );

      // Advance animation past completion (1500ms + buffer)
      // Don't use pumpAndSettle as the starburst has a repeating animation
      await tester.pump(Duration(milliseconds: 1600));

      // Pumping app with different widget to trigger dispose
      await tester.pumpApp(Container());
      await tester.pump();

      // No error should occur during dispose
      expect(completed, isTrue);
    });

    testWidgets('animation starts immediately on build', (tester) async {
      await tester.pumpApp(
        WinnerCelebration(onComplete: () {}),
      );

      // Pump a small amount to let animation start
      await tester.pump(Duration(milliseconds: 100));

      // Widget should be animating - find Transform.scale
      expect(find.byType(Transform), findsWidgets);
    });
  });
}
