import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:randoeats/app/router.dart';
import 'package:randoeats/blocs/blocs.dart';
import 'package:randoeats/config/config.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/providers/active_filters_provider.dart';
import 'package:randoeats/providers/active_region_provider.dart';
import 'package:randoeats/screens/detail/detail_screen.dart';
import 'package:randoeats/services/services.dart';
import 'package:randoeats/widgets/widgets.dart';

/// Screen displaying restaurant discovery results with slot machine selection.
///
/// This is the main entry point of the app. Shows restaurants sorted by
/// visit count (unvisited first) with a slot machine-style selection.
class ResultsScreen extends ConsumerStatefulWidget {
  /// Creates a [ResultsScreen].
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  final GlobalKey<MultiReelSlotMachineState> _slotMachineKey = GlobalKey();
  bool _showCelebration = false;
  // Whether the user dismissed the current advisory banner. Reset on each new
  // search so the banner re-appears for fresh results.
  bool _noticeDismissed = false;
  List<SavedRegion> _regions = [];

  @override
  void initState() {
    super.initState();
    _loadRegions();
    // Auto-fetch restaurants on launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(discoveryProvider);
      if (state.status == DiscoveryStatus.initial) {
        unawaited(ref.read(discoveryProvider.notifier).start());
      }
    });
  }

  void _loadRegions() {
    if (!StorageService.instance.isInitialized) return;
    setState(() => _regions = StorageService.instance.getAllRegions());
  }

  Future<void> _onCreateRegion() async {
    await context.push<void>(AppRoutes.regionDraw);
    _loadRegions();
  }

  Future<void> _onDeleteRegion(SavedRegion region) async {
    await StorageService.instance.deleteRegion(region.id);
    if (ref.read(activeRegionProvider)?.id == region.id) {
      ref.read(activeRegionProvider.notifier).clear();
    }
    _loadRegions();
  }

  Future<void> _onRenameRegion(SavedRegion region) async {
    final controller = TextEditingController(text: region.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename area'),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;

    final renamed = region.copyWith(name: name.trim());
    await StorageService.instance.saveRegion(renamed);
    if (ref.read(activeRegionProvider)?.id == region.id) {
      ref.read(activeRegionProvider.notifier).select(renamed);
    }
    _loadRegions();
  }

  /// Saves the current filters (and the active area, if any) as a named Spot.
  ///
  /// On "Near Me" this creates an area-less (GPS) Spot — recalling it searches
  /// the user's location with these filters. With an area active, the new Spot
  /// reuses that area's polygon plus the current filters.
  Future<void> _onSaveSpot() async {
    final filters = ref.read(activeFiltersProvider);
    if (filters.isEmpty) return;

    final activeRegion = ref.read(activeRegionProvider);
    final hasArea = activeRegion != null && activeRegion.hasArea;
    final areaName = hasArea ? activeRegion.name : null;
    final summary = filters.summaryLabel;
    final suggestion = areaName == null ? summary : '$areaName — $summary';

    final controller = TextEditingController(text: suggestion);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.star, color: GoogieColors.mustard),
            const SizedBox(width: 8),
            const Text('Save Spot'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const ValueKey('spot_name_field'),
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            Text('Area: ${areaName ?? 'Near Me (GPS)'}'),
            const SizedBox(height: 4),
            Text('Filters: $summary'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('spot_save_confirm'),
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;

    final now = DateTime.now();
    final spot = SavedRegion(
      id: now.millisecondsSinceEpoch.toString(),
      name: name.trim(),
      points: hasArea ? activeRegion.points : const <double>[],
      createdAt: now,
      filters: filters,
    );
    await StorageService.instance.saveRegion(spot);
    ref.read(activeRegionProvider.notifier).select(spot);
    _loadRegions();
  }

  void _startSpin() {
    // Guard against re-entry during the reveal/celebration sequence.
    if (_showCelebration) return;
    ref.read(discoveryProvider.notifier).startSpin();
    _slotMachineKey.currentState?.spin();
  }

  void _onSpinComplete(Restaurant restaurant) {
    unawaited(ref.read(discoveryProvider.notifier).selectWinner(restaurant));
    setState(() {
      _showCelebration = true;
    });
  }

  void _onCelebrationComplete() {
    setState(() {
      _showCelebration = false;
    });
    ref.read(discoveryProvider.notifier).completeCelebration();

    // Navigate to detail screen
    final state = ref.read(discoveryProvider);
    if (state.selectedRestaurant != null) {
      unawaited(
        context.push<void>(AppRoutes.detail, extra: state.selectedRestaurant),
      );
    }
  }

  void _onDirectTap(Restaurant restaurant) {
    // Records the selection only; the card's container transform handles the
    // navigation into the detail page (see MultiReelSlotMachine.detailBuilder).
    unawaited(
      ref.read(discoveryProvider.notifier).selectRestaurant(restaurant),
    );
  }

  void _navigateToSettings() {
    unawaited(context.push<void>(AppRoutes.settings));
  }

  /// Opens an M3 bottom sheet for quick radius/price tweaks without leaving the
  /// results screen.
  Future<void> _openQuickTune() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        var settings = StorageService.instance.getSettings();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick tune',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: GoogieColors.deepTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Search radius', style: theme.textTheme.titleSmall),
                  Text(
                    settings.distanceUnit.format(
                      settings.searchRadiusMeters.toDouble(),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: GoogieColors.deepTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: settings.searchRadiusMeters.toDouble().clamp(
                      UserSettings.minSearchRadius.toDouble(),
                      UserSettings.maxSearchRadius.toDouble(),
                    ),
                    min: UserSettings.minSearchRadius.toDouble(),
                    max: UserSettings.maxSearchRadius.toDouble(),
                    divisions: 19,
                    activeColor: GoogieColors.turquoise,
                    onChanged: (v) => setSheetState(
                      () => settings = settings.copyWith(
                        searchRadiusMeters: v.round(),
                      ),
                    ),
                    onChangeEnd: (v) async {
                      await StorageService.instance.saveSettings(
                        settings.copyWith(searchRadiusMeters: v.round()),
                      );
                      unawaited(ref.read(discoveryProvider.notifier).start());
                    },
                  ),
                  const SizedBox(height: 8),
                  Text('Price', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Consumer(
                    builder: (context, sheetRef, _) {
                      final filters = sheetRef.watch(activeFiltersProvider);
                      return Wrap(
                        spacing: 8,
                        children: [
                          for (final level in const [1, 2, 3])
                            ChoiceChip(
                              key: ValueKey('tune_price_$level'),
                              label: Text(r'$' * level),
                              selected: filters.priceLevels.contains(level),
                              showCheckmark: true,
                              selectedColor: GoogieColors.coral,
                              backgroundColor: GoogieColors.turquoiseContainer,
                              shape: const StadiumBorder(),
                              onSelected: (_) => sheetRef
                                  .read(activeFiltersProvider.notifier)
                                  .togglePriceLevel(level),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoveryProvider);
    // Re-run discovery whenever the active scope or filters change.
    ref
      ..listen(activeRegionProvider, (previous, next) {
        if (previous?.id != next?.id) {
          unawaited(ref.read(discoveryProvider.notifier).start());
        }
      })
      ..listen(activeFiltersProvider, (previous, next) {
        if (previous != next) {
          unawaited(ref.read(discoveryProvider.notifier).start());
        }
      })
      // A new search re-arms the advisory banner (un-dismiss it).
      ..listen(discoveryProvider, (previous, next) {
        if (next.status == DiscoveryStatus.loading && _noticeDismissed) {
          setState(() => _noticeDismissed = false);
        }
      });
    final isSpinning = state.status == DiscoveryStatus.spinning;
    final canRefresh =
        state.status == DiscoveryStatus.success ||
        state.status == DiscoveryStatus.selected ||
        state.status == DiscoveryStatus.winner;

    final showSpinButton =
        state.status == DiscoveryStatus.success ||
        state.status == DiscoveryStatus.spinning ||
        state.status == DiscoveryStatus.selected ||
        state.status == DiscoveryStatus.winner;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top bar with refresh and settings
                _buildTopBar(isSpinning, canRefresh),
                // One-tap scope picker: Near Me + saved regions + New Area
                RegionChipBar(
                  regions: _regions,
                  onCreate: _onCreateRegion,
                  onRename: _onRenameRegion,
                  onDelete: _onDeleteRegion,
                ),
                // One-tap filters: cuisine + atmosphere + rating/price
                FilterChipBar(onSaveSpot: _onSaveSpot),
                // Advisory banner (e.g. most places closed right now), pinned
                // at the top of the list so it stays visible until dismissed.
                if (state.notice != null &&
                    !_noticeDismissed &&
                    state.status != DiscoveryStatus.loading)
                  _buildNoticeBanner(context, state.notice!),
                // Main content
                Expanded(
                  child: _buildBody(context, state),
                ),
              ],
            ),
            // Floating round badge: tap to spin. Floats above the listings so
            // users can still tap a card directly to skip the game.
            if (showSpinButton)
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: Center(
                  child: Semantics(
                    identifier: 'spin_button',
                    button: true,
                    child: RandoEatsButton(
                      key: const ValueKey('spin_button'),
                      // Locked for the whole winner sequence: the reel spin
                      // (status == spinning) through the reveal + celebration,
                      // re-enabled only once the celebration completes.
                      onPressed: (isSpinning || _showCelebration)
                          ? null
                          : _startSpin,
                      isSpinning: isSpinning,
                    ),
                  ),
                ),
              ),
            // Winner celebration overlay
            if (_showCelebration)
              WinnerCelebration(onComplete: _onCelebrationComplete),
          ],
        ),
      ),
    );
  }

  void _refreshRestaurants() {
    unawaited(ref.read(discoveryProvider.notifier).refresh());
  }

  /// Turns off the Open-Only setting and re-runs discovery so closed places
  /// show too (the banner's "Show all" action).
  Future<void> _showAllRestaurants() async {
    final settings = StorageService.instance.getSettings();
    await StorageService.instance.saveSettings(
      settings.copyWith(includeOpenOnly: false),
    );
    unawaited(ref.read(discoveryProvider.notifier).refresh());
  }

  Widget _buildNoticeBanner(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: GoogieColors.mustardContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GoogieColors.mustard),
      ),
      child: Row(
        children: [
          Icon(
            Icons.nightlight_round,
            size: 20,
            color: GoogieColors.onMustardContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: GoogieColors.onMustardContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            key: const ValueKey('notice_show_all'),
            onPressed: _showAllRestaurants,
            style: TextButton.styleFrom(
              foregroundColor: GoogieColors.onMustardContainer,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 36),
            ),
            child: const Text('Show all'),
          ),
          IconButton(
            key: const ValueKey('notice_dismiss'),
            icon: const Icon(Icons.close, size: 18),
            color: GoogieColors.onMustardContainer,
            visualDensity: VisualDensity.compact,
            tooltip: 'Dismiss',
            onPressed: () => setState(() => _noticeDismissed = true),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isSpinning, bool canRefresh) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Refresh button (left side)
          if (canRefresh)
            IconButton(
              icon: const Icon(Icons.refresh),
              color: GoogieColors.deepTeal,
              iconSize: 28,
              onPressed: isSpinning ? null : _refreshRestaurants,
              tooltip: 'Find new restaurants',
            ),
          const Spacer(),
          // Quick tune (radius + price) in an M3 bottom sheet.
          IconButton(
            key: const ValueKey('quick_tune_button'),
            icon: const Icon(Icons.tune),
            color: GoogieColors.deepTeal,
            iconSize: 26,
            onPressed: isSpinning ? null : _openQuickTune,
            tooltip: 'Quick tune',
          ),
          // Settings gear (right side)
          Semantics(
            identifier: 'settings_button',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.settings),
              color: GoogieColors.deepTeal,
              iconSize: 28,
              onPressed: isSpinning ? null : _navigateToSettings,
              tooltip: 'Settings',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, DiscoveryState state) {
    final theme = Theme.of(context);

    // The spin control floats over this body (see build); the list fills the
    // whole area and scrolls behind it.
    return state.status == DiscoveryStatus.initial ||
            state.status == DiscoveryStatus.loading
        ? _buildLoading(theme)
        : state.status == DiscoveryStatus.failure
        ? _buildError(
            context,
            theme,
            state.errorMessage ?? 'Unknown error',
          )
        : _buildSlotMachineList(context, state);
  }

  Widget _buildLoading(ThemeData theme) {
    // M3 shimmer skeletons that mirror the cards, instead of a spinner.
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: WavyLine(
                  secondaryColor: GoogieColors.coral,
                  amplitude: 4,
                  wavelength: 30,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Scanning nearby quadrants...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: GoogieColors.deepTeal,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const Expanded(child: SkeletonCardList()),
      ],
    );
  }

  Widget _buildError(BuildContext context, ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: GoogieColors.coral,
            ),
            const SizedBox(height: 16),
            Text(
              'Houston, we have a problem',
              style: theme.textTheme.titleMedium?.copyWith(
                color: GoogieColors.coral,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                unawaited(ref.read(discoveryProvider.notifier).start());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotMachineList(BuildContext context, DiscoveryState state) {
    final calmMode =
        StorageService.instance.isInitialized &&
        StorageService.instance.getSettings().calmMode;
    return MultiReelSlotMachine(
      key: _slotMachineKey,
      restaurants: state.restaurants,
      onRestaurantTap: _onDirectTap,
      onSpinComplete: _onSpinComplete,
      detailBuilder: (restaurant) => DetailScreen(restaurant: restaurant),
      calmMode: calmMode,
    );
  }
}
