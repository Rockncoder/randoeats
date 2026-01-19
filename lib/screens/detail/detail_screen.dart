import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:randoeats/blocs/blocs.dart';
import 'package:randoeats/config/config.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/services/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen displaying restaurant details with navigation and rating options.
class DetailScreen extends StatelessWidget {
  /// Creates a [DetailScreen].
  const DetailScreen({required this.restaurant, super.key});

  /// The restaurant to display.
  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Destination Locked!'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(theme),
            _buildInfo(theme),
            const Divider(height: 32, indent: 16, endIndent: 16),
            _buildActions(context, theme),
            const SizedBox(height: 24),
            _buildRatingSection(context, theme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final photoUrl = PlacesService.instance.getPhotoUrl(
      restaurant.photoReference,
      maxWidth: 800,
    );

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: GoogieColors.turquoise.withValues(alpha: 0.2),
      ),
      child: photoUrl != null
          ? Image.network(
              photoUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, error, stackTrace) => _buildPhotoPlaceholder(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildPhotoPlaceholder(isLoading: true);
              },
            )
          : _buildPhotoPlaceholder(),
    );
  }

  Widget _buildPhotoPlaceholder({bool isLoading = false}) {
    return Center(
      child: isLoading
          ? const CircularProgressIndicator(
              color: GoogieColors.turquoise,
            )
          : const Icon(
              Icons.restaurant,
              size: 80,
              color: GoogieColors.turquoise,
            ),
    );
  }

  Widget _buildInfo(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            restaurant.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: GoogieColors.coral,
            ),
          ),
          const SizedBox(height: 8),
          // Address
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 18,
                color: GoogieColors.turquoise,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  restaurant.address,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Metadata row
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              // Rating
              if (restaurant.rating != null)
                _buildChip(
                  icon: Icons.star,
                  iconColor: GoogieColors.mustard,
                  label: _formatRating(),
                  theme: theme,
                ),
              // Price level
              if (restaurant.priceLevel != null)
                _buildChip(
                  icon: Icons.attach_money,
                  iconColor: GoogieColors.turquoise,
                  label: restaurant.priceLevel!,
                  theme: theme,
                ),
              // Open status
              if (restaurant.isOpen != null)
                _buildChip(
                  icon: restaurant.isOpen! ? Icons.check_circle : Icons.cancel,
                  iconColor: restaurant.isOpen! ? Colors.green : Colors.red,
                  label: restaurant.isOpen! ? 'Open now' : 'Closed',
                  theme: theme,
                ),
            ],
          ),
          // Categories
          if (restaurant.types.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: restaurant.types
                  .take(5)
                  .map((type) => _buildCategoryChip(type, theme))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required Color iconColor,
    required String label,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: GoogieColors.chrome,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRating() {
    final rating = restaurant.rating!.toStringAsFixed(1);
    if (restaurant.totalRatings != null) {
      return '$rating (${restaurant.totalRatings})';
    }
    return rating;
  }

  Widget _buildCategoryChip(String type, ThemeData theme) {
    final displayType = type.replaceAll('_', ' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: GoogieColors.turquoise.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayType,
        style: theme.textTheme.bodySmall?.copyWith(
          color: GoogieColors.turquoise,
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _openMaps(context),
              icon: const Icon(Icons.navigation),
              label: const Text('NAVIGATE'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: GoogieColors.coral,
              side: const BorderSide(color: GoogieColors.coral, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            ),
            child: const Text('Abort Mission'),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How was this establishment?',
            style: theme.textTheme.titleMedium?.copyWith(
              color: GoogieColors.turquoise,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your rating helps us make better recommendations.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildRatingButton(
                  context: context,
                  ratingType: RatingType.thumbsUp,
                  icon: Icons.thumb_up,
                  label: 'Good Pick!',
                  color: Colors.green,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRatingButton(
                  context: context,
                  ratingType: RatingType.thumbsDown,
                  icon: Icons.thumb_down,
                  label: 'Not For Me',
                  color: Colors.red,
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingButton({
    required BuildContext context,
    required RatingType ratingType,
    required IconData icon,
    required String label,
    required Color color,
    required ThemeData theme,
  }) {
    final existingRating = StorageService.instance.getRating(
      restaurant.placeId,
    );
    final isSelected = existingRating?.rating == ratingType;

    return OutlinedButton(
      onPressed: () async {
        final rating = UserRating(
          placeId: restaurant.placeId,
          rating: ratingType,
          ratedAt: DateTime.now(),
        );

        await StorageService.instance.saveRating(rating);

        // Also save as recent pick
        final pick = RecentPick(
          placeId: restaurant.placeId,
          pickedAt: DateTime.now(),
        );
        await StorageService.instance.saveRecentPick(pick);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ratingType == RatingType.thumbsUp
                    ? 'Added to your favorites!'
                    : "Got it! We won't suggest this again.",
              ),
              backgroundColor: color,
            ),
          );

          // For thumbs down, remove from list; for thumbs up, just go back
          if (ratingType == RatingType.thumbsDown) {
            context.read<DiscoveryBloc>().add(
              DiscoveryRestaurantRemoved(restaurant.placeId),
            );
          }
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : color,
        backgroundColor: isSelected ? color : Colors.transparent,
        side: BorderSide(color: color, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _openMaps(BuildContext context) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${restaurant.latitude},${restaurant.longitude}'
      '&destination_place_id=${restaurant.placeId}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open maps'),
            backgroundColor: GoogieColors.coral,
          ),
        );
      }
    }
  }
}
