import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randoeats/services/analytics_service.dart';

/// Provider for the AnalyticsService.
///
/// Returns null on web (Firebase Analytics not configured for web).
/// Initialized eagerly in bootstrap and injected via ProviderScope overrides.
final analyticsServiceProvider = Provider<AnalyticsService?>((ref) {
  if (kIsWeb) return null;
  return AnalyticsService();
});
