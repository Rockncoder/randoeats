import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:randoeats/config/config.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/providers/active_filters_provider.dart';
import 'package:randoeats/providers/active_region_provider.dart';
import 'package:randoeats/screens/region_draw/region_draw_controller.dart';
import 'package:randoeats/services/services.dart';

/// Screen for creating a new region by tracing a freehand lasso on the map.
///
/// Pan/zoom to frame the area, tap *Draw*, then drag a loop around the blocks
/// you like. The loop is simplified into a polygon, auto-named via reverse
/// geocoding, and saved as the active scope.
class RegionDrawScreen extends ConsumerStatefulWidget {
  /// Creates a [RegionDrawScreen].
  const RegionDrawScreen({super.key});

  @override
  ConsumerState<RegionDrawScreen> createState() => _RegionDrawScreenState();
}

class _RegionDrawScreenState extends ConsumerState<RegionDrawScreen> {
  // Default camera: Old Towne Orange (the motivating "Orange Circle").
  static const _initialCamera = CameraPosition(
    target: LatLng(33.7879, -117.8531),
    zoom: 14,
  );

  final RegionDrawController _draw = RegionDrawController();
  final List<Offset> _screenPath = [];

  GoogleMapController? _mapController;
  bool _drawMode = false;

  @override
  void dispose() {
    _draw.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _toggleDrawMode() {
    setState(() {
      _drawMode = !_drawMode;
      if (_drawMode) {
        _draw.clear();
        _screenPath.clear();
      }
    });
  }

  void _onPanStart(DragStartDetails details) {
    _screenPath
      ..clear()
      ..add(details.localPosition);
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() => _screenPath.add(details.localPosition));
  }

  Future<void> _onPanEnd(DragEndDetails details) async {
    final controller = _mapController;
    if (controller == null || _screenPath.length < 3) {
      setState(_screenPath.clear);
      return;
    }

    final ratio = MediaQuery.of(context).devicePixelRatio;
    final vertices = <({double lat, double lng})>[];
    for (final point in _screenPath) {
      final latLng = await controller.getLatLng(
        ScreenCoordinate(
          x: (point.dx * ratio).round(),
          y: (point.dy * ratio).round(),
        ),
      );
      vertices.add((lat: latLng.latitude, lng: latLng.longitude));
    }

    _draw
      ..startDrawing()
      ..addPoints(vertices)
      ..finishDrawing();

    if (!mounted) return;
    setState(() {
      _drawMode = false;
      _screenPath.clear();
    });
  }

  Future<void> _save() async {
    final vertices = _draw.points;
    if (vertices.length < 3) return;

    final circle = GeoUtils.boundingCircle(vertices);
    final suggested = await _suggestRegionName(circle.lat, circle.lng);
    if (!mounted) return;

    final name = await _promptForName(suggested);
    if (name == null || name.trim().isEmpty) return;

    final region = SavedRegion.fromVertices(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      vertices: vertices,
      createdAt: DateTime.now(),
      // Bundle the currently-active filters so the Spot recalls where + what.
      filters: ref.read(activeFiltersProvider),
    );
    await StorageService.instance.saveRegion(region);
    if (!mounted) return;

    ref.read(activeRegionProvider.notifier).select(region);
    Navigator.of(context).pop(true);
  }

  Future<String> _suggestRegionName(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return 'New Area';
      final placemark = placemarks.first;
      final subLocality = placemark.subLocality ?? '';
      if (subLocality.isNotEmpty) return subLocality;
      final locality = placemark.locality ?? '';
      return locality.isNotEmpty ? locality : 'New Area';
    } on Exception {
      return 'New Area';
    }
  }

  Future<String?> _promptForName(String initial) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Name this area'),
        content: TextField(
          key: const ValueKey('region_name_field'),
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Orange Circle'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('region_save_confirm'),
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Set<Polygon> _buildPolygons() {
    if (_draw.points.length < 3) return const {};
    return {
      Polygon(
        polygonId: const PolygonId('draft'),
        points: _draw.points.map((p) => LatLng(p.lat, p.lng)).toList(),
        strokeColor: GoogieColors.turquoise,
        strokeWidth: 3,
        fillColor: GoogieColors.coral.withValues(alpha: 0.25),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw an Area'),
        actions: [
          AnimatedBuilder(
            animation: _draw,
            builder: (context, _) => TextButton(
              key: const ValueKey('region_save_button'),
              onPressed: _draw.canSave && !_drawMode ? _save : null,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _draw,
        builder: (context, _) => Stack(
          children: [
            GoogleMap(
              initialCameraPosition: _initialCamera,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              polygons: _buildPolygons(),
              scrollGesturesEnabled: !_drawMode,
              zoomGesturesEnabled: !_drawMode,
              rotateGesturesEnabled: !_drawMode,
              tiltGesturesEnabled: !_drawMode,
              myLocationButtonEnabled: false,
            ),
            if (_drawMode) ...[
              Positioned.fill(
                child: CustomPaint(painter: _LassoPainter(_screenPath)),
              ),
              Positioned.fill(
                child: GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  behavior: HitTestBehavior.opaque,
                ),
              ),
              const _DrawHint(),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('region_draw_fab'),
        onPressed: _toggleDrawMode,
        backgroundColor: _drawMode ? GoogieColors.chrome : GoogieColors.coral,
        icon: Icon(_drawMode ? Icons.close : Icons.gesture),
        label: Text(_pickFabLabel()),
      ),
    );
  }

  String _pickFabLabel() {
    if (_drawMode) return 'Cancel';
    return _draw.canSave ? 'Redraw' : 'Draw';
  }
}

/// Paints the in-progress lasso path as the user drags.
class _LassoPainter extends CustomPainter {
  const _LassoPainter(this.points);

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = GoogieColors.turquoise
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LassoPainter oldDelegate) => true;
}

class _DrawHint extends StatelessWidget {
  const _DrawHint();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: GoogieColors.spaceBlack.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            'Trace a loop around your area, then lift your finger',
            textAlign: TextAlign.center,
            style: TextStyle(color: GoogieColors.white),
          ),
        ),
      ),
    );
  }
}
