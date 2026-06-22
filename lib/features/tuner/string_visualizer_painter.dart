import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Draws the strings of the active tuning (low string at top → high at bottom).
/// The active string vibrates as a real plucked string would: a standing wave
/// pinned at both ends (nut and bridge), built from the fundamental mode plus
/// a couple of decaying harmonics, oscillating over time.
class StringVisualizerPainter extends CustomPainter {
  StringVisualizerPainter({
    required this.activeIndex,
    required this.intensity,
    required this.phase,
    this.stringCount = 6,
  });

  /// Index into the active tuning's strings (0 = low string), or null for none.
  final int? activeIndex;

  /// 0..1 vibration intensity for the active string.
  final double intensity;

  /// Animation phase in radians; one full oscillation of the fundamental every
  /// 2π. Driven by a continuous clock so the string truly moves over time.
  final double phase;

  /// Number of strings to draw.
  final int stringCount;

  @override
  void paint(Canvas canvas, Size size) {
    final int count = stringCount;
    final double stepY = size.height / (count + 1);
    const double marginX = 28;
    final double span = size.width - 2 * marginX;

    for (int i = 0; i < count; i++) {
      final double y = stepY * (i + 1);
      final bool active = i == activeIndex;
      // Thicker strings for the low register (like real strings).
      final double thickness = 2.0 + (count - i) * 0.5;

      if (!active) {
        final Paint paint = Paint()
          ..color = AppColors.border
          ..strokeWidth = thickness
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(marginX, y),
          Offset(size.width - marginX, y),
          paint,
        );
        continue;
      }

      // Peak excursion, capped so the swing never reaches the neighboring
      // strings. Lower strings (drawn higher up) visibly swing a touch wider.
      final double lowFactor = 1 + 0.25 * (count - 1 - i) / (count - 1);
      final double amp =
          (stepY * 0.42) * intensity.clamp(0.0, 1.0) * lowFactor;

      // Modal superposition: y(x,t) = Σ aₙ · sin(nπx/L) · sin(nφ + θₙ).
      // The fundamental dominates; the 2nd/3rd modes add a realistic shimmer.
      final double f1 = sin(phase);
      final double f2 = sin(2 * phase + 0.6);
      final double f3 = sin(3 * phase + 1.1);

      final Path path = Path();
      const int segments = 64;
      for (int s = 0; s <= segments; s++) {
        final double u = s / segments; // 0..1 along the string
        final double x = marginX + u * span;
        final double disp = amp *
            (sin(pi * u) * f1 +
                0.32 * sin(2 * pi * u) * f2 +
                0.16 * sin(3 * pi * u) * f3);
        if (s == 0) {
          path.moveTo(x, y + disp);
        } else {
          path.lineTo(x, y + disp);
        }
      }

      final Paint glow = Paint()
        ..color = AppColors.primary.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness + 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(path, glow);

      final Paint paint = Paint()
        ..shader = const LinearGradient(
          colors: <Color>[AppColors.primary, AppColors.secondary],
        ).createShader(Rect.fromLTWH(marginX, 0, span, size.height))
        ..strokeWidth = thickness
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StringVisualizerPainter oldDelegate) =>
      oldDelegate.activeIndex != activeIndex ||
      oldDelegate.intensity != intensity ||
      oldDelegate.stringCount != stringCount ||
      // Only the active string animates, so phase only matters when one is lit.
      (activeIndex != null && oldDelegate.phase != phase);
}
