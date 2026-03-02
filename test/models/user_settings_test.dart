import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/models/models.dart';

void main() {
  group('UserSettings', () {
    test('has correct default values', () {
      const settings = UserSettings();

      expect(settings.hideDaysAfterPick, UserSettings.defaultHideDays);
      expect(settings.searchRadiusMeters, UserSettings.defaultSearchRadius);
      expect(settings.includeOpenOnly, isTrue);
      expect(settings.maxResults, UserSettings.defaultMaxResults);
      expect(settings.distanceUnit, DistanceUnit.miles);
      expect(settings.bannedCategories, isEmpty);
    });

    test('supports value equality', () {
      const a = UserSettings();
      const b = UserSettings();

      expect(a, equals(b));
    });

    test('props are correct', () {
      const settings = UserSettings();

      expect(settings.props, [
        UserSettings.defaultHideDays,
        UserSettings.defaultSearchRadius,
        true,
        UserSettings.defaultMaxResults,
        DistanceUnit.miles,
        <String>{},
      ]);
    });

    test('static constants are correct', () {
      expect(UserSettings.defaultHideDays, 7);
      expect(UserSettings.minHideDays, 1);
      expect(UserSettings.maxHideDays, 30);
      expect(UserSettings.defaultSearchRadius, 1500);
      expect(UserSettings.minSearchRadius, 500);
      expect(UserSettings.maxSearchRadius, 10000);
      expect(UserSettings.defaultMaxResults, 20);
      expect(UserSettings.minMaxResults, 5);
      expect(UserSettings.maxMaxResults, 50);
    });

    group('copyWith', () {
      test('returns identical object when no parameters specified', () {
        const settings = UserSettings(
          hideDaysAfterPick: 14,
          searchRadiusMeters: 3000,
          includeOpenOnly: false,
          maxResults: 10,
          distanceUnit: DistanceUnit.kilometers,
          bannedCategories: {'cafe'},
        );

        final copy = settings.copyWith();

        expect(copy, equals(settings));
      });

      test('updates hideDaysAfterPick', () {
        const settings = UserSettings();
        final updated = settings.copyWith(hideDaysAfterPick: 14);

        expect(updated.hideDaysAfterPick, 14);
        expect(updated.searchRadiusMeters, settings.searchRadiusMeters);
      });

      test('updates searchRadiusMeters', () {
        const settings = UserSettings();
        final updated = settings.copyWith(searchRadiusMeters: 5000);

        expect(updated.searchRadiusMeters, 5000);
      });

      test('updates includeOpenOnly', () {
        const settings = UserSettings();
        final updated = settings.copyWith(includeOpenOnly: false);

        expect(updated.includeOpenOnly, isFalse);
      });

      test('updates maxResults', () {
        const settings = UserSettings();
        final updated = settings.copyWith(maxResults: 30);

        expect(updated.maxResults, 30);
      });

      test('updates distanceUnit', () {
        const settings = UserSettings();
        final updated = settings.copyWith(
          distanceUnit: DistanceUnit.kilometers,
        );

        expect(updated.distanceUnit, DistanceUnit.kilometers);
      });

      test('updates bannedCategories', () {
        const settings = UserSettings();
        final updated = settings.copyWith(bannedCategories: {'cafe', 'bar'});

        expect(updated.bannedCategories, {'cafe', 'bar'});
      });
    });

    test('two settings with different values are not equal', () {
      const a = UserSettings(hideDaysAfterPick: 3);
      const b = UserSettings(hideDaysAfterPick: 14);

      expect(a, isNot(equals(b)));
    });
  });

  group('DistanceUnit', () {
    test('miles has correct abbreviation', () {
      expect(DistanceUnit.miles.abbreviation, 'mi');
    });

    test('kilometers has correct abbreviation', () {
      expect(DistanceUnit.kilometers.abbreviation, 'km');
    });

    test('format converts meters to miles', () {
      final result = DistanceUnit.miles.format(1609.34);
      expect(result, '1.0 mi');
    });

    test('format converts meters to kilometers', () {
      final result = DistanceUnit.kilometers.format(1000);
      expect(result, '1.0 km');
    });

    test('format handles large distances in miles', () {
      final result = DistanceUnit.miles.format(16093.4);
      expect(result, '10.0 mi');
    });

    test('format handles small distances in kilometers', () {
      final result = DistanceUnit.kilometers.format(500);
      expect(result, '0.5 km');
    });
  });
}
