import 'package:flutter/material.dart';
import 'package:randoeats/config/config.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/services/services.dart';

/// A card displaying restaurant information in Googie style.
class RestaurantCard extends StatelessWidget {
  /// Creates a [RestaurantCard].
  const RestaurantCard({
    required this.restaurant,
    required this.onTap,
    this.index = 0,
    super.key,
  });

  /// The restaurant to display.
  final Restaurant restaurant;

  /// Callback when the card is tapped.
  final VoidCallback onTap;

  /// Index in the list (used for animation stagger).
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: GoogieColors.chrome,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo or placeholder
            _buildPhoto(theme),
            // Info section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(theme),
                  const SizedBox(height: 4),
                  _buildSubtitle(theme),
                  const SizedBox(height: 8),
                  _buildMetadata(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto(ThemeData theme) {
    final photoUrl = PlacesService.instance.getPhotoUrl(
      restaurant.photoReference,
    );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: GoogieColors.turquoise.withValues(alpha: 0.2),
        ),
        child: photoUrl != null
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, error, stackTrace) => _buildPlaceholder(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildPlaceholder(isLoading: true);
                },
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder({bool isLoading = false}) {
    return Center(
      child: isLoading
          ? const CircularProgressIndicator(
              strokeWidth: 2,
              color: GoogieColors.turquoise,
            )
          : const Icon(
              Icons.restaurant,
              size: 36,
              color: GoogieColors.turquoise,
            ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Text(
      restaurant.name,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: GoogieColors.coral,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSubtitle(ThemeData theme) {
    return Text(
      restaurant.address,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMetadata(ThemeData theme) {
    return Row(
      children: [
        // Rating
        if (restaurant.rating != null) ...[
          const Icon(Icons.star, size: 18, color: GoogieColors.mustard),
          const SizedBox(width: 4),
          Text(
            restaurant.rating!.toStringAsFixed(1),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (restaurant.totalRatings != null) ...[
            const SizedBox(width: 4),
            Text(
              '(${restaurant.totalRatings})',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
          const SizedBox(width: 16),
        ],
        // Price level
        if (restaurant.priceLevel != null) ...[
          Text(
            restaurant.priceLevel!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: GoogieColors.turquoise,
            ),
          ),
          const SizedBox(width: 16),
        ],
        // Open status
        if (restaurant.isOpen != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: restaurant.isOpen!
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              restaurant.isOpen! ? 'Open' : 'Closed',
              style: theme.textTheme.bodySmall?.copyWith(
                color: restaurant.isOpen! ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
