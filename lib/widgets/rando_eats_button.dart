import 'dart:async';
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
          // Static frosted-blur disc behind the logo. It blurs whatever sits
          // under it (the restaurant cards) within a circle, helping the badge
          // pop. It is outside the rotation, so it never spins.
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: discSize,
                height: discSize,
                color: GoogieColors.cream.withValues(alpha: 0.3),
              ),
            ),
          ),
          control,
        ],
      ),
    );
  }
}
