import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:randoeats/config/config.dart';

/// A large, Googie-styled button for triggering the slot machine animation.
///
/// The round badge logo floats over the listings on a soft frosted-blur disc
/// so it stands out against busy restaurant photos. Tapping spins the logo
/// (the blur stays put).
class RandoEatsButton extends StatefulWidget {
  /// Creates a [RandoEatsButton].
  const RandoEatsButton({
    required this.onPressed,
    this.isSpinning = false,
    super.key,
  });

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Whether the slot machine is currently spinning.
  final bool isSpinning;

  @override
  State<RandoEatsButton> createState() => _RandoEatsButtonState();
}

class _RandoEatsButtonState extends State<RandoEatsButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _spinController;

  /// Slow, continuous rotation for the scalloped "cookie" shape behind the
  /// badge — a Material 3 Expressive signature. Independent of the logo spin.
  late AnimationController _scallopController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    unawaited(_pulseController.repeat(reverse: true));

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scallopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    unawaited(_scallopController.repeat());
  }

  @override
  void didUpdateWidget(RandoEatsButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning && !oldWidget.isSpinning) {
      unawaited(_spinController.repeat());
    } else if (!widget.isSpinning && oldWidget.isSpinning) {
      _spinController
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _spinController.dispose();
    _scallopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 88.0;
    // The frosted blur ring extends ~16px beyond the logo all around, so the
    // disc is the logo plus a 16px halo on each side.
    const halo = 16.0;
    const discSize = size + halo * 2;

    // The round badge logo IS the control: it gently pulses to invite a tap
    // and rotates while the reels spin.
    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: GoogieColors.coral.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/rand-o-eats-badge.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );

    // While spinning the badge rotates and is not tappable; idle, it pulses
    // and accepts taps. Either way the rotation/scale wraps ONLY the logo so
    // the blur disc behind it stays still.
    final control = widget.isSpinning
        ? RotationTransition(turns: _spinController, child: badge)
        : Semantics(
            button: true,
            label: 'Spin to pick a restaurant',
            child: GestureDetector(
              onTap: widget.onPressed,
              child: ScaleTransition(scale: _pulseAnimation, child: badge),
            ),
          );

    return SizedBox(
      width: discSize,
      height: discSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Frosted-blur scalloped "cookie" shape behind the logo (Material 3
          // Expressive signature). It blurs the cards under it so the badge
          // pops, and slowly rotates on its own — independent of the logo spin.
          RotationTransition(
            turns: _scallopController,
            child: ClipPath(
              clipper: _ScallopClipper(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  width: discSize,
                  height: discSize,
                  color: GoogieColors.cream.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          control,
        ],
      ),
    );
  }
}

/// Clips to a smooth scalloped "cookie" shape — radius gently modulated by a
/// cosine so the edge ripples into soft lobes (Material 3 Expressive shape).
class _ScallopClipper extends CustomClipper<Path> {
  /// Number of lobes around the edge.
  static const lobes = 12;

  /// How far the lobes bulge, as a fraction of the radius.
  static const depth = 0.06;

  @override
  Path getClip(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final base = size.shortestSide / 2;
    final path = Path();
    const steps = 240;
    for (var i = 0; i <= steps; i++) {
      final theta = i / steps * 2 * math.pi;
      final r = base * (1 - depth) + base * depth * math.cos(lobes * theta);
      final x = cx + r * math.cos(theta);
      final y = cy + r * math.sin(theta);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _ScallopClipper old) => false;
}
