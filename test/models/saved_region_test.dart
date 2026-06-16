import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:randoeats/models/models.dart';

void main() {
  group('SavedRegion', () {
    final createdAt = DateTime(2026, 6, 13, 12);

    SavedRegion buildSquare() => SavedRegion(
      id: 'r1',
      name: 'Orange Circle',
      points: const [33.78, -117.85, 33.79, -117.85, 33.79, -117.84],
      createdAt: createdAt,
    );

    test('supports value equality', () {
      expect(buildSquare(), equals(buildSquare()));
    });

    test('differs when any field differs', () {
      expect(buildSquare(), isNot(equals(buildSquare().copyWith(id: 'r2'))));
      expect(
        buildSquare(),
        isNot(equals(buildSquare().copyWith(name: 'Downtown'))),
      );
    });

    test('props expose all fields', () {
      final region = buildSquare();
      expect(region.props, [
        'r1',
        'Orange Circle',
        region.points,
        createdAt,
      ]);
    });

    group('vertices', () {
      test('reads flattened points back as lat/lng pairs', () {
        final region = buildSquare();
        expect(region.vertices, [
          (lat: 33.78, lng: -117.85),
          (lat: 33.79, lng: -117.85),
          (lat: 33.79, lng: -117.84),
        ]);
      });

      test('ignores a trailing unpaired coordinate', () {
        final region = buildSquare().copyWith(points: const [1, 2, 3]);
        expect(region.vertices, [(lat: 1, lng: 2)]);
      });

      test('is empty when there are no points', () {
        expect(buildSquare().copyWith(points: const []).vertices, isEmpty);
      });
    });

    group('fromVertices', () {
      test('flattens lat/lng pairs into points', () {
        final region = SavedRegion.fromVertices(
          id: 'r1',
          name: 'Orange Circle',
          vertices: const [
            (lat: 33.78, lng: -117.85),
            (lat: 33.79, lng: -117.84),
          ],
          createdAt: createdAt,
        );
        expect(region.points, [33.78, -117.85, 33.79, -117.84]);
      });

      test('round-trips through vertices', () {
        const verts = [
          (lat: 1.0, lng: 2.0),
          (lat: 3.0, lng: 4.0),
          (lat: 5.0, lng: 6.0),
        ];
        final region = SavedRegion.fromVertices(
          id: 'r1',
          name: 'n',
          vertices: verts,
          createdAt: createdAt,
        );
        expect(region.vertices, verts);
      });
    });

    group('copyWith', () {
      test('replaces only provided fields', () {
        final region = buildSquare().copyWith(name: 'New Name');
        expect(region.name, 'New Name');
        expect(region.id, 'r1');
        expect(region.points, buildSquare().points);
        expect(region.createdAt, createdAt);
      });
    });

    group('SavedRegionAdapter', () {
      late Directory tempDir;

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('saved_region_test');
        Hive.init(tempDir.path);
        if (!Hive.isAdapterRegistered(7)) {
          Hive.registerAdapter(SavedRegionAdapter());
        }
      });

      tearDown(() async {
        await Hive.deleteFromDisk();
        await tempDir.delete(recursive: true);
      });

      test('has the expected typeId', () {
        expect(SavedRegionAdapter().typeId, 7);
      });

      test('persists and reads back an identical region', () async {
        final box = await Hive.openBox<SavedRegion>('regions_roundtrip');
        final region = buildSquare();
        await box.put(region.id, region);
        await box.close();

        final reopened = await Hive.openBox<SavedRegion>('regions_roundtrip');
        expect(reopened.get('r1'), equals(region));
      });
    });
  });
}
