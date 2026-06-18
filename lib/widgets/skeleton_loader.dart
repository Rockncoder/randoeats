import 'dart:async';

import 'package:flutter/material.dart';
import 'package:randoeats/config/config.dart';

/// A shimmering list of card-shaped skeletons shown while results load —
/// the M3 alternative to a spinner. Mirrors the rounded, full-bleed cards.
class SkeletonCardList extends StatefulWidget {
  /// Creates a [SkeletonCardList].
  const SkeletonCardList({this.count = 4, super.key});

  /// How many skeleton cards to show.
  final int count;

  @override
  State<SkeletonCardList> createState() => _SkeletonCardListState();
}

class _SkeletonCardListState extends State<SkeletonCardList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void initState() {
    super.initState();
    unawaited(_controller.repeat());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: widget.count,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            size: const Size(double.infinity, 160),
            painter: _SkeletonPainter(
              t: _controller.value,
              base: GoogieColors.chrome.withValues(alpha: 0.28),
              highlight: GoogieColors.cardTint,
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonPainter extends CustomPainter {
  _SkeletonPainter({
    required this.t,
    required this.base,
    required this.highlight,
  });

  final double t;
  final Color base;
  final Color highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(28));
    // Moving highlight band sweeps left -> right.
    final dx = (t * 2 - 0.5) * size.width;
    final shimmer =
        LinearGradient(
          colors: [base, highlight, base],
          stops: const [0.35, 0.5, 0.65],
        ).createShader(
          Rect.fromLTWH(dx - size.width, 0, size.width * 2, size.height),
        );
    canvas
      ..save()
      ..clipRRect(rrect)
      ..drawRect(rect, Paint()..color = base)
      ..drawRect(rect, Paint()..shader = shimmer)
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _SkeletonPainter old) =>
      old.t != t || old.base != base || old.highlight != highlight;
}
