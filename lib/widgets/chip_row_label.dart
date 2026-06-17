import 'package:flutter/material.dart';
import 'package:randoeats/config/config.dart';

/// A compact, non-interactive leading label for a horizontal chip row.
///
/// Used to tell the results screen's two chip rows apart — one controls *where*
/// to search ("Area"), the other *what* to search for ("Filters") — which
/// otherwise render with identical chip styling.
class ChipRowLabel extends StatelessWidget {
  /// Creates a [ChipRowLabel].
  const ChipRowLabel({required this.icon, required this.label, super.key});

  /// Leading icon shown before the label text.
  final IconData icon;

  /// Short label describing what the row's chips control.
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: GoogieColors.deepTeal),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: GoogieColors.deepTeal,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
