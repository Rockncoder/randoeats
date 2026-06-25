import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      // No app bar: the photo runs full-bleed to the very top of the screen
      // (behind the status bar) and the back button floats over it.
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Photo is full-bleed; the rest is capped to a readable width
                // and centered so it doesn't stretch edge-to-edge on tablets.
                _buildHeader(context, theme),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDescription(theme),
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
          // Back button floats over the photo, nudged below the status bar.
          Positioned(
            top: MediaQuery.paddingOf(context).top + 4,
            left: 8,
            child: _buildBackButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        key: const ValueKey('detail_back'),
        icon: const Icon(Icons.arrow_back),
        color: GoogieColors.white,
        onPressed: () => context.pop(),
        tooltip: 'Back',
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    // Google returns the whole photos array, so build a URL for each and let
    // the user swipe through them. Fall back to the single reference.
    final urls = <String>[
      for (final ref in restaurant.photoReferences)
        ?PlacesService.instance.getPhotoUrl(ref, maxWidth: 800),
    ];
    if (urls.isEmpty) {
      final single = PlacesService.instance.getPhotoUrl(
        restaurant.photoReference,
        maxWidth: 800,
      );
      if (single != null) urls.add(single);
    }

    // Give the full-bleed photo more presence on wide screens, where a short
    // strip looked thin above the centered content column. Add the top inset so
    // the photo fills the space behind the status bar too.
    final topInset = MediaQuery.paddingOf(context).top;
    final headerHeight =
        (MediaQuery.sizeOf(context).width >= 640 ? 340.0 : 220.0) + topInset;

    return Hero(
      tag: restaurantPhotoHeroTag(restaurant.placeId),
      child: Container(
        height: headerHeight,
        decoration: BoxDecoration(
          color: GoogieColors.turquoise.withValues(alpha: 0.2),
        ),
        child: urls.isEmpty
            ? _buildPhotoPlaceholder()
            : _PhotoCarousel(photoUrls: urls),
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

  Widget _buildDescription(ThemeData theme) {
    final summary = restaurant.editorialSummary;
    if (summary == null || summary.isEmpty) return const SizedBox.shrink();
    return Padding(
      key: const ValueKey('detail_description'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Text(
        summary,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
          fontStyle: FontStyle.italic,
          height: 1.35,
        ),
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
              // Atmosphere chips — parking/beer/wine. Fetched per-detail-view
              // (one Place Details call, shared) so they show even when the
              // search didn't request the atmosphere fields.
              _AtmosphereChip(
                placeId: restaurant.placeId,
                known: restaurant.hasParking,
                select: (a) => a.hasParking,
                icon: Icons.local_parking,
                label: 'Parking',
                theme: theme,
              ),
              _AtmosphereChip(
                placeId: restaurant.placeId,
                known: restaurant.servesBeer,
                select: (a) => a.servesBeer,
                icon: Icons.sports_bar,
                label: 'Beer',
                theme: theme,
              ),
              _AtmosphereChip(
                placeId: restaurant.placeId,
                known: restaurant.servesWine,
                select: (a) => a.servesWine,
                icon: Icons.wine_bar,
                label: 'Wine',
                theme: theme,
              ),
            ],
          ),
          // Opening hours — today's line, tap to expand the whole week.
          if (restaurant.weekdayHours != null &&
              restaurant.weekdayHours!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _HoursSection(weekdayHours: restaurant.weekdayHours!, theme: theme),
          ],
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

            // For thumbs down, remove from list; for thumbs up, just go back.
            // pop() returns to results for both the container-transform route
            // and the go_router push (winner-celebration) flow.
            if (ratingType == RatingType.thumbsDown) {
              ref
                  .read(discoveryProvider.notifier)
                  .removeRestaurant(
                    restaurant.placeId,
                  );
            }
            context.pop();
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

/// Opening hours: shows today's hours, expands to the full week when tapped.
class _HoursSection extends StatefulWidget {
  const _HoursSection({required this.weekdayHours, required this.theme});

  /// One localized line per day, e.g. "Monday: 9:00 AM – 5:00 PM".
  final List<String> weekdayHours;
  final ThemeData theme;

  @override
  State<_HoursSection> createState() => _HoursSectionState();
}

class _HoursSectionState extends State<_HoursSection> {
  bool _expanded = false;

  static const _dayNames = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  /// Index of today's line. Matches by day name (robust to Monday/Sunday-first
  /// ordering), falling back to a Monday-first assumption.
  int get _todayIndex {
    final today = _dayNames[DateTime.now().weekday - 1];
    final byName = widget.weekdayHours.indexWhere(
      (d) => d.toLowerCase().startsWith(today),
    );
    if (byName >= 0) return byName;
    return (DateTime.now().weekday - 1).clamp(
      0,
      widget.weekdayHours.length - 1,
    );
  }

  /// The hours portion of a "Monday: 9:00 AM – 5:00 PM" line.
  String _hoursPart(String description) {
    final i = description.indexOf(': ');
    return i >= 0 ? description.substring(i + 2) : description;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final todayIdx = _todayIndex;

    return Semantics(
      button: true,
      label: 'Opening hours',
      child: InkWell(
        key: const ValueKey('detail_hours'),
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.schedule, size: 18, color: GoogieColors.turquoise),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topCenter,
                  child: _expanded
                      ? _buildWeek(theme, todayIdx)
                      : _buildToday(
                          theme,
                          _hoursPart(widget.weekdayHours[todayIdx]),
                        ),
                ),
              ),
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToday(ThemeData theme, String todayHours) {
    return Row(
      children: [
        Text(
          'Today',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            todayHours,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeek(ThemeData theme, int todayIdx) {
    TextStyle? styleFor(int i) => theme.textTheme.bodyMedium?.copyWith(
      fontWeight: i == todayIdx ? FontWeight.bold : FontWeight.normal,
      color: i == todayIdx
          ? GoogieColors.coral
          : theme.colorScheme.onSurface.withValues(alpha: 0.8),
    );

    // Day | open | "– close": day left, open times right-aligned in their own
    // column and closing times in the next, so all opens (and all closes) line
    // up regardless of day-name or time width.
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: IntrinsicColumnWidth(),
        2: FlexColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        for (var i = 0; i < widget.weekdayHours.length; i++)
          _dayRow(widget.weekdayHours[i], styleFor(i)),
      ],
    );
  }

  TableRow _dayRow(String description, TextStyle? style) {
    final parsed = _parseLine(description);
    final hasRange = parsed.open.isNotEmpty;
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16, top: 2, bottom: 2),
          child: Text(parsed.day, style: style),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8, top: 2, bottom: 2),
          child: Text(parsed.open, textAlign: TextAlign.right, style: style),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            hasRange ? '– ${parsed.close}' : parsed.close,
            style: style,
          ),
        ),
      ],
    );
  }

  /// Splits "Monday: 9:00 AM – 5:00 PM" into day / open / close. Lines without a
  /// single time range (e.g. "Closed", "Open 24 hours", split lunch/dinner
  /// hours) keep the whole value in `close` with an empty `open`.
  ({String day, String open, String close}) _parseLine(String description) {
    final colon = description.indexOf(': ');
    final day = colon >= 0 ? description.substring(0, colon) : description;
    final rest = (colon >= 0 ? description.substring(colon + 2) : '').trim();
    if (!rest.contains(',')) {
      final match = RegExp('(.+?)[–—-](.+)').firstMatch(rest);
      if (match != null) {
        return (
          day: day,
          open: match.group(1)!.trim(),
          close: match.group(2)!.trim(),
        );
      }
    }
    return (day: day, open: '', close: rest);
  }
}

/// One Place Details lookup per opened place for the atmosphere chips
/// (parking/beer/wine), shared + cached by placeId so the chips fetch once.
// ignore: specify_nonobvious_property_types
final _atmosphereProvider = FutureProvider.family<PlaceAtmosphere, String>(
  (ref, placeId) => PlacesService.instance.fetchAtmosphere(placeId),
);

/// An atmosphere indicator chip (parking/beer/wine). Uses the value from the
/// search if present, otherwise the shared per-detail [_atmosphereProvider].
/// Renders nothing unless Google confirms the amenity.
class _AtmosphereChip extends ConsumerWidget {
  const _AtmosphereChip({
    required this.placeId,
    required this.known,
    required this.select,
    required this.icon,
    required this.label,
    required this.theme,
  });

  final String placeId;
  final bool? known;
  final bool? Function(PlaceAtmosphere) select;
  final IconData icon;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var value = known;
    if (value == null) {
      final atmo = ref.watch(_atmosphereProvider(placeId)).asData?.value;
      if (atmo != null) value = select(atmo);
    }
    if (value != true) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: GoogieColors.turquoiseContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: GoogieColors.onTurquoiseContainer),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: GoogieColors.onTurquoiseContainer,
            ),
          ),
        ],
      ),
    );
  }
}

/// Swipeable photo gallery for the detail header, with page dots.
class _PhotoCarousel extends StatefulWidget {
  const _PhotoCarousel({required this.photoUrls});

  final List<String> photoUrls;

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _placeholder({bool isLoading = false}) {
    return Center(
      child: isLoading
          ? CircularProgressIndicator(color: GoogieColors.turquoise)
          : Icon(Icons.restaurant, size: 80, color: GoogieColors.turquoise),
    );
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.photoUrls;
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          key: const ValueKey('detail_photo_carousel'),
          controller: _controller,
          itemCount: urls.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) => Image.network(
            urls[i],
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, _, _) => _placeholder(),
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : _placeholder(isLoading: true),
          ),
        ),
        // Subtle bottom scrim so the photo transitions into the content
        // instead of butting hard against it.
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x29000000)],
                stops: [0.65, 1],
              ),
            ),
          ),
        ),
        // Top scrim keeps the status bar + floating back button legible over
        // bright photos.
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x59000000), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        // Page dots (only when there's more than one photo).
        if (urls.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < urls.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 9 : 7,
                    height: i == _index ? 9 : 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: GoogieColors.white.withValues(
                        alpha: i == _index ? 1 : 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
