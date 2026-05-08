import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/providers/service_providers.dart';
import 'package:randoeats/screens/screens.dart';

/// Route paths for the app.
abstract class AppRoutes {
  /// Results screen (home).
  static const results = '/';

  /// Restaurant detail screen.
  static const detail = '/detail';

  /// Settings screen.
  static const settings = '/settings';
}

/// Provider for the app router.
///
/// The Firebase Analytics observer is attached lazily through
/// [analyticsServiceProvider] so the router builds cleanly in tests
/// and on web where Firebase Analytics is not initialized.
final routerProvider = Provider<GoRouter>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);

  final observers = <NavigatorObserver>[
    if (!kIsWeb && analytics != null)
      FirebaseAnalyticsObserver(analytics: analytics.instance),
  ];

  return GoRouter(
    observers: observers,
    routes: [
      GoRoute(
        path: AppRoutes.results,
        builder: (context, state) => const ResultsScreen(),
      ),
      GoRoute(
        path: AppRoutes.detail,
        builder: (context, state) {
          final restaurant = state.extra! as Restaurant;
          return DetailScreen(restaurant: restaurant);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
