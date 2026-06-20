import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Horizontal cents meter: a center line with a glowing indicator that moves
/// left (flat) or right (sharp) within ±50 cents.
class TuningMeterPainter extends CustomPainter {
  TuningMeterPainter({
    required this.cents,
    required this.active,
    required this.inTune,
  });

  final double cents; // -50..50
  final bool active;
  final bool inTune;

  @override
  void paint(Canvas canvas, Size size) {
    final double cy = size.height / 2;
    final double half = size.width / 2;

    // Track.
    final Paint track = Paint()
      ..color = AppColors.border
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(16, cy), Offset(size.width - 16, cy), track);

    // Tick marks every 10 cents.
    final Paint tick = Paint()
      ..color = AppColors.textMuted
      ..strokeWidth = 1.5;
    for (int c = -50; c <= 50; c += 10) {
      final double x = half + (c / 50) * (half - 16);
      final double len = c == 0 ? 18 : 8;
      canvas.drawLine(Offset(x, cy - len / 2), Offset(x, cy + len / 2), tick);
    }

    // In-tune zone shading.
    final Paint zone = Paint()..color = AppColors.inTune.withOpacity(0.10);
    final double zx0 = half + (-5 / 50) * (half - 16);
    final double zx1 = half + (5 / 50) * (half - 16);
    canvas.drawRect(Rect.fromLTRB(zx0, cy - 20, zx1, cy + 20), zone);

    if (!active) {
      return;
    }

    final double clamped = cents.clamp(-50.0, 50.0);
    final double x = half + (clamped / 50) * (half - 16);
    final Color color = inTune ? AppColors.inTune : (cents < 0 ? AppColors.flat : AppColors.sharp);

    final Paint glow = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 14);
    canvas.drawCircle(Offset(x, cy), 14, glow);

    final Paint dot = Paint()..color = color;
    canvas.drawCircle(Offset(x, cy), 12, dot);
  }

  @override
  bool shouldRepaint(covariant TuningMeterPainter oldDelegate) =>
      oldDelegate.cents != cents ||
      oldDelegate.active != active ||
      oldDelegate.inTune != inTune;
}
