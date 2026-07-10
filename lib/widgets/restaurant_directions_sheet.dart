import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:randoeats/config/config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// A modal bottom sheet that shows Google Maps **directions** in-app.
///
/// Presents a WebView with the route drawn from the user's location ([origin])
/// to the restaurant ([destination]); when [origin] is null (location not yet
/// available) it falls back to showing the restaurant on its own. An "Open in
/// Google Maps" button hands off to the Maps app for full turn-by-turn.
///
/// Present it with [RestaurantDirectionsSheet.show].
class RestaurantDirectionsSheet extends StatefulWidget {
  /// Creates a [RestaurantDirectionsSheet].
  const RestaurantDirectionsSheet({
    required this.destination,
    required this.name,
    required this.externalUrl,
    this.origin,
    super.key,
  });

  /// The restaurant's coordinates (the route's destination).
  final LatLng destination;

  /// The user's coordinates (the route's origin); null when unknown.
  final LatLng? origin;

  /// The restaurant's name, shown in the title.
  final String name;

  /// The full Google Maps directions URL for the "Open in Google Maps" handoff.
  final Uri externalUrl;

  /// Presents the sheet as a modal bottom sheet over [context].
  static Future<void> show(
    BuildContext context, {
    required LatLng destination,
    required String name,
    required Uri externalUrl,
    LatLng? origin,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      // Off so the map inside keeps pan/zoom gestures.
      enableDrag: false,
      // Let the sheet grow tall enough to be a usable directions view.
      isScrollControlled: true,
      backgroundColor: GoogieColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => RestaurantDirectionsSheet(
        destination: destination,
        name: name,
        externalUrl: externalUrl,
        origin: origin,
      ),
    );
  }

  @override
  State<RestaurantDirectionsSheet> createState() =>
      _RestaurantDirectionsSheetState();
}

class _RestaurantDirectionsSheetState extends State<RestaurantDirectionsSheet> {
  /// Maps Embed API key (build-time). When set, the official Embed API is used,
  /// which auto-fits the route so both endpoints are always in view. When
  /// empty, we fall back to the keyless embed (renders a route, but doesn't
  /// frame both ends as nicely).
  static const _embedKey = String.fromEnvironment('MAPS_EMBED_KEY');

  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    unawaited(_controller.setJavaScriptMode(JavaScriptMode.unrestricted));
    // The Google Maps embed refuses to render as a top-level document ("must be
    // used in an iFrame"), so load a tiny wrapper page that hosts it in an
    // iframe. The randoeats.com base URL gives the iframe a matching referrer
    // for referrer-restricted keys.
    unawaited(
      _controller.loadHtmlString(
        _embedHtml(),
        baseUrl: 'https://randoeats.com/',
      ),
    );
  }

  /// The embeddable Google Maps URL. With a key it uses the official Embed API
  /// (directions mode when we have the user's location, place mode otherwise),
  /// which auto-fits the view. Without a key it uses the keyless embed.
  String _embedUrl() {
    final d = widget.destination;
    final o = widget.origin;

    if (_embedKey.isNotEmpty) {
      if (o != null) {
        return 'https://www.google.com/maps/embed/v1/directions'
            '?key=$_embedKey'
            '&origin=${o.latitude},${o.longitude}'
            '&destination=${d.latitude},${d.longitude}'
            '&mode=driving';
      }
      return 'https://www.google.com/maps/embed/v1/place'
          '?key=$_embedKey&q=${d.latitude},${d.longitude}';
    }

    if (o == null) {
      return 'https://maps.google.com/maps'
          '?q=${d.latitude},${d.longitude}&output=embed';
    }
    return 'https://maps.google.com/maps'
        '?saddr=${o.latitude},${o.longitude}'
        '&daddr=${d.latitude},${d.longitude}&output=embed';
  }

  /// A minimal HTML page that hosts the maps embed in a full-bleed iframe.
  String _embedHtml() {
    final src = _embedUrl();
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
<style>html,body{margin:0;padding:0;height:100%}iframe{border:0;width:100%;height:100%;display:block}</style>
</head>
<body>
<iframe src="$src" allowfullscreen loading="lazy"
        referrerpolicy="no-referrer-when-downgrade"></iframe>
</body>
</html>
''';
  }

  Future<void> _openInGoogleMaps() async {
    await launchUrl(widget.externalUrl, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      key: const ValueKey('restaurantDetailDirectionsSheet1'),
      height: 0.85 * MediaQuery.of(context).size.height,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Directions to ${widget.name}',
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  key: const ValueKey('restaurantDetailCloseBtn1'),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: WebViewWidget(
              key: const ValueKey('restaurantDetailDirectionsMap1'),
              controller: _controller,
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  key: const ValueKey('restaurantDetailOpenExternalBtn1'),
                  onPressed: _openInGoogleMaps,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open in Google Maps'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
