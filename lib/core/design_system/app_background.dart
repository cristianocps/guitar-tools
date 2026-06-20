import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-screen gradient background with a soft radial glow, used as the base
/// layer for every screen to give the app a consistent "stunning" depth.
class AppBackground extends StatelessWidget {
  const AppBackground({
    required this.child,
    super.key,
    this.glowColor,
  });

  final Widget child;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -120,
            left: -80,
            right: -80,
            height: 360,
            child: IgnorePointer(
              child: _RadialGlow(color: glowColor ?? AppColors.primary),
            ),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class _RadialGlow extends StatelessWidget {
  const _RadialGlow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GlowPainter(color: color.withOpacity(0.18)),
      size: Size.infinite,
    );
  }
}

class _GlowPainter extends CustomPainter {
  const _GlowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 3);
    final double radius = size.width * 0.7;
    final Paint paint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[color, color.withOpacity(0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_GlowPainter oldDelegate) => oldDelegate.color != color;
}
