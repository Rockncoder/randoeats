import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/screens/region_draw/region_draw_controller.dart';
import 'package:randoeats/services/geo_utils.dart';

void main() {
  group('RegionDrawController', () {
    late RegionDrawController controller;
    late int notifications;

    setUp(() {
      controller = RegionDrawController(simplifyTolerance: 0.01)
        ..addListener(() => notifications++);
      notifications = 0;
    });

    tearDown(() => controller.dispose());

    test('starts empty and not drawing', () {
      expect(controller.isDrawing, isFalse);
      expect(controller.points, isEmpty);
      expect(controller.canSave, isFalse);
    });

    test('startDrawing enters drawing mode and clears, notifying', () {
      controller
        ..startDrawing()
        ..addPoint((lat: 1, lng: 1))
        ..startDrawing();
      expect(controller.isDrawing, isTrue);
      expect(controller.points, isEmpty);
      expect(notifications, greaterThan(0));
    });

    test('addPoint is ignored when not drawing', () {
      controller.addPoint((lat: 1, lng: 1));
      expect(controller.points, isEmpty);
    });

    test('addPoint appends while drawing', () {
      controller
        ..startDrawing()
        ..addPoint((lat: 0, lng: 0))
        ..addPoint((lat: 0, lng: 1));
      expect(controller.points, [(lat: 0, lng: 0), (lat: 0, lng: 1)]);
    });

    test('points getter is unmodifiable', () {
      controller
        ..startDrawing()
        ..addPoint((lat: 0, lng: 0));
      expect(
        () => controller.points.add((lat: 9, lng: 9)),
        throwsUnsupportedError,
      );
    });

    test('finishDrawing simplifies a noisy path and enables save', () {
      // Many near-collinear points along an L shape.
      const path = <LatLngPoint>[
        (lat: 0, lng: 0),
        (lat: 0, lng: 1),
        (lat: 0, lng: 2),
        (lat: 0, lng: 3),
        (lat: 0, lng: 4),
        (lat: 3, lng: 4),
      ];
      controller
        ..startDrawing()
        ..addPoints(path)
        ..finishDrawing();

      expect(controller.isDrawing, isFalse);
      expect(controller.canSave, isTrue);
      expect(controller.points.length, lessThan(path.length));
    });

    test('addPoints is ignored when not drawing', () {
      controller.addPoints(const [(lat: 0, lng: 0), (lat: 1, lng: 1)]);
      expect(controller.points, isEmpty);
    });

    test('finishDrawing leaves a too-short path untouched', () {
      controller
        ..startDrawing()
        ..addPoint((lat: 0, lng: 0))
        ..addPoint((lat: 1, lng: 1))
        ..finishDrawing();
      expect(controller.isDrawing, isFalse);
      expect(controller.points.length, 2);
      expect(controller.canSave, isFalse);
    });

    test('clear resets everything', () {
      controller
        ..startDrawing()
        ..addPoint((lat: 0, lng: 0))
        ..addPoint((lat: 1, lng: 1))
        ..addPoint((lat: 2, lng: 0))
        ..clear();
      expect(controller.isDrawing, isFalse);
      expect(controller.points, isEmpty);
      expect(controller.canSave, isFalse);
    });
  });
}
