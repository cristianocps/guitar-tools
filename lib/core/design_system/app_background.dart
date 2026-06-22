import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-screen animated "aurora" background: the base gradient plus a few
/// slowly drifting neon blobs that give the app a living, premium depth.
///
/// The motion is intentionally slow and the blob count small so it stays
/// smooth even on low-end Android. Pass [glowColor] to tint the dominant blob
/// to match the active feature (e.g. green when in tune).
class AppBackground extends StatefulWidget {
  const AppBackground({
    required this.child,
    super.key,
    this.glowColor,
  });

  final Widget child;
  final Color? glowColor;

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color glow = widget.glowColor ?? AppColors.primary;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (BuildContext context, _) {
                    return CustomPaint(
                      painter: _AuroraPainter(
                        t: _controller.value,
                        primary: glow,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
              ),
            ),
          ),
          SafeArea(child: widget.child),
        ],
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({required this.t, required this.primary});

  /// Normalized animation phase (0..1).
  final double t;
  final Color primary;

  @override
  void paint(Canvas canvas, Size size) {
    const double tau = 2 * math.pi;

    _blob(
      canvas,
      size,
      color: primary,
      alpha: 0.22,
      cx: 0.30 + 0.12 * math.sin(t * tau),
      cy: 0.18 + 0.06 * math.cos(t * tau),
      radius: 0.75,
    );
    _blob(
      canvas,
      size,
      color: AppColors.secondary,
      alpha: 0.16,
      cx: 0.80 + 0.10 * math.cos(t * tau + 1.4),
      cy: 0.30 + 0.08 * math.sin(t * tau * 0.8),
      radius: 0.65,
    );
    _blob(
      canvas,
      size,
      color: AppColors.tertiary,
      alpha: 0.10,
      cx: 0.55 + 0.14 * math.sin(t * tau * 0.6 + 3.0),
      cy: 0.88 + 0.05 * math.cos(t * tau * 1.2),
      radius: 0.8,
    );
  }

  void _blob(
    Canvas canvas,
    Size size, {
    required Color color,
    required double alpha,
    required double cx,
    required double cy,
    required double radius,
  }) {
    final Offset center = Offset(cx * size.width, cy * size.height);
    final double r = radius * size.shortestSide;
    final Paint paint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          color.withOpacity(alpha),
          color.withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, paint);
  }

  @override
  bool shouldRepaint(_AuroraPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.primary != primary;
}
