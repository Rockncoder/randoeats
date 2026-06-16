import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:randoeats/app/router.dart';
import 'package:randoeats/blocs/blocs.dart';
import 'package:randoeats/config/config.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/providers/active_region_provider.dart';
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

  void _startSpin() {
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
    unawaited(
      ref.read(discoveryProvider.notifier).selectRestaurant(restaurant),
    );

    unawaited(context.push<void>(AppRoutes.detail, extra: restaurant));
  }

  void _navigateToSettings() {
    unawaited(context.push<void>(AppRoutes.settings));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoveryProvider);
    // Re-run discovery whenever the active scope (Near Me / a region) changes.
    ref.listen(activeRegionProvider, (previous, next) {
      if (previous?.id != next?.id) {
        unawaited(ref.read(discoveryProvider.notifier).start());
      }
    });
    final isSpinning = state.status == DiscoveryStatus.spinning;
    final canRefresh =
        state.status == DiscoveryStatus.success ||
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
                // Main content
                Expanded(
                  child: _buildBody(context, state),
                ),
              ],
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
    final isSpinning = state.status == DiscoveryStatus.spinning;
    final showSpinButton =
        state.status == DiscoveryStatus.success ||
        state.status == DiscoveryStatus.spinning ||
        state.status == DiscoveryStatus.selected ||
        state.status == DiscoveryStatus.winner;

    return Column(
      children: [
        // Restaurant list
        Expanded(
          child:
              state.status == DiscoveryStatus.initial ||
                  state.status == DiscoveryStatus.loading
              ? _buildLoading(theme)
              : state.status == DiscoveryStatus.failure
              ? _buildError(
                  context,
                  theme,
                  state.errorMessage ?? 'Unknown error',
                )
              : _buildSlotMachineList(context, state),
        ),
        // Rand-o-Eats button - allows re-spin after returning from details
        if (showSpinButton)
          Padding(
            padding: const EdgeInsets.only(
              top: 4,
              bottom: 12,
              left: 16,
              right: 16,
            ),
            child: Semantics(
              identifier: 'spin_button',
              button: true,
              child: RandoEatsButton(
                onPressed: _startSpin,
                isSpinning: isSpinning,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: GoogieColors.turquoise,
          ),
          const SizedBox(height: 16),
          Text(
            'Scanning nearby quadrants...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: GoogieColors.turquoise,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
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
    return MultiReelSlotMachine(
      key: _slotMachineKey,
      restaurants: state.restaurants,
      onRestaurantTap: _onDirectTap,
      onSpinComplete: _onSpinComplete,
    );
  }
}
