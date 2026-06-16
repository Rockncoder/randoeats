import 'dart:math' as math;

/// A latitude/longitude pair used by the geometry helpers.
typedef LatLngPoint = ({double lat, double lng});

/// A circle that encloses a polygon: a center (`lat`/`lng`) and `radiusMeters`.
typedef BoundingCircle = ({double lat, double lng, double radiusMeters});

/// Pure geometry helpers for region selection.
///
/// These functions are deliberately dependency-free (no maps/geolocator
/// plugins) so they can be unit-tested without a Flutter binding.
abstract final class GeoUtils {
  static const double _earthRadiusMeters = 6371000;

  /// Returns whether the point ([lat], [lng]) lies inside [polygon].
  ///
  /// Uses the even-odd ray-casting rule. A polygon with fewer than three
  /// vertices can not contain anything, so this returns `false`.
  static bool isPointInPolygon(
    double lat,
    double lng,
    List<LatLngPoint> polygon,
  ) {
    if (polygon.length < 3) return false;

    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].lng;
      final yi = polygon[i].lat;
      final xj = polygon[j].lng;
      final yj = polygon[j].lat;

      final crossesRay = (yi > lat) != (yj > lat);
      if (crossesRay && lng < (xj - xi) * (lat - yi) / (yj - yi) + xi) {
        inside = !inside;
      }
    }
    return inside;
  }

  /// Returns the smallest enclosing circle (approx) for [polygon].
  ///
  /// The center is the vertex centroid and the radius is the greatest distance
  /// from that centroid to any vertex, scaled by [padding] (default 5%) so the
  /// Places query comfortably covers the whole polygon. Throws [ArgumentError]
  /// when [polygon] is empty.
  static BoundingCircle boundingCircle(
    List<LatLngPoint> polygon, {
    double padding = 1.05,
  }) {
    if (polygon.isEmpty) {
      throw ArgumentError.value(polygon, 'polygon', 'must not be empty');
    }

    var sumLat = 0.0;
    var sumLng = 0.0;
    for (final p in polygon) {
      sumLat += p.lat;
      sumLng += p.lng;
    }
    final centerLat = sumLat / polygon.length;
    final centerLng = sumLng / polygon.length;

    var maxDistance = 0.0;
    for (final p in polygon) {
      final d = distanceMeters(centerLat, centerLng, p.lat, p.lng);
      if (d > maxDistance) maxDistance = d;
    }

    return (
      lat: centerLat,
      lng: centerLng,
      radiusMeters: maxDistance * padding,
    );
  }

  /// Great-circle distance in meters between two coordinates (Haversine).
  static double distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.asin(math.min(1, math.sqrt(a)));
    return _earthRadiusMeters * c;
  }

  /// Simplifies [points] using the Ramer–Douglas–Peucker algorithm.
  ///
  /// [tolerance] is expressed in degrees (~0.0002 ≈ 22m). Lists of three or
  /// fewer points are returned unchanged.
  static List<LatLngPoint> simplifyPolygon(
    List<LatLngPoint> points, {
    double tolerance = 0.0002,
  }) {
    if (points.length <= 3) return List<LatLngPoint>.of(points);
    return _rdp(points, tolerance);
  }

  static List<LatLngPoint> _rdp(List<LatLngPoint> points, double epsilon) {
    if (points.length < 3) return List<LatLngPoint>.of(points);

    final end = points.length - 1;
    var maxDistance = 0.0;
    var index = 0;
    for (var i = 1; i < end; i++) {
      final d = _perpendicularDistance(points[i], points.first, points[end]);
      if (d > maxDistance) {
        maxDistance = d;
        index = i;
      }
    }

    if (maxDistance <= epsilon) {
      return [points.first, points[end]];
    }

    final left = _rdp(points.sublist(0, index + 1), epsilon);
    final right = _rdp(points.sublist(index), epsilon);
    return [...left.sublist(0, left.length - 1), ...right];
  }

  static double _perpendicularDistance(
    LatLngPoint p,
    LatLngPoint a,
    LatLngPoint b,
  ) {
    final dx = b.lng - a.lng;
    final dy = b.lat - a.lat;
    if (dx == 0 && dy == 0) {
      return math.sqrt(
        math.pow(p.lng - a.lng, 2) + math.pow(p.lat - a.lat, 2),
      );
    }

    final t =
        ((p.lng - a.lng) * dx + (p.lat - a.lat) * dy) / (dx * dx + dy * dy);
    final clamped = t.clamp(0.0, 1.0);
    final projX = a.lng + clamped * dx;
    final projY = a.lat + clamped * dy;
    return math.sqrt(
      math.pow(p.lng - projX, 2) + math.pow(p.lat - projY, 2),
    );
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
