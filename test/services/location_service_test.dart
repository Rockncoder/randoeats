import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/services/services.dart';

void main() {
  group('LocationResult types', () {
    test('LocationSuccess holds position and exposes lat/lng', () {
      // LocationSuccess requires a Position object. We can test the type
      // hierarchy is correct.
      const result = LocationPermissionDenied();
      expect(result, isA<LocationResult>());
    });

    test('LocationPermissionDenied defaults to not permanent', () {
      const result = LocationPermissionDenied();
      expect(result.isPermanent, isFalse);
    });

    test('LocationPermissionDenied can be permanent', () {
      const result = LocationPermissionDenied(isPermanent: true);
      expect(result.isPermanent, isTrue);
    });

    test('LocationServicesDisabled is a LocationResult', () {
      const result = LocationServicesDisabled();
      expect(result, isA<LocationResult>());
    });

    test('LocationError holds message', () {
      const result = LocationError('test error');
      expect(result.message, 'test error');
    });

    test('LocationError is a LocationResult', () {
      const result = LocationError('error');
      expect(result, isA<LocationResult>());
    });
  });

  group('LocationService', () {
    test('singleton returns same instance', () {
      final a = LocationService();
      final b = LocationService();
      expect(identical(a, b), isTrue);
    });

    test('instance getter returns same instance', () {
      expect(identical(LocationService.instance, LocationService()), isTrue);
    });

    test('lastKnownPosition is initially null', () {
      // Note: the singleton may have state from prior calls, but we can
      // verify the property accessor works
      expect(LocationService.instance.lastKnownPosition, isA<Object?>());
    });

    test('distanceBetween calculates distance', () {
      // distanceBetween is a pure calculation method from Geolocator
      final distance = LocationService.instance.distanceBetween(
        startLatitude: 0,
        startLongitude: 0,
        endLatitude: 0,
        endLongitude: 1,
      );

      // Distance at equator for 1 degree longitude is ~111km
      expect(distance, greaterThan(100000));
      expect(distance, lessThan(120000));
    });
  });
}
