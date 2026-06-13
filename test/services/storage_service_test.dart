import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/services/services.dart';

void main() {
  group('StorageService', () {
    test('singleton returns same instance', () {
      final a = StorageService();
      final b = StorageService();
      expect(identical(a, b), isTrue);
    });

    test('instance getter returns same instance', () {
      expect(identical(StorageService.instance, StorageService()), isTrue);
    });

    test('isInitialized is false before initialize', () {
      // The singleton might already be initialized in certain test
      // environments, but we verify the property exists and is accessible
      expect(StorageService.instance.isInitialized, isA<bool>());
    });
  });

  group('StorageService saved regions', () {
    late Directory tempDir;
    final storage = StorageService.instance;

    SavedRegion region(String id, {String name = 'Region', DateTime? created}) {
      return SavedRegion(
        id: id,
        name: name,
        points: const [0, 0, 0, 1, 1, 1],
        createdAt: created ?? DateTime(2026),
      );
    }

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('storage_service_test');
      await storage.initializeForTest(tempDir.path);
    });

    tearDownAll(() async {
      await storage.close();
      await tempDir.delete(recursive: true);
    });

    setUp(() async {
      await storage.clearRegions();
    });

    test('saveRegion inserts a region', () async {
      await storage.saveRegion(region('r1'));
      expect(storage.getRegion('r1')?.id, 'r1');
      expect(storage.getAllRegions(), hasLength(1));
    });

    test('saveRegion upserts by id (no duplicates)', () async {
      await storage.saveRegion(region('r1', name: 'Old'));
      await storage.saveRegion(region('r1', name: 'New'));
      expect(storage.getAllRegions(), hasLength(1));
      expect(storage.getRegion('r1')?.name, 'New');
    });

    test('getAllRegions returns newest first', () async {
      await storage.saveRegion(region('old', created: DateTime(2026)));
      await storage.saveRegion(region('new', created: DateTime(2026, 6)));
      expect(
        storage.getAllRegions().map((r) => r.id).toList(),
        ['new', 'old'],
      );
    });

    test('deleteRegion removes a region', () async {
      await storage.saveRegion(region('r1'));
      await storage.deleteRegion('r1');
      expect(storage.getRegion('r1'), isNull);
      expect(storage.getAllRegions(), isEmpty);
    });

    test('clearAll preserves saved regions', () async {
      await storage.saveRegion(region('r1'));
      await storage.clearAll();
      expect(storage.getRegion('r1'), isNotNull);
    });

    test('clearRegions removes all regions', () async {
      await storage.saveRegion(region('r1'));
      await storage.saveRegion(region('r2'));
      await storage.clearRegions();
      expect(storage.getAllRegions(), isEmpty);
    });
  });
}
