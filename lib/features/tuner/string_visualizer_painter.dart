import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Draws six guitar strings (low E at top → high E at bottom). The active
/// string is highlighted and vibrates; the others stay still.
class StringVisualizerPainter extends CustomPainter {
  StringVisualizerPainter({
    required this.activeIndex,
    required this.intensity,
  });

  /// Index into the active tuning's strings (0 = low E), or null for none.
  final int? activeIndex;

  /// 0..1 vibration intensity for the active string.
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    const int count = 6;
    final double stepY = size.height / (count + 1);
    const double marginX = 28;

    for (int i = 0; i < count; i++) {
      final double y = stepY * (i + 1);
      final bool active = i == activeIndex;
      // Thicker strings for the low register (like real strings).
      final double thickness = 2.0 + (count - i) * 0.5;

      final Paint paint = Paint()
        ..color = active ? AppColors.primary : AppColors.border
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round;

      if (!active) {
        canvas.drawLine(
          Offset(marginX, y),
          Offset(size.width - marginX, y),
          paint,
        );
      } else {
        final Path path = Path();
        const int segments = 40;
        final double amp = 6 + intensity * 14;
        for (int s = 0; s <= segments; s++) {
          final double t = s / segments;
          final double x = marginX + t * (size.width - 2 * marginX);
          final double wave = sin(t * pi * 4) * amp * intensity;
          if (s == 0) {
            path.moveTo(x, y + wave);
          } else {
            path.lineTo(x, y + wave);
          }
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant StringVisualizerPainter oldDelegate) =>
      oldDelegate.activeIndex != activeIndex ||
      oldDelegate.intensity != intensity;
}
