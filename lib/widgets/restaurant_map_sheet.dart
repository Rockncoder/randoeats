import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:randoeats/config/config.dart';

/// A modal bottom sheet that shows a single restaurant on a Google map.
///
/// Present it with [RestaurantMapSheet.show]. The sheet covers ~60% of the
/// screen, has drag-to-dismiss disabled so pan/zoom gestures belong to the map,
/// and drops one marker on [coordinates] with [name] shown as the title. A ✕ in
/// the top-right corner dismisses it.
class RestaurantMapSheet extends StatelessWidget {
  /// Creates a [RestaurantMapSheet] for [name] at [coordinates].
  const RestaurantMapSheet({
    required this.coordinates,
    required this.name,
    super.key,
  });

  /// The restaurant's location; the map centers here and drops its marker.
  final LatLng coordinates;

  /// The restaurant's name, shown as the title above the map.
  final String name;

  /// Presents the sheet as a modal bottom sheet over [context].
  ///
  /// Returns a future that completes when the sheet is dismissed.
  static Future<void> show(
    BuildContext context, {
    required LatLng coordinates,
    required String name,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      // Off so the map keeps pan/zoom gestures instead of dismissing the sheet.
      enableDrag: false,
      // Allow the sheet to grow past the default (~half-screen) cap so the
      // fixed 60% height below isn't clipped.
      isScrollControlled: true,
      backgroundColor: GoogieColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => RestaurantMapSheet(coordinates: coordinates, name: name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 0.6 * MediaQuery.of(context).size.height,
      child: Column(
        children: [
          // Title on the left, close (✕) on the right.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  key: const ValueKey('restaurant_map_close'),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: coordinates,
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('restaurant'),
                    position: coordinates,
                    infoWindow: InfoWindow(title: name),
                  ),
                },
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
