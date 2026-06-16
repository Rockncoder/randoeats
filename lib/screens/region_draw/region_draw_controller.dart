import 'package:flutter/foundation.dart';
import 'package:randoeats/services/geo_utils.dart';

/// Holds the in-progress lasso drawing state for the region draw screen.
///
/// Deliberately UI-free (no widgets, no maps SDK types beyond [LatLngPoint])
/// so the drawing logic can be unit-tested without a live map.
class RegionDrawController extends ChangeNotifier {
  /// Creates a controller. [simplifyTolerance] is the RDP tolerance (degrees)
  /// applied to the raw lasso path when drawing finishes.
  RegionDrawController({double simplifyTolerance = 0.0002})
    : _tolerance = simplifyTolerance;

  final double _tolerance;

  bool _isDrawing = false;
  final List<LatLngPoint> _points = [];

  /// Whether a lasso drag is currently in progress.
  bool get isDrawing => _isDrawing;

  /// The current polygon vertices (raw while drawing, simplified once
  /// [finishDrawing] has run).
  List<LatLngPoint> get points => List.unmodifiable(_points);

  /// Whether the current shape forms a saveable polygon (≥ 3 vertices).
  bool get canSave => _points.length >= 3;

  /// Begins a fresh lasso, discarding any previous path.
  void startDrawing() {
    _isDrawing = true;
    _points.clear();
    notifyListeners();
  }

  /// Appends a point to the current lasso. Ignored unless [isDrawing].
  void addPoint(LatLngPoint point) {
    if (!_isDrawing) return;
    _points.add(point);
    notifyListeners();
  }

  /// Appends several points to the current lasso. Ignored unless [isDrawing].
  void addPoints(Iterable<LatLngPoint> points) {
    if (!_isDrawing) return;
    _points.addAll(points);
    notifyListeners();
  }

  /// Ends the lasso and simplifies the captured path into a compact polygon.
  ///
  /// Leaves the path untouched when fewer than three points were captured.
  void finishDrawing() {
    _isDrawing = false;
    if (_points.length >= 3) {
      final simplified = GeoUtils.simplifyPolygon(
        _points,
        tolerance: _tolerance,
      );
      _points
        ..clear()
        ..addAll(simplified);
    }
    notifyListeners();
  }

  /// Clears the path and exits drawing mode.
  void clear() {
    _isDrawing = false;
    _points.clear();
    notifyListeners();
  }
}
