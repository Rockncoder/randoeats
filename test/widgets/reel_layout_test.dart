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

    test('distributes ALL restaurants across columns (strided, no dupes)', () {
      final reels = ReelLayout.buildReels(makeRestaurants(12), columns: 3);
      expect(reels, hasLength(3));
      expect(reels.every((r) => r.length == 4), isTrue);
      // Every restaurant present exactly once.
      final all = reels.expand((r) => r).map((r) => r.placeId).toList();
      expect(all.toSet(), hasLength(12));
      // Strided: column c holds restaurants c, c+3, c+6, ...
      expect(reels[0].map((r) => r.placeId), ['p0', 'p3', 'p6', 'p9']);
      expect(reels[1].map((r) => r.placeId), ['p1', 'p4', 'p7', 'p10']);
      expect(reels[2].map((r) => r.placeId), ['p2', 'p5', 'p8', 'p11']);
    });

    test('fewer restaurants than columns leaves trailing columns empty', () {
      final reels = ReelLayout.buildReels(makeRestaurants(2), columns: 3);
      expect(reels.map((r) => r.length), [1, 1, 0]);
      expect(reels[0].first.placeId, 'p0');
      expect(reels[1].first.placeId, 'p1');
    });

    test('returns empty reels for empty input', () {
      final reels = ReelLayout.buildReels(const [], columns: 2);
      expect(reels, hasLength(2));
      expect(reels.every((r) => r.isEmpty), isTrue);
    });

    test('single column (phone) holds the whole list in order', () {
      final reels = ReelLayout.buildReels(makeRestaurants(5), columns: 1);
      expect(reels, hasLength(1));
      expect(reels.first.map((r) => r.placeId), ['p0', 'p1', 'p2', 'p3', 'p4']);
    });
  });
}
