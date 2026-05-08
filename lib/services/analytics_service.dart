import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Centralized analytics service wrapping Firebase Analytics.
///
/// All calls are no-ops on web (Firebase Analytics is not configured for web).
class AnalyticsService {
  AnalyticsService() : _analytics = FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  /// The Firebase Analytics instance (used for the navigation observer).
  FirebaseAnalytics get instance => _analytics;

  Future<void> logScreenView(String screenName) async {
    if (kIsWeb) return;
    await _analytics.logScreenView(screenName: screenName);
  }
}
