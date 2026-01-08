import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:randoeats/models/models.dart';

/// Service for managing local storage using Hive.
class StorageService {
  /// Gets the singleton instance of [StorageService].
  factory StorageService() => _instance;

  StorageService._internal();

  static final StorageService _instance = StorageService._internal();

  /// Gets the singleton instance of [StorageService].
  static StorageService get instance => _instance;

  /// Box names for different data types.
  static const String _ratingsBox = 'ratings';
  static const String _recentPicksBox = 'recent_picks';
  static const String _settingsBox = 'settings';
  static const String _settingsKey = 'user_settings';

  late Box<UserRating> _ratings;
  late Box<RecentPick> _recentPicks;
  late Box<UserSettings> _settings;

  bool _isInitialized = false;

  /// Whether the storage service has been initialized.
  bool get isInitialized => _isInitialized;

  /// Initializes Hive and registers type adapters.
  ///
  /// Must be called before using any storage methods.
  Future<void> initialize() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Register type adapters
    Hive
      ..registerAdapter(RatingTypeAdapter())
      ..registerAdapter(UserRatingAdapter())
      ..registerAdapter(RecentPickAdapter())
      ..registerAdapter(UserSettingsAdapter())
      ..registerAdapter(RestaurantAdapter());

    // Open boxes
    _ratings = await Hive.openBox<UserRating>(_ratingsBox);
    _recentPicks = await Hive.openBox<RecentPick>(_recentPicksBox);
    _settings = await Hive.openBox<UserSettings>(_settingsBox);

    _isInitialized = true;
    debugPrint('StorageService initialized');
  }

  // ============================================
  // User Settings
  // ============================================

  /// Gets the user settings, or default settings if not set.
  UserSettings getSettings() {
    return _settings.get(_settingsKey) ?? const UserSettings();
  }

  /// Saves the user settings.
  Future<void> saveSettings(UserSettings settings) async {
    await _settings.put(_settingsKey, settings);
  }

  // ============================================
  // User Ratings
  // ============================================

  /// Gets all user ratings.
  List<UserRating> getAllRatings() {
    return _ratings.values.toList();
  }

  /// Gets the rating for a specific place, if any.
  UserRating? getRating(String placeId) {
    for (final rating in _ratings.values) {
      if (rating.placeId == placeId) return rating;
    }
    return null;
  }

  /// Saves a rating for a restaurant.
  Future<void> saveRating(UserRating rating) async {
    // Remove any existing rating for this place
    final existingKey = _ratings.keys.cast<dynamic>().firstWhere(
          (key) => _ratings.get(key)?.placeId == rating.placeId,
          orElse: () => null,
        );

    if (existingKey != null) {
      await _ratings.delete(existingKey);
    }

    await _ratings.add(rating);
  }

  /// Removes the rating for a place.
  Future<void> removeRating(String placeId) async {
    final key = _ratings.keys.cast<dynamic>().firstWhere(
          (key) => _ratings.get(key)?.placeId == placeId,
          orElse: () => null,
        );

    if (key != null) {
      await _ratings.delete(key);
    }
  }

  /// Gets all place IDs that have been rated thumbs down.
  Set<String> getThumbsDownPlaceIds() {
    return _ratings.values
        .where((r) => r.isNegative)
        .map((r) => r.placeId)
        .toSet();
  }

  /// Gets all place IDs that have been rated thumbs up.
  Set<String> getThumbsUpPlaceIds() {
    return _ratings.values
        .where((r) => r.isPositive)
        .map((r) => r.placeId)
        .toSet();
  }

  // ============================================
  // Recent Picks
  // ============================================

  /// Gets all recent picks.
  List<RecentPick> getAllRecentPicks() {
    return _recentPicks.values.toList();
  }

  /// Gets the most recent pick for a place, if any.
  RecentPick? getRecentPick(String placeId) {
    for (final pick in _recentPicks.values) {
      if (pick.placeId == placeId) return pick;
    }
    return null;
  }

  /// Saves a recent pick.
  Future<void> saveRecentPick(RecentPick pick) async {
    // Remove any existing pick for this place
    final existingKey = _recentPicks.keys.cast<dynamic>().firstWhere(
          (key) => _recentPicks.get(key)?.placeId == pick.placeId,
          orElse: () => null,
        );

    if (existingKey != null) {
      await _recentPicks.delete(existingKey);
    }

    await _recentPicks.add(pick);
  }

  /// Gets place IDs that should be hidden based on recent picks.
  Set<String> getHiddenPlaceIds() {
    final settings = getSettings();
    return _recentPicks.values
        .where((p) => p.shouldHide(hideDays: settings.hideDaysAfterPick))
        .map((p) => p.placeId)
        .toSet();
  }

  /// Clears all recent picks.
  Future<void> clearRecentPicks() async {
    await _recentPicks.clear();
  }

  // ============================================
  // Utility Methods
  // ============================================

  /// Gets all place IDs that should be excluded from results.
  ///
  /// This includes places that are:
  /// - Rated thumbs down (permanently hidden)
  /// - Recently picked (temporarily hidden based on settings)
  Set<String> getExcludedPlaceIds() {
    return {...getThumbsDownPlaceIds(), ...getHiddenPlaceIds()};
  }

  /// Clears all stored data.
  Future<void> clearAll() async {
    await Future.wait([
      _ratings.clear(),
      _recentPicks.clear(),
      _settings.clear(),
    ]);
  }

  /// Closes all boxes. Call when the app is closing.
  Future<void> close() async {
    await Future.wait([
      _ratings.close(),
      _recentPicks.close(),
      _settings.close(),
    ]);
  }
}
