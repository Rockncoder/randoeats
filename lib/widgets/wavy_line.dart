import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:randoeats/config/config.dart';

/// An animated sine-wave line in the Material 3 Expressive spirit (the
/// "squiggle"). Used as a lively divider and as an indeterminate "scanning"
/// progress line.
///
/// Optionally draws a second, offset wave in [secondaryColor] for depth.
class WavyLine extends StatefulWidget {
  /// Creates a [WavyLine].
  const WavyLine({
    this.color = GoogieColors.turquoise,
    this.secondaryColor,
    this.height = 20,
    this.amplitude = 5,
    this.wavelength = 40,
    this.strokeWidth = 4,
    this.animate = true,
    this.speed = 1,
    super.key,
  });

  /// Primary wave color.
  final Color color;

  /// Optional second wave, drawn half a wavelength out of phase behind the
  /// primary one.
  final Color? secondaryColor;

  /// Overall height of the painted band.
  final double height;

  /// Peak height of the wave from its midline.
  final double amplitude;

  /// Horizontal distance of one full wave cycle.
  final double wavelength;

  /// Wave stroke thickness.
  final double strokeWidth;

  /// Whether the wave travels horizontally.
  final bool animate;

  /// Animation speed multiplier (1.0 ≈ one cycle every ~1.6s).
  final double speed;

  @override
  State<WavyLine> createState() => _WavyLineState();
}

class _WavyLineState extends State<WavyLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (1600 / widget.speed).round()),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) unawaited(_controller.repeat());
  }

  @override
  void didUpdateWidget(WavyLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      unawaited(_controller.repeat());
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _WavyPainter(
              phase: _controller.value * 2 * math.pi,
              color: widget.color,
              secondaryColor: widget.secondaryColor,
              amplitude: widget.amplitude,
              wavelength: widget.wavelength,
              strokeWidth: widget.strokeWidth,
            ),
          );
        },
      ),
    );
  }
}

class _WavyPainter extends CustomPainter {
  _WavyPainter({
    required this.phase,
    required this.color,
    required this.secondaryColor,
    required this.amplitude,
    required this.wavelength,
    required this.strokeWidth,
  });

  final double phase;
  final Color color;
  final Color? secondaryColor;
  final double amplitude;
  final double wavelength;
  final double strokeWidth;

  Path _wavePath(Size size, double phaseShift) {
    final path = Path();
    final mid = size.height / 2;
    final k = 2 * math.pi / wavelength;
    for (double x = 0; x <= size.width; x += 2) {
      final y = mid + amplitude * math.sin(k * x + phase + phaseShift);
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (secondaryColor != null) {
      canvas.drawPath(
        _wavePath(size, math.pi),
        paint..color = secondaryColor!,
      );
    }
    canvas.drawPath(_wavePath(size, 0), paint..color = color);
  }

  @override
  bool shouldRepaint(covariant _WavyPainter old) =>
      old.phase != phase ||
      old.color != color ||
      old.secondaryColor != secondaryColor ||
      old.amplitude != amplitude ||
      old.wavelength != wavelength ||
      old.strokeWidth != strokeWidth;
}
