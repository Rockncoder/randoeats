import 'package:flutter/material.dart';

/// Wraps [child] in a gentle, continuous breathing pulse (subtle scale loop).
///
/// Used to give primary actions a lively Material 3 Expressive feel without a
/// tap. Purely decorative — it does not affect layout or hit-testing.
class Pulse extends StatefulWidget {
  /// Creates a [Pulse].
  const Pulse({
    required this.child,
    this.minScale = 1,
    this.maxScale = 1.03,
    this.duration = const Duration(milliseconds: 1400),
    super.key,
  });

  /// The widget that breathes.
  final Widget child;

  /// Scale at the trough of the pulse.
  final double minScale;

  /// Scale at the peak of the pulse.
  final double maxScale;

  /// Time for one half-cycle (min -> max).
  final Duration duration;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween<double>(
    begin: widget.minScale,
    end: widget.maxScale,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
