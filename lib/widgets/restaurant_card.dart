import 'package:flutter/material.dart';
import 'package:randoeats/config/config.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/services/services.dart';

/// Hero tag for a restaurant's photo, shared between the winning slot-machine
/// cell and the detail screen header so the photo flies between them.
String restaurantPhotoHeroTag(String placeId) => 'restaurant_photo_$placeId';

/// A full-bleed restaurant card: the photo fills the card, a dark scrim sits at
/// the bottom, and the name + metadata are overlaid in white (M3 Expressive).
///
/// The inner height ([_innerHeight]) plus the card's vertical margin must equal
/// the reel's `cardHeight` (176) so slot-machine spin math lands correctly.
class RestaurantCard extends StatelessWidget {
  /// Creates a [RestaurantCard].
  const RestaurantCard({
    required this.restaurant,
    required this.onTap,
    this.index = 0,
    this.heroTag,
    super.key,
  });

  /// The restaurant to display.
  final Restaurant restaurant;

  /// Callback when the card is tapped.
  final VoidCallback onTap;

  /// Index in the list (used for animation stagger).
  final int index;

  /// Optional Hero tag for the photo. Set only for a unique card (e.g. the
  /// winning reel cell) — repeated cells must leave this null to avoid
  /// duplicate Hero tags on the same route.
  final String? heroTag;

  // 176 reel cardHeight - 2 * 8 vertical margin.
  static const double _innerHeight = 160;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // Tonal elevation (surface tint), no hard drop shadow.
      elevation: 1,
      color: GoogieColors.cardTint,
      surfaceTintColor: GoogieColors.turquoise,
      shadowColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: GoogieColors.turquoise.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: SizedBox(
        height: _innerHeight,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildPhoto(theme),
              // Bottom scrim so white type stays legible over any photo.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00000000),
                      Color(0x33000000),
                      Color(0xD9000000),
                    ],
                    stops: [0.35, 0.6, 1],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTitle(theme),
                    const SizedBox(height: 2),
                    _buildSubtitle(theme),
                    const SizedBox(height: 8),
                    _buildMetadata(theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(ThemeData theme) {
    final photoUrl = PlacesService.instance.getPhotoUrl(
      restaurant.photoReference,
    );

    final photo = ColoredBox(
      color: GoogieColors.turquoise.withValues(alpha: 0.2),
      child: photoUrl != null
          ? Image.network(
              photoUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, error, stackTrace) => _buildPlaceholder(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildPlaceholder(isLoading: true);
              },
            )
          : _buildPlaceholder(),
    );

    if (heroTag == null) return photo;
    return Hero(tag: heroTag!, child: photo);
  }

  Widget _buildPlaceholder({bool isLoading = false}) {
    return Center(
      child: isLoading
          ? CircularProgressIndicator(
              strokeWidth: 2,
              color: GoogieColors.turquoise,
            )
          : Icon(
              Icons.restaurant,
              size: 44,
              color: GoogieColors.turquoise,
            ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Text(
      restaurant.name,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: const [Shadow(color: Color(0x99000000), blurRadius: 6)],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSubtitle(ThemeData theme) {
    return Text(
      restaurant.address,
      style: theme.textTheme.bodySmall?.copyWith(
        color: Colors.white.withValues(alpha: 0.85),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMetadata(ThemeData theme) {
    return Row(
      children: [
        // Rating
        if (restaurant.rating != null) ...[
          Icon(Icons.star, size: 18, color: GoogieColors.mustard),
          const SizedBox(width: 4),
          Text(
            restaurant.rating!.toStringAsFixed(1),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (restaurant.totalRatings != null) ...[
            const SizedBox(width: 4),
            Text(
              '(${restaurant.totalRatings})',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(width: 14),
        ],
        // Price level
        if (restaurant.priceLevel != null) ...[
          Text(
            restaurant.priceLevel!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
        ],
        // Open status — solid pill so it reads over the photo.
        if (restaurant.isOpen != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: restaurant.isOpen!
                  ? GoogieColors.statusOpen
                  : GoogieColors.statusClosed,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              restaurant.isOpen! ? 'Open' : 'Closed',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        // Phone indicator — this place can be called (tap through to detail).
        if (restaurant.phoneNumber != null) ...[
          const Spacer(),
          const Icon(Icons.phone, size: 16, color: Colors.white),
        ],
      ],
    );
  }
}
