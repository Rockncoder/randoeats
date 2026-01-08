import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Result of a location request.
sealed class LocationResult {
  const LocationResult();
}

/// Location successfully obtained.
class LocationSuccess extends LocationResult {
  /// Creates a [LocationSuccess] with the given position.
  const LocationSuccess(this.position);

  /// The user's current position.
  final Position position;

  /// Latitude coordinate.
  double get latitude => position.latitude;

  /// Longitude coordinate.
  double get longitude => position.longitude;
}

/// Location permission was denied.
class LocationPermissionDenied extends LocationResult {
  /// Creates a [LocationPermissionDenied] result.
  const LocationPermissionDenied({this.isPermanent = false});

  /// Whether the denial is permanent (user selected "Don't ask again").
  final bool isPermanent;
}

/// Location services are disabled on the device.
class LocationServicesDisabled extends LocationResult {
  /// Creates a [LocationServicesDisabled] result.
  const LocationServicesDisabled();
}

/// An error occurred while getting location.
class LocationError extends LocationResult {
  /// Creates a [LocationError] with the given message.
  const LocationError(this.message);

  /// Error message.
  final String message;
}

/// Service for getting the user's location.
class LocationService {
  /// Gets the singleton instance of [LocationService].
  factory LocationService() => _instance;

  LocationService._internal();

  static final LocationService _instance = LocationService._internal();

  /// Gets the singleton instance of [LocationService].
  static LocationService get instance => _instance;

  Position? _lastKnownPosition;

  /// The last known position, if available.
  Position? get lastKnownPosition => _lastKnownPosition;

  /// Checks if location services are enabled.
  Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  /// Checks the current location permission status.
  Future<PermissionStatus> checkPermission() async {
    return Permission.location.status;
  }

  /// Requests location permission from the user.
  Future<PermissionStatus> requestPermission() async {
    return Permission.location.request();
  }

  /// Opens the app settings page for the user to enable permissions.
  Future<bool> openSettings() async {
    return openAppSettings();
  }

  /// Gets the current location.
  ///
  /// Returns a [LocationResult] indicating success or the type of failure.
  Future<LocationResult> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationServicesDisabled();
      }

      // Check permission status
      var permission = await checkPermission();

      // Request permission if not granted
      if (permission.isDenied) {
        permission = await requestPermission();
      }

      // Handle permission result
      if (permission.isDenied) {
        return const LocationPermissionDenied();
      }

      if (permission.isPermanentlyDenied) {
        return const LocationPermissionDenied(isPermanent: true);
      }

      // Get the current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeout,
        ),
      );

      _lastKnownPosition = position;
      debugPrint(
        'Location obtained: ${position.latitude}, ${position.longitude}',
      );

      return LocationSuccess(position);
    } on LocationServiceDisabledException {
      return const LocationServicesDisabled();
    } on PermissionDeniedException {
      return const LocationPermissionDenied();
    } on Exception catch (e) {
      debugPrint('Location error: $e');
      return LocationError(e.toString());
    }
  }

  /// Gets the last known position without requesting a new one.
  ///
  /// Returns null if no position has been obtained yet.
  Future<Position?> getLastKnownPosition() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        _lastKnownPosition = position;
      }
      return position;
    } on Exception catch (e) {
      debugPrint('Error getting last known position: $e');
      return null;
    }
  }

  /// Calculates the distance in meters between two coordinates.
  double distanceBetween({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}
