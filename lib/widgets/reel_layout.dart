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

  /// Distributes [restaurants] into [columns] reels of [rows] cells each.
  ///
  /// When there are fewer restaurants than cells, restaurants repeat to fill
  /// (duplicates across cells are allowed by design). Returns `columns` lists,
  /// each of length `rows` (empty lists when [restaurants] is empty).
  static List<List<Restaurant>> buildReels(
    List<Restaurant> restaurants, {
    required int columns,
    required int rows,
  }) {
    final reels = List.generate(
      columns,
      (_) => <Restaurant>[],
      growable: false,
    );
    if (restaurants.isEmpty || columns <= 0 || rows <= 0) return reels;

    var index = 0;
    for (var c = 0; c < columns; c++) {
      for (var r = 0; r < rows; r++) {
        reels[c].add(restaurants[index % restaurants.length]);
        index++;
      }
    }
    return reels;
  }
}
