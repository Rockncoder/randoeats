import 'dart:async';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:randoeats/services/services.dart';

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
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

  // Initialize Google Mobile Ads (mobile only)
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }

  // Initialize storage
  await StorageService.instance.initialize();

  runApp(ProviderScope(child: await builder()));
}
