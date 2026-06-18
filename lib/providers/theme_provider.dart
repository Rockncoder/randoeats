import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randoeats/config/config.dart';
import 'package:randoeats/services/services.dart';

/// The currently selected [AppTheme], restored from storage on launch and
/// persisted whenever the user changes it.
final themeProvider = NotifierProvider<ThemeNotifier, AppTheme>(
  ThemeNotifier.new,
);

/// Notifier backing [themeProvider].
class ThemeNotifier extends Notifier<AppTheme> {
  @override
  AppTheme build() {
    if (!StorageService.instance.isInitialized) return AppTheme.fallback;
    return AppTheme.fromId(StorageService.instance.getThemeId()) ??
        AppTheme.fallback;
  }

  /// Selects and persists [theme].
  Future<void> select(AppTheme theme) async {
    state = theme;
    if (StorageService.instance.isInitialized) {
      await StorageService.instance.setThemeId(theme.id);
    }
  }
}
