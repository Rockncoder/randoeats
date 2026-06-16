import 'dart:async';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:randoeats/providers/service_providers.dart';
import 'package:randoeats/services/services.dart';

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  // In debug builds (not web, not release), use MarionetteBinding so AI agents
  // can drive the running app via marionette_mcp for feature/bug-fix proofing.
  // It must be the only WidgetsBinding initialized in the process.
  if (kDebugMode && !kIsWeb) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }

  // Use path-based URLs on web (not hash-based) for clean deep links.
  usePathUrlStrategy();

  // Initialize Firebase (skip on web — not configured yet)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
    } on Exception catch (e) {
      log('Firebase initialization failed: $e');
    }
  }

  // Initialize Crashlytics (mobile only)
  if (!kIsWeb) {
    try {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        unawaited(
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
        );
        return true;
      };
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );
    } on Exception catch (e) {
      log('Crashlytics initialization failed: $e');
    }
  } else {
    FlutterError.onError = (details) {
      log(details.exceptionAsString(), stackTrace: details.stack);
    };
  }

  // Initialize Analytics (mobile only — Firebase Analytics is not yet
  // configured for web).
  AnalyticsService? analyticsService;
  if (!kIsWeb) {
    try {
      analyticsService = AnalyticsService();
    } on Exception catch (e) {
      log('Analytics initialization failed: $e');
    }
  }

  // Initialize Google Mobile Ads (mobile only)
  if (!kIsWeb) {
    try {
      await MobileAds.instance.initialize();
    } on Exception catch (e) {
      log('MobileAds initialization failed: $e');
    }
  }

  // Initialize storage
  try {
    await StorageService.instance.initialize();
  } on Exception catch (e) {
    log('Storage initialization failed: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        if (analyticsService != null)
          analyticsServiceProvider.overrideWithValue(analyticsService),
      ],
      child: await builder(),
    ),
  );
}
