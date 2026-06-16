import 'package:flutter/material.dart';

/// Wraps a horizontally-scrolling child with a soft fade on the trailing edge,
/// hinting that more content scrolls off-screen.
///
/// Uses a [ShaderMask] with [BlendMode.dstIn] so the child's right edge fades
/// to transparent. Purely decorative — it does not affect layout or hit-testing
/// of the underlying scroll view.
class HorizontalScrollFade extends StatelessWidget {
  /// Creates a [HorizontalScrollFade].
  const HorizontalScrollFade({required this.child, super.key});

  /// The scrolling content to fade at its trailing edge.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Colors.white, Colors.white, Colors.transparent],
        stops: [0, 0.92, 1],
      ).createShader(bounds),
      child: child,
    );
  }
}
