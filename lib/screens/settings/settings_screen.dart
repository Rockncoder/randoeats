import 'package:flutter/material.dart';
import 'package:randoeats/config/config.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/services/services.dart';

/// Available restaurant categories that can be banned.
const restaurantCategories = <String, String>{
  'mexican_restaurant': 'Mexican',
  'chinese_restaurant': 'Chinese',
  'italian_restaurant': 'Italian',
  'japanese_restaurant': 'Japanese',
  'thai_restaurant': 'Thai',
  'indian_restaurant': 'Indian',
  'vietnamese_restaurant': 'Vietnamese',
  'korean_restaurant': 'Korean',
  'american_restaurant': 'American',
  'pizza_restaurant': 'Pizza',
  'burger_restaurant': 'Burgers',
  'seafood_restaurant': 'Seafood',
  'steak_house': 'Steak',
  'sushi_restaurant': 'Sushi',
  'mediterranean_restaurant': 'Mediterranean',
  'greek_restaurant': 'Greek',
  'french_restaurant': 'French',
  'barbecue_restaurant': 'BBQ',
  'cafe': 'Cafe',
  'fast_food_restaurant': 'Fast Food',
  'fine_dining_restaurant': 'Fine Dining',
  'breakfast_restaurant': 'Breakfast',
  'brunch_restaurant': 'Brunch',
  'sandwich_shop': 'Sandwiches',
  'ice_cream_shop': 'Ice Cream',
  'bakery': 'Bakery',
};

/// Screen for configuring app settings.
class SettingsScreen extends StatefulWidget {
  /// Creates a [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late UserSettings _settings;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _settings = StorageService.instance.getSettings();
  }

  Future<void> _saveSettings() async {
    await StorageService.instance.saveSettings(_settings);
    setState(() {
      _hasChanges = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved!'),
          backgroundColor: GoogieColors.turquoise,
        ),
      );
    }
  }

  void _updateSettings(UserSettings newSettings) {
    setState(() {
      _settings = newSettings;
      _hasChanges = true;
    });
  }

  void _toggleCategory(String category) {
    final bannedCategories = Set<String>.from(_settings.bannedCategories);
    if (bannedCategories.contains(category)) {
      bannedCategories.remove(category);
    } else {
      bannedCategories.add(category);
    }
    _updateSettings(_settings.copyWith(bannedCategories: bannedCategories));
  }

  String _formatDistance(int meters) {
    if (_settings.distanceUnit == DistanceUnit.miles) {
      final miles = meters / 1609.34;
      return '${miles.toStringAsFixed(1)} mi';
    }
    if (meters >= 1000) {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
    return '$meters m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveSettings,
              child: Text(
                'SAVE',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: GoogieColors.turquoise,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Distance Units Section
          _buildSectionHeader(theme, 'Distance Units'),
          const SizedBox(height: 12),
          _buildDistanceUnitToggle(theme),

          const SizedBox(height: 24),

          // Search Settings Section
          _buildSectionHeader(theme, 'Search Parameters'),
          const SizedBox(height: 12),

          // Search Radius Slider
          _buildSettingCard(
            theme,
            title: 'Search Radius',
            subtitle: _formatDistance(_settings.searchRadiusMeters),
            child: Slider(
              value: _settings.searchRadiusMeters.toDouble(),
              min: UserSettings.minSearchRadius.toDouble(),
              max: UserSettings.maxSearchRadius.toDouble(),
              divisions: 19,
              activeColor: GoogieColors.turquoise,
              onChanged: (value) {
                _updateSettings(
                  _settings.copyWith(searchRadiusMeters: value.round()),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Max Results Slider
          _buildSettingCard(
            theme,
            title: 'Maximum Results',
            subtitle: '${_settings.maxResults} restaurants',
            child: Slider(
              value: _settings.maxResults.toDouble(),
              min: UserSettings.minMaxResults.toDouble(),
              max: UserSettings.maxMaxResults.toDouble(),
              divisions:
                  UserSettings.maxMaxResults - UserSettings.minMaxResults,
              activeColor: GoogieColors.turquoise,
              onChanged: (value) {
                _updateSettings(
                  _settings.copyWith(maxResults: value.round()),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Open Only Toggle
          _buildSettingCard(
            theme,
            title: 'Open Restaurants Only',
            subtitle: _settings.includeOpenOnly
                ? 'Only showing open restaurants'
                : 'Showing all restaurants',
            child: Switch(
              value: _settings.includeOpenOnly,
              activeTrackColor: GoogieColors.turquoise,
              onChanged: (value) {
                _updateSettings(
                  _settings.copyWith(includeOpenOnly: value),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Banned Categories Section
          _buildSectionHeader(theme, 'Banned Categories'),
          const SizedBox(height: 4),
          Text(
            'Tap to ban, tap again to enable',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          _buildCategoryChips(theme),

          const SizedBox(height: 24),

          // History Settings Section
          _buildSectionHeader(theme, 'History Settings'),
          const SizedBox(height: 12),

          // Hide Days Slider
          _buildSettingCard(
            theme,
            title: 'Hide After Picking',
            subtitle: '${_settings.hideDaysAfterPick} days',
            description:
                'Restaurants you pick will be hidden for this many days.',
            child: Slider(
              value: _settings.hideDaysAfterPick.toDouble(),
              min: UserSettings.minHideDays.toDouble(),
              max: UserSettings.maxHideDays.toDouble(),
              divisions: UserSettings.maxHideDays - UserSettings.minHideDays,
              activeColor: GoogieColors.turquoise,
              onChanged: (value) {
                _updateSettings(
                  _settings.copyWith(hideDaysAfterPick: value.round()),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Data Management Section
          _buildSectionHeader(theme, 'Data Management'),
          const SizedBox(height: 12),

          _buildActionButton(
            theme,
            title: 'Clear Visit History',
            subtitle: 'Reset all visit counts to zero',
            icon: Icons.history,
            onPressed: () => _showClearVisitHistoryDialog(theme),
          ),
          const SizedBox(height: 12),

          _buildActionButton(
            theme,
            title: 'Clear Recent Picks',
            subtitle: 'Show all previously picked restaurants again',
            icon: Icons.refresh,
            onPressed: () => _showClearRecentPicksDialog(theme),
          ),
          const SizedBox(height: 12),

          _buildActionButton(
            theme,
            title: 'Clear All Data',
            subtitle: 'Reset everything including ratings',
            icon: Icons.delete_forever,
            color: GoogieColors.coral,
            onPressed: () => _showClearAllDataDialog(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceUnitToggle(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildUnitOption(
              theme,
              label: 'Miles',
              isSelected: _settings.distanceUnit == DistanceUnit.miles,
              onTap: () => _updateSettings(
                _settings.copyWith(distanceUnit: DistanceUnit.miles),
              ),
            ),
          ),
          Expanded(
            child: _buildUnitOption(
              theme,
              label: 'Kilometers',
              isSelected: _settings.distanceUnit == DistanceUnit.kilometers,
              onTap: () => _updateSettings(
                _settings.copyWith(distanceUnit: DistanceUnit.kilometers),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitOption(
    ThemeData theme, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? GoogieColors.turquoise : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            color: isSelected
                ? Colors.white
                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: restaurantCategories.entries.map((entry) {
        final isBanned = _settings.bannedCategories.contains(entry.key);
        return _buildCategoryChip(
          theme,
          label: entry.value,
          isBanned: isBanned,
          onTap: () => _toggleCategory(entry.key),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryChip(
    ThemeData theme, {
    required String label,
    required bool isBanned,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isBanned
              ? theme.colorScheme.surface
              : GoogieColors.turquoise.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isBanned
                ? theme.colorScheme.outline.withValues(alpha: 0.3)
                : GoogieColors.turquoise,
          ),
        ),
        child: Text(
          isBanned ? label : label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isBanned
                ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                : GoogieColors.turquoise,
            decoration: isBanned ? TextDecoration.lineThrough : null,
            fontWeight: isBanned ? FontWeight.normal : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        color: GoogieColors.turquoise,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSettingCard(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required Widget child,
    String? description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: GoogieColors.turquoise,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (child is Switch) child,
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
          if (child is! Switch) ...[
            const SizedBox(height: 8),
            child,
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    final buttonColor = color ?? GoogieColors.turquoise;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: buttonColor,
        side: BorderSide(color: buttonColor.withValues(alpha: 0.5)),
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: buttonColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: buttonColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: buttonColor.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearVisitHistoryDialog(ThemeData theme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Visit History?'),
        content: const Text(
          'This will reset all restaurant visit counts to zero. '
          'Unvisited restaurants will no longer be prioritized.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'CLEAR',
              style: TextStyle(color: GoogieColors.coral),
            ),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && mounted) {
      await StorageService.instance.clearVisitedPlaces();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visit history cleared!'),
          backgroundColor: GoogieColors.turquoise,
        ),
      );
    }
  }

  Future<void> _showClearRecentPicksDialog(ThemeData theme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Recent Picks?'),
        content: const Text(
          'This will show all previously picked restaurants again. '
          'They will no longer be hidden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'CLEAR',
              style: TextStyle(color: GoogieColors.coral),
            ),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && mounted) {
      await StorageService.instance.clearRecentPicks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recent picks cleared!'),
          backgroundColor: GoogieColors.turquoise,
        ),
      );
    }
  }

  Future<void> _showClearAllDataDialog(ThemeData theme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will delete all your data including ratings, '
          'visit history, and recent picks. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'DELETE ALL',
              style: TextStyle(color: GoogieColors.coral),
            ),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && mounted) {
      await StorageService.instance.clearAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data cleared!'),
          backgroundColor: GoogieColors.coral,
        ),
      );
    }
  }
}
