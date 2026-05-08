import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:randoeats/blocs/blocs.dart';
import 'package:randoeats/config/config.dart';
import 'package:randoeats/screens/screens.dart';

import 'helpers/mock_providers.dart';

late Directory _screenshotDir;

void main() {
  setUpAll(() {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    _screenshotDir = Directory('/tmp/flutter_screenshots')
      ..createSync(recursive: true);
  });

  // ==================== Warm-up ====================
  testWidgets('warm_up', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GoogieTheme.light,
        home: const Scaffold(
          body: Center(child: Text('Loading fonts...')),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
  });

  // ==================== 1. Home Screen ====================
  testWidgets('home_light', (tester) async {
    await _pumpScreenshot(
      tester,
      theme: GoogieTheme.light,
      discoveryState: homeState(),
      child: const HomeScreen(),
    );
    await _saveScreenshot(tester, 'home_light');
  });

  testWidgets('home_dark', (tester) async {
    await _pumpScreenshot(
      tester,
      theme: GoogieTheme.dark,
      discoveryState: homeState(),
      child: const HomeScreen(),
    );
    await _saveScreenshot(tester, 'home_dark');
  });

  // ==================== 2. Results Screen ====================
  testWidgets('results_light', (tester) async {
    await _pumpScreenshot(
      tester,
      theme: GoogieTheme.light,
      discoveryState: resultsState(),
      child: const ResultsScreen(),
    );
    await _saveScreenshot(tester, 'results_light');
  });

  testWidgets('results_dark', (tester) async {
    await _pumpScreenshot(
      tester,
      theme: GoogieTheme.dark,
      discoveryState: resultsState(),
      child: const ResultsScreen(),
    );
    await _saveScreenshot(tester, 'results_dark');
  });

  // ==================== 3. Detail Screen ====================
  testWidgets('detail_light', (tester) async {
    await _pumpScreenshot(
      tester,
      theme: GoogieTheme.light,
      discoveryState: detailState(),
      child: DetailScreen(restaurant: sampleRestaurants[2]),
    );
    await _saveScreenshot(tester, 'detail_light');
  });

  testWidgets('detail_dark', (tester) async {
    await _pumpScreenshot(
      tester,
      theme: GoogieTheme.dark,
      discoveryState: detailState(),
      child: DetailScreen(restaurant: sampleRestaurants[2]),
    );
    await _saveScreenshot(tester, 'detail_dark');
  });

  // ==================== 4. Settings Screen ====================
  testWidgets('settings_light', (tester) async {
    await _pumpScreenshot(
      tester,
      theme: GoogieTheme.light,
      child: const SettingsScreen(),
    );
    await _saveScreenshot(tester, 'settings_light');
  });

  testWidgets('settings_dark', (tester) async {
    await _pumpScreenshot(
      tester,
      theme: GoogieTheme.dark,
      child: const SettingsScreen(),
    );
    await _saveScreenshot(tester, 'settings_dark');
  });
}

// ==================== Screenshot Capture ====================

Future<void> _saveScreenshot(
  WidgetTester tester,
  String name,
) async {
  await tester.pump();

  final renderObject =
      tester.binding.rootElement!.renderObject!;
  final layer = renderObject.debugLayer! as OffsetLayer;
  final image = await layer.toImage(renderObject.paintBounds);
  final byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);

  File('${_screenshotDir.path}/$name.png')
      .writeAsBytesSync(byteData!.buffer.asUint8List());
}

// ==================== Pump Helper ====================

Future<void> _pumpScreenshot(
  WidgetTester tester, {
  required ThemeData theme,
  required Widget child,
  DiscoveryState? discoveryState,
}) async {
  Widget app = MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    home: child,
  );

  app = ProviderScope(
    overrides: [
      if (discoveryState != null)
        discoveryProvider.overrideWith(
          () => MockDiscoveryNotifier(discoveryState),
        ),
    ],
    child: app,
  );

  // Suppress RenderFlex overflow errors.
  final origOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.toString().contains('overflowed')) return;
    origOnError?.call(details);
  };

  await tester.pumpWidget(app);
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(seconds: 1));

  addTearDown(() {
    FlutterError.onError = origOnError;
  });
}
