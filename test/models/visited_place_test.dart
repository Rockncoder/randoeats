import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/models/models.dart';

void main() {
  group('VisitedPlace', () {
    test('supports value equality', () {
      final dateTime = DateTime(2024, 1, 15, 12);
      final a = VisitedPlace(
        placeId: 'place_1',
        visitCount: 3,
        lastVisitedAt: dateTime,
      );
      final b = VisitedPlace(
        placeId: 'place_1',
        visitCount: 3,
        lastVisitedAt: dateTime,
      );

      expect(a, equals(b));
    });

    test('props are correct', () {
      final dateTime = DateTime(2024, 1, 15, 12);
      final visited = VisitedPlace(
        placeId: 'place_1',
        visitCount: 3,
        lastVisitedAt: dateTime,
      );

      expect(visited.props, ['place_1', 3, dateTime]);
    });

    test('two visited places with different placeIds are not equal', () {
      final dateTime = DateTime(2024, 1, 15, 12);
      final a = VisitedPlace(
        placeId: 'place_1',
        visitCount: 1,
        lastVisitedAt: dateTime,
      );
      final b = VisitedPlace(
        placeId: 'place_2',
        visitCount: 1,
        lastVisitedAt: dateTime,
      );

      expect(a, isNot(equals(b)));
    });

    test('two visited places with different visit counts are not equal', () {
      final dateTime = DateTime(2024, 1, 15, 12);
      final a = VisitedPlace(
        placeId: 'place_1',
        visitCount: 1,
        lastVisitedAt: dateTime,
      );
      final b = VisitedPlace(
        placeId: 'place_1',
        visitCount: 2,
        lastVisitedAt: dateTime,
      );

      expect(a, isNot(equals(b)));
    });

    group('factory firstVisit', () {
      test('creates a first visit with count of 1', () {
        final before = DateTime.now();
        final visited = VisitedPlace.firstVisit('place_1');
        final after = DateTime.now();

        expect(visited.placeId, 'place_1');
        expect(visited.visitCount, 1);
        expect(
          visited.lastVisitedAt.isAfter(before) ||
              visited.lastVisitedAt == before,
          isTrue,
        );
        expect(
          visited.lastVisitedAt.isBefore(after) ||
              visited.lastVisitedAt == after,
          isTrue,
        );
      });
    });

    group('incrementVisit', () {
      test('increments visit count', () {
        final visited = VisitedPlace(
          placeId: 'place_1',
          visitCount: 3,
          lastVisitedAt: DateTime(2024, 1, 15),
        );

        final incremented = visited.incrementVisit();

        expect(incremented.placeId, 'place_1');
        expect(incremented.visitCount, 4);
      });

      test('updates lastVisitedAt to current time', () {
        final visited = VisitedPlace(
          placeId: 'place_1',
          visitCount: 1,
          lastVisitedAt: DateTime(2024),
        );

        final before = DateTime.now();
        final incremented = visited.incrementVisit();
        final after = DateTime.now();

        expect(
          incremented.lastVisitedAt.isAfter(before) ||
              incremented.lastVisitedAt == before,
          isTrue,
        );
        expect(
          incremented.lastVisitedAt.isBefore(after) ||
              incremented.lastVisitedAt == after,
          isTrue,
        );
      });

      test('preserves placeId', () {
        final visited = VisitedPlace(
          placeId: 'place_42',
          visitCount: 10,
          lastVisitedAt: DateTime(2024),
        );

        final incremented = visited.incrementVisit();
        expect(incremented.placeId, 'place_42');
      });
    });
  });
}
