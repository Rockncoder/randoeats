import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:randoeats/config/config.dart';

/// A large, Googie-styled button for triggering the slot machine animation.
///
/// Features atomic-age styling with starburst accents and a pill shape.
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
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isSpinning ? 1.0 : _pulseAnimation.value,
          child: child,
        );
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: GoogieColors.coral.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: GoogieColors.mustard.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isSpinning ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(40),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isSpinning
                      ? [
                          GoogieColors.chrome,
                          GoogieColors.chrome.withValues(alpha: 0.8),
                        ]
                      : [
                          GoogieColors.coral,
                          GoogieColors.coral.withValues(alpha: 0.9),
                          const Color(0xFFFF8A65),
                        ],
                ),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: GoogieColors.mustard.withValues(alpha: 0.5),
                  width: 3,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Starburst decorations
                  if (!widget.isSpinning) ...[
                    Positioned(
                      left: 20,
                      child: _buildStarburst(size: 24),
                    ),
                    Positioned(
                      right: 20,
                      child: _buildStarburst(size: 24),
                    ),
                  ],
                  // Button content
                  if (widget.isSpinning)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: GoogieColors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'SPINNING...',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: GoogieColors.white,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                offset: const Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Image.asset(
                        'assets/images/rand-o-eats-no-motto.png',
                        height: 56,
                        fit: BoxFit.contain,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStarburst({required double size}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StarburstPainter(
          color: GoogieColors.mustard.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

class _StarburstPainter extends CustomPainter {
  _StarburstPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw 8-point starburst
    final path = Path();
    const points = 8;
    for (var i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final r = i.isEven ? radius : radius * 0.4;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
