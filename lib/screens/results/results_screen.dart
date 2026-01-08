import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:randoeats/blocs/blocs.dart';
import 'package:randoeats/config/config.dart';
import 'package:randoeats/screens/screens.dart';
import 'package:randoeats/widgets/widgets.dart';

/// Screen displaying restaurant discovery results.
///
/// Shows 5 restaurant cards with option to refresh.
class ResultsScreen extends StatelessWidget {
  /// Creates a [ResultsScreen].
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscoveryBloc, DiscoveryState>(
      builder: (context, state) {
        return Scaffold(
          appBar: _buildAppBar(context),
          body: _buildBody(context, state),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Mission Options'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          context.read<DiscoveryBloc>().add(const DiscoveryReset());
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, DiscoveryState state) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: GoogieColors.turquoise.withValues(alpha: 0.1),
          child: Column(
            children: [
              Text(
                'Mission options identified!',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: GoogieColors.turquoise,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (state.mood != null && state.mood!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Searching for "${state.mood}"',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Restaurant list
        Expanded(
          child: state.status == DiscoveryStatus.loading
              ? _buildLoading(theme)
              : state.status == DiscoveryStatus.failure
                  ? _buildError(
                      context,
                      theme,
                      state.errorMessage ?? 'Unknown error',
                    )
                  : _buildList(context, state),
        ),
        // Refresh button
        if (state.status == DiscoveryStatus.success)
          _buildRefreshButton(context, theme),
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
                context.read<DiscoveryBloc>().add(const DiscoveryRefreshed());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, DiscoveryState state) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.restaurants.length,
      itemBuilder: (context, index) {
        final restaurant = state.restaurants[index];
        return RestaurantCard(
          restaurant: restaurant,
          index: index,
          onTap: () async {
            final bloc = context.read<DiscoveryBloc>()
              ..add(DiscoveryRestaurantSelected(restaurant));

            // Navigate to detail screen
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: DetailScreen(restaurant: restaurant),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRefreshButton(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: OutlinedButton.icon(
        onPressed: () {
          context.read<DiscoveryBloc>().add(const DiscoveryRefreshed());
        },
        icon: const Icon(Icons.refresh),
        style: OutlinedButton.styleFrom(
          foregroundColor: GoogieColors.coral,
          side: const BorderSide(color: GoogieColors.coral, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        label: Text(
          'These do not please me',
          style: theme.textTheme.titleSmall?.copyWith(
            color: GoogieColors.coral,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
