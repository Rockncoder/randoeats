import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:randoeats/blocs/blocs.dart';
import 'package:randoeats/config/config.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/screens/screens.dart';
import 'package:randoeats/widgets/widgets.dart';

/// Screen displaying restaurant discovery results with slot machine selection.
///
/// This is the main entry point of the app. Shows restaurants sorted by
/// visit count (unvisited first) with a slot machine-style selection.
class ResultsScreen extends StatefulWidget {
  /// Creates a [ResultsScreen].
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final GlobalKey<SlotMachineListState> _slotMachineKey = GlobalKey();
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    // Auto-fetch restaurants on launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<DiscoveryBloc>();
      if (bloc.state.status == DiscoveryStatus.initial) {
        bloc.add(const DiscoveryStarted());
      }
    });
  }

  void _startSpin() {
    context.read<DiscoveryBloc>().add(const DiscoverySpinStarted());
    _slotMachineKey.currentState?.spin();
  }

  void _onSpinComplete(Restaurant restaurant) {
    context.read<DiscoveryBloc>().add(DiscoveryWinnerSelected(restaurant));
    setState(() {
      _showCelebration = true;
    });
  }

  void _onCelebrationComplete() {
    setState(() {
      _showCelebration = false;
    });
    context.read<DiscoveryBloc>().add(const DiscoveryCelebrationComplete());

    // Navigate to detail screen
    final state = context.read<DiscoveryBloc>().state;
    if (state.selectedRestaurant != null) {
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider.value(
              value: context.read<DiscoveryBloc>(),
              child: DetailScreen(restaurant: state.selectedRestaurant!),
            ),
          ),
        ),
      );
    }
  }

  void _onDirectTap(Restaurant restaurant) {
    context.read<DiscoveryBloc>().add(DiscoveryRestaurantSelected(restaurant));

    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BlocProvider.value(
            value: context.read<DiscoveryBloc>(),
            child: DetailScreen(restaurant: restaurant),
          ),
        ),
      ),
    );
  }

  void _navigateToSettings() {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const SettingsScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscoveryBloc, DiscoveryState>(
      builder: (context, state) {
        final isSpinning = state.status == DiscoveryStatus.spinning;

        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // Settings gear in top right
                    _buildTopBar(isSpinning),
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
      },
    );
  }

  Widget _buildTopBar(bool isSpinning) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.settings),
            color: GoogieColors.turquoise,
            iconSize: 28,
            onPressed: isSpinning ? null : _navigateToSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, DiscoveryState state) {
    final theme = Theme.of(context);
    final isSpinning = state.status == DiscoveryStatus.spinning;

    return Column(
      children: [
        // Restaurant list
        Expanded(
          child: state.status == DiscoveryStatus.initial ||
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
        // Rand-o-Eats button
        if (state.status == DiscoveryStatus.success ||
            state.status == DiscoveryStatus.spinning)
          Padding(
            padding: const EdgeInsets.all(16),
            child: RandoEatsButton(
              onPressed: _startSpin,
              isSpinning: isSpinning,
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
                context.read<DiscoveryBloc>().add(const DiscoveryStarted());
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
    return SlotMachineList(
      key: _slotMachineKey,
      restaurants: state.restaurants,
      onRestaurantTap: _onDirectTap,
      onSpinComplete: _onSpinComplete,
    );
  }
}
