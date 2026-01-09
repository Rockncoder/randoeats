import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:randoeats/config/config.dart';

/// A celebration overlay with atomic-age starburst effects.
///
/// Shows when a winner is selected from the slot machine.
class WinnerCelebration extends StatefulWidget {
  /// Creates a [WinnerCelebration].
  const WinnerCelebration({
    required this.onComplete,
    super.key,
  });

  /// Called when the celebration animation completes.
  final VoidCallback onComplete;

  @override
  State<WinnerCelebration> createState() => _WinnerCelebrationState();
}

class _WinnerCelebrationState extends State<WinnerCelebration>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _starburstController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _starburstRotation;

  final List<_Particle> _particles = [];
  final _random = math.Random();

  @override
  void initState() {
    super.initState();

    // Main celebration controller
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_mainController);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 1),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0),
        weight: 20,
      ),
    ]).animate(_mainController);

    // Starburst rotation controller
    _starburstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _starburstRotation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _starburstController, curve: Curves.linear),
    );

    // Generate particles
    _generateParticles();

    // Start animations
    unawaited(_mainController.forward());
    unawaited(_starburstController.repeat());

    // Trigger completion callback
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  void _generateParticles() {
    final colors = [
      GoogieColors.coral,
      GoogieColors.mustard,
      GoogieColors.turquoise,
      const Color(0xFFFF8A65),
      const Color(0xFF81D4FA),
    ];

    for (var i = 0; i < 30; i++) {
      _particles.add(
        _Particle(
          angle: _random.nextDouble() * 2 * math.pi,
          speed: 100 + _random.nextDouble() * 200,
          size: 8 + _random.nextDouble() * 16,
          color: colors[_random.nextInt(colors.length)],
          shape: _ParticleShape.values[_random.nextInt(3)],
          rotationSpeed: (_random.nextDouble() - 0.5) * 10,
        ),
      );
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _starburstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _starburstController]),
      builder: (context, child) {
        return IgnorePointer(
          child: Stack(
            children: [
              // Background flash
              Positioned.fill(
                child: Opacity(
                  opacity: _opacityAnimation.value * 0.3,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          GoogieColors.mustard.withValues(alpha: 0.8),
                          GoogieColors.coral.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              // Central starburst
              Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _starburstRotation.value,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: CustomPaint(
                        size: const Size(200, 200),
                        painter: _CelebrationStarburstPainter(
                          color: GoogieColors.mustard,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Particles
              ..._buildParticles(),
              // Winner text
              Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: GoogieColors.coral,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: GoogieColors.coral.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Text(
                        'WINNER!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: GoogieColors.white,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildParticles() {
    final progress = _mainController.value;
    return _particles.map((particle) {
      final distance = particle.speed * progress;
      final x = math.cos(particle.angle) * distance;
      final y = math.sin(particle.angle) * distance - (progress * 50);
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final rotation = particle.rotationSpeed * progress * math.pi;

      return Positioned(
        left: MediaQuery.of(context).size.width / 2 + x - particle.size / 2,
        top: MediaQuery.of(context).size.height / 2 + y - particle.size / 2,
        child: Transform.rotate(
          angle: rotation,
          child: Opacity(
            opacity: opacity,
            child: _buildParticleShape(particle),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildParticleShape(_Particle particle) {
    switch (particle.shape) {
      case _ParticleShape.star:
        return CustomPaint(
          size: Size(particle.size, particle.size),
          painter: _StarPainter(color: particle.color),
        );
      case _ParticleShape.circle:
        return Container(
          width: particle.size,
          height: particle.size,
          decoration: BoxDecoration(
            color: particle.color,
            shape: BoxShape.circle,
          ),
        );
      case _ParticleShape.diamond:
        return Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: particle.size * 0.7,
            height: particle.size * 0.7,
            color: particle.color,
          ),
        );
    }
  }
}

enum _ParticleShape { star, circle, diamond }

class _Particle {
  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
    required this.shape,
    required this.rotationSpeed,
  });

  final double angle;
  final double speed;
  final double size;
  final Color color;
  final _ParticleShape shape;
  final double rotationSpeed;
}

class _CelebrationStarburstPainter extends CustomPainter {
  _CelebrationStarburstPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.3;

    final path = Path();
    const points = 12;
    for (var i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final r = i.isEven ? outerRadius : innerRadius;
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

class _StarPainter extends CustomPainter {
  _StarPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.4;

    final path = Path();
    const points = 5;
    for (var i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final r = i.isEven ? outerRadius : innerRadius;
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
