import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/models/models.dart';

void main() {
  group('RecentPick', () {
    test('supports value equality', () {
      final dateTime = DateTime(2024, 1, 15, 12);
      final a = RecentPick(placeId: 'place_1', pickedAt: dateTime);
      final b = RecentPick(placeId: 'place_1', pickedAt: dateTime);

      expect(a, equals(b));
    });

    test('props are correct', () {
      final dateTime = DateTime(2024, 1, 15, 12);
      final pick = RecentPick(placeId: 'place_1', pickedAt: dateTime);

      expect(pick.props, ['place_1', dateTime]);
    });

    test('two picks with different placeIds are not equal', () {
      final dateTime = DateTime(2024, 1, 15, 12);
      final a = RecentPick(placeId: 'place_1', pickedAt: dateTime);
      final b = RecentPick(placeId: 'place_2', pickedAt: dateTime);

      expect(a, isNot(equals(b)));
    });

    test('two picks with different dates are not equal', () {
      final a = RecentPick(
        placeId: 'place_1',
        pickedAt: DateTime(2024, 1, 15),
      );
      final b = RecentPick(
        placeId: 'place_1',
        pickedAt: DateTime(2024, 1, 16),
      );

      expect(a, isNot(equals(b)));
    });

    group('factory now', () {
      test('creates a pick with current time', () {
        final before = DateTime.now();
        final pick = RecentPick.now('place_1');
        final after = DateTime.now();

        expect(pick.placeId, 'place_1');
        expect(
          pick.pickedAt.isAfter(before) || pick.pickedAt == before,
          isTrue,
        );
        expect(
          pick.pickedAt.isBefore(after) || pick.pickedAt == after,
          isTrue,
        );
      });
    });

    group('shouldHide', () {
      test('returns true when within hide period', () {
        final pick = RecentPick(
          placeId: 'place_1',
          pickedAt: DateTime.now().subtract(const Duration(days: 3)),
        );

        expect(pick.shouldHide(hideDays: 7), isTrue);
      });

      test('returns false when past hide period', () {
        final pick = RecentPick(
          placeId: 'place_1',
          pickedAt: DateTime.now().subtract(const Duration(days: 10)),
        );

        expect(pick.shouldHide(hideDays: 7), isFalse);
      });

      test('returns true when picked today with any hide days', () {
        final pick = RecentPick.now('place_1');

        expect(pick.shouldHide(hideDays: 1), isTrue);
      });

      test('returns false when exactly at hide boundary', () {
        final pick = RecentPick(
          placeId: 'place_1',
          pickedAt: DateTime.now().subtract(const Duration(days: 7)),
        );

        // At exactly 7 days, now is NOT before hideUntil, so it is false
        expect(pick.shouldHide(hideDays: 7), isFalse);
      });
    });

    group('daysSincePick', () {
      test('returns 0 for today', () {
        final pick = RecentPick.now('place_1');
        expect(pick.daysSincePick, 0);
      });

      test('returns correct days for past pick', () {
        final pick = RecentPick(
          placeId: 'place_1',
          pickedAt: DateTime.now().subtract(const Duration(days: 5)),
        );

        expect(pick.daysSincePick, 5);
      });
    });
  });
}
