import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:randoeats/app/router.dart';
import 'package:randoeats/blocs/blocs.dart';
import 'package:randoeats/config/config.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/services/services.dart';
import 'package:randoeats/widgets/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen displaying restaurant details with navigation and rating options.
class DetailScreen extends ConsumerWidget {
  /// Creates a [DetailScreen].
  const DetailScreen({required this.restaurant, super.key});

  /// The restaurant to display.
  final Restaurant restaurant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Destination'),
        backgroundColor: GoogieColors.turquoiseContainer,
        foregroundColor: GoogieColors.onTurquoiseContainer,
        leading: IconButton(
          key: const ValueKey('detail_back'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo stays full-bleed; everything below is capped to a readable
            // width and centered so the body doesn't stretch edge-to-edge on
            // tablets (where it otherwise reads as a blown-up phone layout).
            _buildHeader(context, theme),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInfo(context, theme),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: WavyLine(
                        secondaryColor: GoogieColors.coral,
                        height: 18,
                        amplitude: 4,
                        wavelength: 34,
                        strokeWidth: 3,
                        speed: 0.5,
                      ),
                    ),
                    _buildActions(context, theme),
                    const SizedBox(height: 24),
                    _buildRatingSection(context, ref, theme),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    final photoUrl = PlacesService.instance.getPhotoUrl(
      restaurant.photoReference,
      maxWidth: 800,
    );

    // Give the full-bleed photo more presence on wide screens, where a short
    // strip looked thin above the centered content column.
    final headerHeight = MediaQuery.sizeOf(context).width >= 640
        ? 340.0
        : 220.0;

    return Hero(
      tag: restaurantPhotoHeroTag(restaurant.placeId),
      child: Container(
        height: headerHeight,
        decoration: BoxDecoration(
          color: GoogieColors.turquoise.withValues(alpha: 0.2),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photoUrl != null)
              Image.network(
                photoUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, error, stackTrace) =>
                    _buildPhotoPlaceholder(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildPhotoPlaceholder(isLoading: true);
                },
              )
            else
              _buildPhotoPlaceholder(),
            // Subtle bottom scrim so the photo transitions into the content
            // instead of butting hard against it.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x29000000)],
                  stops: [0.65, 1],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder({bool isLoading = false}) {
    return Center(
      child: isLoading
          ? CircularProgressIndicator(
              color: GoogieColors.turquoise,
            )
          : Icon(
              Icons.restaurant,
              size: 80,
              color: GoogieColors.turquoise,
            ),
    );
  }

  Widget _buildInfo(BuildContext context, ThemeData theme) {
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
              Icon(
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
          // Phone — tap to call (useful for checking group availability).
          if (restaurant.phoneNumber != null) ...[
            const SizedBox(height: 8),
            _buildPhoneRow(context, theme, restaurant.phoneNumber!),
          ],
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
                  iconColor: GoogieColors.onMustardContainer,
                  label: _formatRating(),
                  fill: GoogieColors.mustardContainer,
                  textColor: GoogieColors.onMustardContainer,
                  theme: theme,
                ),
              // Price level — the "$$" string already reads as price, so no
              // leading dollar-sign icon (it would render as "$ $$").
              if (restaurant.priceLevel != null)
                _buildChip(
                  label: restaurant.priceLevel!,
                  fill: GoogieColors.turquoiseContainer,
                  textColor: GoogieColors.onTurquoiseContainer,
                  theme: theme,
                ),
              // Open status
              if (restaurant.isOpen != null)
                _buildChip(
                  icon: restaurant.isOpen! ? Icons.check_circle : Icons.cancel,
                  iconColor: restaurant.isOpen!
                      ? GoogieColors.statusOpen
                      : GoogieColors.statusClosed,
                  label: restaurant.isOpen! ? 'Open' : 'Closed',
                  fill: restaurant.isOpen!
                      ? GoogieColors.statusOpenContainer
                      : GoogieColors.coralContainer,
                  textColor: restaurant.isOpen!
                      ? GoogieColors.statusOpen
                      : GoogieColors.onCoralContainer,
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

  Widget _buildPhoneRow(
    BuildContext context,
    ThemeData theme,
    String phoneNumber,
  ) {
    return InkWell(
      key: const ValueKey('detail_call'),
      onTap: () => _callPhone(context, phoneNumber),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              Icons.phone,
              size: 18,
              color: GoogieColors.turquoise,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                phoneNumber,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: GoogieColors.turquoise,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required ThemeData theme,
    IconData? icon,
    Color? iconColor,
    Color? fill,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: fill ?? GoogieColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: GoogieColors.turquoiseContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _prettyType(type),
        style: theme.textTheme.bodySmall?.copyWith(
          color: GoogieColors.onTurquoiseContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// Turns a raw Places type ("mexican_restaurant", "greek restaurant") into a
  /// friendly, title-cased label ("Mexican", "Greek") for display. A redundant
  /// trailing "restaurant" is dropped unless it's the only word.
  String _prettyType(String type) {
    var words = type.replaceAll('_', ' ').trim().split(RegExp(r'\s+'));
    if (words.length > 1 && words.last.toLowerCase() == 'restaurant') {
      words = words.sublist(0, words.length - 1);
    }
    return words
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Widget _buildActions(BuildContext context, ThemeData theme) {
    // Single, clearly-labelled action. The app bar's back arrow already covers
    // "go back," so there's no separate abort button. Width is bounded by the
    // centered content column, so the button can stretch without hitting the
    // iPad infinite-width layout assert.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Pulse(
        child: FilledButton.icon(
          key: const ValueKey('detail_navigate'),
          onPressed: () => _openMaps(context),
          icon: const Icon(Icons.navigation),
          label: const Text('Directions'),
          style: FilledButton.styleFrom(
            backgroundColor: GoogieColors.coral,
            foregroundColor: GoogieColors.white,
            minimumSize: const Size(double.infinity, 56),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
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
                  ref: ref,
                  ratingType: RatingType.thumbsUp,
                  icon: Icons.thumb_up,
                  label: 'Good Pick!',
                  color: GoogieColors.statusOpen,
                  containerColor: GoogieColors.statusOpenContainer,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRatingButton(
                  context: context,
                  ref: ref,
                  ratingType: RatingType.thumbsDown,
                  icon: Icons.thumb_down,
                  label: 'Not For Me',
                  color: GoogieColors.statusClosed,
                  containerColor: GoogieColors.coralContainer,
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
    required WidgetRef ref,
    required RatingType ratingType,
    required IconData icon,
    required String label,
    required Color color,
    required Color containerColor,
    required ThemeData theme,
  }) {
    final existingRating = StorageService.instance.getRating(
      restaurant.placeId,
    );
    final isSelected = existingRating?.rating == ratingType;

    return Semantics(
      label: label,
      button: true,
      child: FilledButton.tonal(
        key: ValueKey('detail_rate_${ratingType.name}'),
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
              ref
                  .read(discoveryProvider.notifier)
                  .removeRestaurant(
                    restaurant.placeId,
                  );
            }
            context.go(AppRoutes.results);
          }
        },
        style: FilledButton.styleFrom(
          foregroundColor: isSelected ? GoogieColors.white : color,
          backgroundColor: isSelected ? color : containerColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Icon(icon, size: 28),
      ),
    );
  }

  Future<void> _callPhone(BuildContext context, String phoneNumber) async {
    // Keep digits and a leading + so the dialer gets a clean tel: URI.
    final sanitized = phoneNumber.replaceAll(RegExp('[^0-9+]'), '');
    final url = Uri(scheme: 'tel', path: sanitized);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to place the call'),
            backgroundColor: GoogieColors.coral,
          ),
        );
      }
    }
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
          SnackBar(
            content: const Text('Unable to open maps'),
            backgroundColor: GoogieColors.coral,
          ),
        );
      }
    }
  }
}
