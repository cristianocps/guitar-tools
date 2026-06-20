import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Draws the metronome pendulum: a housing, a swinging rod and a bob whose
/// color highlights the downbeat.
class PendulumPainter extends CustomPainter {
  PendulumPainter({
    required this.phaseNotifier,
    required this.beatNotifier,
    required this.beatsPerBar,
  });

  final ValueListenable<double> phaseNotifier;
  final ValueListenable<int> beatNotifier;
  final int beatsPerBar;

  static const double _maxAngle = 0.7; // radians (~40°)

  @override
  void paint(Canvas canvas, Size size) {
    final double phase = phaseNotifier.value;
    final int beat = beatNotifier.value;
    final bool playing = beat > 0;

    final Offset pivot = Offset(size.width / 2, size.height * 0.92);
    final double rodLength = size.height * 0.78;

    // Housing base.
    final Paint basePaint = Paint()
      ..color = AppColors.surfaceElevated
      ..style = PaintingStyle.fill;
    final RRect base = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.94),
        width: size.width * 0.6,
        height: size.height * 0.08,
      ),
      const Radius.circular(16),
    );
    canvas.drawRRect(base, basePaint);

    // Beat dots row.
    final double dotY = size.height * 0.1;
    final double spacing = size.width * 0.8 / (beatsPerBar - 1).clamp(1, 8);
    for (int i = 0; i < beatsPerBar; i++) {
      final Offset center = Offset(
        size.width * 0.1 + spacing * i,
        dotY,
      );
      final bool accent = i == 0;
      final bool active = playing && (beat - 1) == i;
      final Paint dot = Paint()
        ..color = active
            ? (accent ? AppColors.accent : AppColors.primary)
            : AppColors.border;
      canvas.drawCircle(center, active ? 8 : 5, dot);
    }

    // Pendulum rod + bob.
    final double angle = playing ? -_maxAngle * cos(pi * phase) : 0;
    final Offset bob = Offset(
      pivot.dx + sin(angle) * rodLength,
      pivot.dy - cos(angle) * rodLength,
    );

    final Paint rodPaint = Paint()
      ..color = AppColors.textSecondary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pivot, bob, rodPaint);

    final Paint pivotPaint = Paint()..color = AppColors.textMuted;
    canvas.drawCircle(pivot, 6, pivotPaint);

    final bool downbeat = playing && beat == 1;
    final Paint bobPaint = Paint()
      ..color = downbeat ? AppColors.accent : AppColors.primary;
    canvas.drawCircle(bob, 16, bobPaint..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12));
    canvas.drawCircle(bob, 14, Paint()..color = downbeat ? AppColors.accent : AppColors.primary);
  }

  @override
  bool shouldRepaint(covariant PendulumPainter oldDelegate) => false;
}
