// `select`/`clear` read better at call sites than assignment setters would.
// ignore_for_file: use_setters_to_change_properties
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randoeats/models/models.dart';

/// The currently active discovery scope.
///
/// `null` means "Near Me" (use the device's GPS location). A non-null value
/// scopes discovery to that saved region's polygon. Held in memory for the
/// session; switching the scope is a single tap from the results screen.
final activeRegionProvider =
    NotifierProvider<ActiveRegionNotifier, SavedRegion?>(
      ActiveRegionNotifier.new,
    );

/// Notifier backing [activeRegionProvider].
class ActiveRegionNotifier extends Notifier<SavedRegion?> {
  @override
  SavedRegion? build() => null;

  /// Scopes discovery to [region].
  void select(SavedRegion region) => state = region;

  /// Resets the scope to "Near Me" (GPS).
  void clear() => state = null;
}
