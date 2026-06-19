import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:randoeats/app/router.dart';

/// In-app splash shown right after the native launch screen.
///
/// The native (OS) splash is limited — Android 12+ masks its icon to a small
/// circle — so this Flutter screen shows the full logo as large as the device
/// allows, then hands off to the results screen. The cream background matches
/// the native splash (#F5F0E1) so the transition is seamless.
class SplashScreen extends StatefulWidget {
  /// Creates a [SplashScreen].
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _background = Color(0xFFF5F0E1);

  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = Tween<double>(begin: 0.86, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    unawaited(_controller.forward());
    _navTimer = Timer(const Duration(milliseconds: 1900), _goToResults);
  }

  void _goToResults() {
    if (!mounted) return;
    context.go(AppRoutes.results);
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    // splash_logo.png is the sign trimmed of its margin, so it can fill most of
    // the screen width — as large as the device allows.
    final logoWidth = (shortestSide * 0.85).clamp(300.0, 760.0);

    return Scaffold(
      backgroundColor: _background,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Image.asset(
              'assets/images/splash_logo.png',
              width: logoWidth,
            ),
          ),
        ),
      ),
    );
  }
}
