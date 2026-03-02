import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/models/models.dart';

void main() {
  group('UserRating', () {
    test('supports value equality', () {
      final dateTime = DateTime(2024, 1, 15, 12);
      final a = UserRating(
        placeId: 'place_1',
        rating: RatingType.thumbsUp,
        ratedAt: dateTime,
      );
      final b = UserRating(
        placeId: 'place_1',
        rating: RatingType.thumbsUp,
        ratedAt: dateTime,
      );

      expect(a, equals(b));
    });

    test('props are correct', () {
      final dateTime = DateTime(2024, 1, 15, 12);
      final rating = UserRating(
        placeId: 'place_1',
        rating: RatingType.thumbsUp,
        ratedAt: dateTime,
      );

      expect(rating.props, ['place_1', RatingType.thumbsUp, dateTime]);
    });

    test('two ratings with different placeIds are not equal', () {
      final dateTime = DateTime(2024, 1, 15, 12);
      final a = UserRating(
        placeId: 'place_1',
        rating: RatingType.thumbsUp,
        ratedAt: dateTime,
      );
      final b = UserRating(
        placeId: 'place_2',
        rating: RatingType.thumbsUp,
        ratedAt: dateTime,
      );

      expect(a, isNot(equals(b)));
    });

    test('two ratings with different types are not equal', () {
      final dateTime = DateTime(2024, 1, 15, 12);
      final a = UserRating(
        placeId: 'place_1',
        rating: RatingType.thumbsUp,
        ratedAt: dateTime,
      );
      final b = UserRating(
        placeId: 'place_1',
        rating: RatingType.thumbsDown,
        ratedAt: dateTime,
      );

      expect(a, isNot(equals(b)));
    });

    group('factory thumbsUp', () {
      test('creates a thumbs up rating with current time', () {
        final before = DateTime.now();
        final rating = UserRating.thumbsUp('place_1');
        final after = DateTime.now();

        expect(rating.placeId, 'place_1');
        expect(rating.rating, RatingType.thumbsUp);
        expect(rating.isPositive, isTrue);
        expect(rating.isNegative, isFalse);
        expect(
          rating.ratedAt.isAfter(before) || rating.ratedAt == before,
          isTrue,
        );
        expect(
          rating.ratedAt.isBefore(after) || rating.ratedAt == after,
          isTrue,
        );
      });
    });

    group('factory thumbsDown', () {
      test('creates a thumbs down rating with current time', () {
        final before = DateTime.now();
        final rating = UserRating.thumbsDown('place_1');
        final after = DateTime.now();

        expect(rating.placeId, 'place_1');
        expect(rating.rating, RatingType.thumbsDown);
        expect(rating.isPositive, isFalse);
        expect(rating.isNegative, isTrue);
        expect(
          rating.ratedAt.isAfter(before) || rating.ratedAt == before,
          isTrue,
        );
        expect(
          rating.ratedAt.isBefore(after) || rating.ratedAt == after,
          isTrue,
        );
      });
    });

    group('isPositive', () {
      test('returns true for thumbs up', () {
        final rating = UserRating(
          placeId: 'p1',
          rating: RatingType.thumbsUp,
          ratedAt: DateTime.now(),
        );
        expect(rating.isPositive, isTrue);
      });

      test('returns false for thumbs down', () {
        final rating = UserRating(
          placeId: 'p1',
          rating: RatingType.thumbsDown,
          ratedAt: DateTime.now(),
        );
        expect(rating.isPositive, isFalse);
      });
    });

    group('isNegative', () {
      test('returns true for thumbs down', () {
        final rating = UserRating(
          placeId: 'p1',
          rating: RatingType.thumbsDown,
          ratedAt: DateTime.now(),
        );
        expect(rating.isNegative, isTrue);
      });

      test('returns false for thumbs up', () {
        final rating = UserRating(
          placeId: 'p1',
          rating: RatingType.thumbsUp,
          ratedAt: DateTime.now(),
        );
        expect(rating.isNegative, isFalse);
      });
    });
  });

  group('RatingType', () {
    test('thumbsUp has correct storage value', () {
      expect(RatingType.thumbsUp.storageValue, 'thumbs_up');
    });

    test('thumbsDown has correct storage value', () {
      expect(RatingType.thumbsDown.storageValue, 'thumbs_down');
    });

    test('toStorage returns storage value', () {
      expect(RatingType.thumbsUp.toStorage(), 'thumbs_up');
      expect(RatingType.thumbsDown.toStorage(), 'thumbs_down');
    });

    group('fromStorage', () {
      test('parses thumbs_up', () {
        expect(RatingType.fromStorage('thumbs_up'), RatingType.thumbsUp);
      });

      test('parses thumbs_down', () {
        expect(RatingType.fromStorage('thumbs_down'), RatingType.thumbsDown);
      });

      test('throws ArgumentError for invalid value', () {
        expect(
          () => RatingType.fromStorage('invalid'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
