import 'package:randoeats/models/models.dart';

/// Pure layout helpers for the responsive multi-reel slot machine.
///
/// Width is *measured* (via `LayoutBuilder` at the call site) and the column
/// count is derived from it — never from device model — so the grid fills the
/// available width on phones, foldables, tablets, and split-screen alike.
abstract final class ReelLayout {
  /// Target width per reel. Columns = floor(availableWidth / this), so cells
  /// stretch to fill the measured width with no leftover gutter.
  static const double targetReelWidth = 340;

  /// Number of reels (columns) for [width], clamped to [1, maxColumns].
  static int columnsForWidth(double width, {int maxColumns = 3}) {
    if (width <= 0 || !width.isFinite) return 1;
    final columns = (width / targetReelWidth).floor();
    return columns.clamp(1, maxColumns);
  }

  /// Distributes ALL [restaurants] across [columns] reels, round-robin
  /// (strided) so every restaurant lands in exactly one column and the columns
  /// stay balanced. No restaurant is dropped and none is duplicated here — each
  /// reel repeats its own cells as needed for the visual fill (see the reel
  /// widget), while selection stays uniform over the distinct restaurants.
  ///
  /// Restaurant `i` goes to column `i % columns`, so the global index `g` maps
  /// to `reels[g % columns][g ~/ columns]`. Returns `columns` lists (some may
  /// be empty when there are fewer restaurants than columns).
  static List<List<Restaurant>> buildReels(
    List<Restaurant> restaurants, {
    required int columns,
  }) {
    final reels = List.generate(
      columns,
      (_) => <Restaurant>[],
      growable: false,
    );
    if (columns <= 0) return reels;
    for (var i = 0; i < restaurants.length; i++) {
      reels[i % columns].add(restaurants[i]);
    }
    return reels;
  }
}
