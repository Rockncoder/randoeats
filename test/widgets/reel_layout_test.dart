import 'package:flutter_test/flutter_test.dart';
import 'package:randoeats/models/models.dart';
import 'package:randoeats/widgets/reel_layout.dart';

void main() {
  group('ReelLayout.columnsForWidth', () {
    test('phone widths get 1 column', () {
      expect(ReelLayout.columnsForWidth(390), 1);
      expect(ReelLayout.columnsForWidth(0), 1);
      expect(ReelLayout.columnsForWidth(-5), 1);
      expect(ReelLayout.columnsForWidth(double.infinity), 1);
    });

    test('tablet portrait gets 2 columns', () {
      expect(ReelLayout.columnsForWidth(768), 2);
      expect(ReelLayout.columnsForWidth(1024), 3); // 1024/340 = 3.01 -> 3
    });

    test('clamps to maxColumns', () {
      expect(ReelLayout.columnsForWidth(4000), 3);
      expect(ReelLayout.columnsForWidth(4000, maxColumns: 4), 4);
    });

    test('is driven purely by width / target (no device assumptions)', () {
      // Just over 2x target -> 2; just over 3x -> 3.
      expect(ReelLayout.columnsForWidth(ReelLayout.targetReelWidth * 2 + 1), 2);
      expect(ReelLayout.columnsForWidth(ReelLayout.targetReelWidth * 3 + 1), 3);
      expect(ReelLayout.columnsForWidth(ReelLayout.targetReelWidth - 1), 1);
    });
  });

  group('ReelLayout.buildReels', () {
    List<Restaurant> makeRestaurants(int n) => List.generate(
      n,
      (i) => Restaurant(
        placeId: 'p$i',
        name: 'R$i',
        address: 'addr $i',
        latitude: 0,
        longitude: 0,
      ),
    );

    test('fills columns x rows with unique restaurants when enough', () {
      final reels = ReelLayout.buildReels(
        makeRestaurants(12),
        columns: 3,
        rows: 4,
      );
      expect(reels, hasLength(3));
      expect(reels.every((r) => r.length == 4), isTrue);
      // 12 distinct across 3x4.
      final all = reels.expand((r) => r).map((r) => r.placeId).toSet();
      expect(all, hasLength(12));
    });

    test('repeats restaurants to fill when too few (duplicates allowed)', () {
      final reels = ReelLayout.buildReels(
        makeRestaurants(2),
        columns: 3,
        rows: 2,
      );
      // 6 cells filled from 2 restaurants, cycling.
      final flat = reels.expand((r) => r).map((r) => r.placeId).toList();
      expect(flat, hasLength(6));
      expect(flat, ['p0', 'p1', 'p0', 'p1', 'p0', 'p1']);
    });

    test('returns empty reels for empty input', () {
      final reels = ReelLayout.buildReels(const [], columns: 2, rows: 3);
      expect(reels, hasLength(2));
      expect(reels.every((r) => r.isEmpty), isTrue);
    });

    test('single column (phone) is the current single-reel case', () {
      final reels = ReelLayout.buildReels(
        makeRestaurants(5),
        columns: 1,
        rows: 5,
      );
      expect(reels, hasLength(1));
      expect(reels.first.map((r) => r.placeId), ['p0', 'p1', 'p2', 'p3', 'p4']);
    });
  });
}
