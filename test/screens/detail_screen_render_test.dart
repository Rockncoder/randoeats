import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/screens/screens.dart';
import 'package:randoeats/services/services.dart';

/// Actually renders DetailScreen (unlike detail_screen_test.dart, which only
/// constructs it) to catch layout/semantics regressions — e.g. the
/// "BoxConstraints forces an infinite width" + parentDataDirty flood seen on
/// the iPad simulator under marionette.
void main() {
  late Directory tempDir;

  const restaurant = Restaurant(
    placeId: 'p1',
    name: 'Test Diner',
    address: '123 Main St, San Francisco, CA 94105, USA',
    latitude: 34,
    longitude: -118,
    rating: 4.5,
    priceLevel: r'$$',
    isOpen: true,
    totalRatings: 100,
    types: ['restaurant', 'mexican_restaurant'],
  );

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('detail_render');
    await StorageService.instance.initializeForTest(tempDir.path);
  });

  tearDownAll(() async {
    await StorageService.instance.close();
    await tempDir.delete(recursive: true);
  });

  Future<void> pumpDetail(WidgetTester tester, Size logicalSize) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = logicalSize;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: DetailScreen(restaurant: restaurant)),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders content on a phone-sized screen', (tester) async {
    await pumpDetail(tester, const Size(390, 844));
    expect(tester.takeException(), isNull);
    expect(find.text('Test Diner'), findsOneWidget);
    expect(find.text('NAVIGATE'), findsOneWidget);
    expect(find.text('Good Pick!'), findsOneWidget);
    expect(find.text('Not For Me'), findsOneWidget);
  });

  testWidgets('renders on a tablet with semantics forced on', (tester) async {
    // ensureSemantics() forces the semantics tree every frame — the same thing
    // accessibility services / marionette do, and the suspected trigger.
    final handle = tester.ensureSemantics();
    await pumpDetail(tester, const Size(1024, 1366));
    expect(tester.takeException(), isNull);
    expect(find.text('NAVIGATE'), findsOneWidget);
    expect(find.text('Good Pick!'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('shows a tappable phone row when a number is present', (
    tester,
  ) async {
    const withPhone = Restaurant(
      placeId: 'p9',
      name: 'Phone Diner',
      address: '1 Call St',
      latitude: 34,
      longitude: -118,
      isOpen: true,
      phoneNumber: '(415) 555-0123',
    );
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: DetailScreen(restaurant: withPhone)),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('detail_call')), findsOneWidget);
    expect(find.text('(415) 555-0123'), findsOneWidget);
  });

  testWidgets('hides the phone row when no number is present', (tester) async {
    // The module-level `restaurant` has no phoneNumber.
    await pumpDetail(tester, const Size(390, 844));
    expect(find.byKey(const ValueKey('detail_call')), findsNothing);
  });

  testWidgets('both action buttons are flexible (no unbounded-width row)', (
    tester,
  ) async {
    // The "Abort Mission" button must be Expanded like NAVIGATE. An inflexible
    // child in the actions Row is measured by RenderFlex with an unbounded
    // main-axis width, which on the iPad accessibility layout pass triggers
    // "BoxConstraints forces an infinite width". Keep it flexible.
    await pumpDetail(tester, const Size(390, 844));
    final abort = find.byKey(const ValueKey('detail_abort'));
    expect(abort, findsOneWidget);
    expect(
      find.ancestor(of: abort, matching: find.byType(Expanded)),
      findsOneWidget,
    );
  });

  testWidgets('renders wide + scrollable with semantics (no infinite width)', (
    tester,
  ) async {
    // The exact condition marionette hit on the iPad: wide AND short enough to
    // scroll AND semantics on — the suspected trigger for the
    // "BoxConstraints forces an infinite width" cascade.
    final handle = tester.ensureSemantics();
    await pumpDetail(tester, const Size(900, 480));
    expect(tester.takeException(), isNull);
    expect(find.text('NAVIGATE'), findsOneWidget);
    handle.dispose();
  });
}
