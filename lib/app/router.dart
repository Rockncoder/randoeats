import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:go_router/go_router.dart';
import 'package:randoeats/models/models.dart';
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

/// The app router configuration.
final router = GoRouter(
  observers: [
    FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
  ],
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
