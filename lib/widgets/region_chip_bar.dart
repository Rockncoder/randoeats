import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randoeats/config/config.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/providers/active_region_provider.dart';

/// A horizontal, one-tap scope picker shown on the results screen.
///
/// Renders `Near Me` (GPS) followed by each saved region and a trailing `+`
/// chip. Tapping a chip switches the active scope via [activeRegionProvider] —
/// no navigation. Long-pressing a region chip surfaces rename/delete actions.
class RegionChipBar extends ConsumerWidget {
  /// Creates a [RegionChipBar].
  const RegionChipBar({
    required this.regions,
    required this.onCreate,
    required this.onRename,
    required this.onDelete,
    super.key,
  });

  /// The saved regions to show as chips (caller-supplied so the widget stays
  /// free of storage dependencies and is easy to test).
  final List<SavedRegion> regions;

  /// Called when the `+` chip is tapped (open the draw screen).
  final VoidCallback onCreate;

  /// Called to rename a region (parent shows the dialog + persists).
  final void Function(SavedRegion region) onRename;

  /// Called to delete a region (parent persists + reloads).
  final void Function(SavedRegion region) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeRegionProvider);
    final notifier = ref.read(activeRegionProvider.notifier);

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _ScopeChip(
            key: const ValueKey('region_chip_near_me'),
            label: 'Near Me',
            icon: Icons.my_location,
            selected: active == null,
            onTap: notifier.clear,
          ),
          for (final region in regions)
            _ScopeChip(
              key: ValueKey('region_chip_${region.id}'),
              label: region.name,
              icon: Icons.place,
              selected: active?.id == region.id,
              onTap: () => notifier.select(region),
              onLongPress: () => _showRegionMenu(context, region),
            ),
          _ScopeChip(
            key: const ValueKey('region_chip_add'),
            label: 'New Area',
            icon: Icons.add,
            selected: false,
            onTap: onCreate,
          ),
        ],
      ),
    );
  }

  Future<void> _showRegionMenu(BuildContext context, SavedRegion region) async {
    final action = await showModalBottomSheet<_RegionAction>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const ValueKey('region_menu_rename'),
              leading: const Icon(Icons.edit, color: GoogieColors.deepTeal),
              title: const Text('Rename'),
              onTap: () => Navigator.pop(sheetContext, _RegionAction.rename),
            ),
            ListTile(
              key: const ValueKey('region_menu_delete'),
              leading: const Icon(Icons.delete, color: GoogieColors.coral),
              title: const Text('Delete'),
              onTap: () => Navigator.pop(sheetContext, _RegionAction.delete),
            ),
          ],
        ),
      ),
    );

    switch (action) {
      case _RegionAction.rename:
        onRename(region);
      case _RegionAction.delete:
        onDelete(region);
      case null:
        break;
    }
  }
}

enum _RegionAction { rename, delete }

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? GoogieColors.white : GoogieColors.deepTeal;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: ChoiceChip(
          avatar: Icon(icon, size: 18, color: foreground),
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          labelStyle: TextStyle(
            color: foreground,
            fontWeight: FontWeight.w600,
          ),
          selectedColor: GoogieColors.coral,
          backgroundColor: GoogieColors.cream,
          side: const BorderSide(color: GoogieColors.chrome),
          onSelected: (_) => onTap(),
        ),
      ),
    );
  }
}
