import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/services/geo_utils.dart';

void main() {
  group('GeoUtils.isPointInPolygon', () {
    // A unit square from (0,0) to (1,1) — note (lat, lng).
    const square = <LatLngPoint>[
      (lat: 0, lng: 0),
      (lat: 0, lng: 1),
      (lat: 1, lng: 1),
      (lat: 1, lng: 0),
    ];

    test('returns true for a point clearly inside', () {
      expect(GeoUtils.isPointInPolygon(0.5, 0.5, square), isTrue);
    });

    test('returns false for a point clearly outside', () {
      expect(GeoUtils.isPointInPolygon(2, 2, square), isFalse);
      expect(GeoUtils.isPointInPolygon(-0.5, 0.5, square), isFalse);
    });

    test('returns false for fewer than three vertices', () {
      expect(
        GeoUtils.isPointInPolygon(0.5, 0.5, const [
          (lat: 0, lng: 0),
          (lat: 1, lng: 1),
        ]),
        isFalse,
      );
    });

    test('handles a concave polygon', () {
      // An arrow/chevron-ish concave shape.
      const concave = <LatLngPoint>[
        (lat: 0, lng: 0),
        (lat: 0, lng: 4),
        (lat: 4, lng: 4),
        (lat: 2, lng: 2), // notch pulled inward
        (lat: 4, lng: 0),
      ];
      // Point in the lower-middle notch area should be outside.
      expect(GeoUtils.isPointInPolygon(3.5, 2, concave), isFalse);
      // Point in a solid lobe should be inside.
      expect(GeoUtils.isPointInPolygon(1, 1, concave), isTrue);
    });
  });

  group('GeoUtils.boundingCircle', () {
    test('centers on the centroid of the vertices', () {
      const square = <LatLngPoint>[
        (lat: 0, lng: 0),
        (lat: 0, lng: 2),
        (lat: 2, lng: 2),
        (lat: 2, lng: 0),
      ];
      final circle = GeoUtils.boundingCircle(square);
      expect(circle.lat, closeTo(1, 1e-9));
      expect(circle.lng, closeTo(1, 1e-9));
    });

    test('radius covers every vertex (with padding)', () {
      const square = <LatLngPoint>[
        (lat: 0, lng: 0),
        (lat: 0, lng: 2),
        (lat: 2, lng: 2),
        (lat: 2, lng: 0),
      ];
      final circle = GeoUtils.boundingCircle(square);
      for (final v in square) {
        final d = GeoUtils.distanceMeters(circle.lat, circle.lng, v.lat, v.lng);
        expect(d, lessThanOrEqualTo(circle.radiusMeters));
      }
    });

    test('padding increases the radius', () {
      const square = <LatLngPoint>[
        (lat: 0, lng: 0),
        (lat: 0, lng: 2),
        (lat: 2, lng: 2),
        (lat: 2, lng: 0),
      ];
      final tight = GeoUtils.boundingCircle(square, padding: 1);
      final padded = GeoUtils.boundingCircle(square, padding: 1.2);
      expect(padded.radiusMeters, greaterThan(tight.radiusMeters));
    });

    test('throws on an empty polygon', () {
      expect(
        () => GeoUtils.boundingCircle(const []),
        throwsArgumentError,
      );
    });
  });

  group('GeoUtils.distanceMeters', () {
    test('is zero for identical points', () {
      expect(GeoUtils.distanceMeters(33.78, -117.85, 33.78, -117.85), 0);
    });

    test('matches a known short distance (~1 deg lat ≈ 111km)', () {
      final d = GeoUtils.distanceMeters(0, 0, 1, 0);
      expect(d, closeTo(111195, 500));
    });
  });

  group('GeoUtils.simplifyPolygon', () {
    test('returns small lists unchanged', () {
      const pts = <LatLngPoint>[
        (lat: 0, lng: 0),
        (lat: 0, lng: 1),
        (lat: 1, lng: 1),
      ];
      expect(GeoUtils.simplifyPolygon(pts), pts);
    });

    test('drops near-collinear intermediate points', () {
      // Many points along a nearly straight line plus a clear corner.
      const pts = <LatLngPoint>[
        (lat: 0, lng: 0),
        (lat: 0, lng: 1),
        (lat: 0, lng: 2),
        (lat: 0, lng: 3),
        (lat: 0, lng: 4),
        (lat: 3, lng: 4),
      ];
      final simplified = GeoUtils.simplifyPolygon(pts, tolerance: 0.01);
      expect(simplified.length, lessThan(pts.length));
      // Endpoints are always preserved.
      expect(simplified.first, pts.first);
      expect(simplified.last, pts.last);
    });

    test('keeps points that exceed the tolerance', () {
      const pts = <LatLngPoint>[
        (lat: 0, lng: 0),
        (lat: 5, lng: 1), // big deviation
        (lat: 0, lng: 2),
        (lat: 5, lng: 3),
        (lat: 0, lng: 4),
      ];
      final simplified = GeoUtils.simplifyPolygon(pts, tolerance: 0.01);
      expect(simplified.length, pts.length);
    });
  });
}
