import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A premium speedometer-style cents gauge: a 260° arc with a graded
/// flat→in-tune→sharp track, tick marks and a glowing needle that points to
/// the current detuning. The note read-out lives in the center (as the widget
/// child), so this painter only renders the gauge itself.
class TunerGaugePainter extends CustomPainter {
  TunerGaugePainter({
    required this.cents,
    required this.active,
    required this.inTune,
    required this.glow,
  });

  /// Smoothed cents value to point at (clamped to ±50 for display).
  final double cents;

  /// Whether a pitch is currently detected (drives the needle/glow).
  final bool active;

  /// Whether the note is within the in-tune tolerance.
  final bool inTune;

  /// 0..1 glow strength (e.g. a pulse when in tune).
  final double glow;

  static const double _halfSpan = 130 * math.pi / 180; // ±130° from top.
  static const double _top = -math.pi / 2;

  double _angleFor(double c) => _top + (c.clamp(-50.0, 50.0) / 50) * _halfSpan;

  @override
  void paint(Canvas canvas, Size size) {
    const double margin = 14;
    // The arc runs from the top (−90°) down to ±130°, so its lowest point sits
    // r·sin(40°) below the center. Size the radius so the whole arc — top point
    // through the two lower tips — fits inside the box without spilling over
    // into the widgets below it.
    const double vFactor = 1 + 0.642788; // 1 + sin(40°)
    final double radius = math.max(
      0,
      math.min(
        size.width / 2 - margin,
        (size.height - 2 * margin) / vFactor,
      ),
    );
    final Offset center = Offset(size.width / 2, margin + radius);
    const double startAngle = _top - _halfSpan;
    const double sweep = 2 * _halfSpan;
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);

    // Faint base track.
    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = AppColors.border.withValues(alpha: 0.6);
    canvas.drawArc(arcRect, startAngle, sweep, false, track);

    // Graded color track (flat → in-tune → sharp) drawn as a sweep gradient.
    final Paint graded = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweep,
        colors: <Color>[
          AppColors.flat.withValues(alpha: 0.85),
          AppColors.flat.withValues(alpha: 0.35),
          AppColors.inTune,
          AppColors.sharp.withValues(alpha: 0.35),
          AppColors.sharp.withValues(alpha: 0.85),
        ],
        stops: const <double>[0.0, 0.36, 0.5, 0.64, 1.0],
        transform: const GradientRotation(startAngle),
      ).createShader(arcRect);
    canvas.drawArc(arcRect, startAngle, sweep, false, graded);

    // Tick marks every 10 cents.
    for (int c = -50; c <= 50; c += 10) {
      final double a = _angleFor(c.toDouble());
      final bool major = c == 0;
      final double inner = radius - (major ? 20 : 12);
      final double outer = radius - 2;
      final Paint tick = Paint()
        ..color = major
            ? AppColors.inTune.withValues(alpha: 0.9)
            : AppColors.textMuted.withValues(alpha: 0.7)
        ..strokeWidth = major ? 3 : 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        center + Offset(math.cos(a), math.sin(a)) * inner,
        center + Offset(math.cos(a), math.sin(a)) * outer,
        tick,
      );
    }

    if (!active) {
      _drawHub(canvas, center, AppColors.textMuted);
      return;
    }

    final Color color = inTune
        ? AppColors.inTune
        : (cents < 0 ? AppColors.flat : AppColors.sharp);
    final double a = _angleFor(cents);
    final Offset dir = Offset(math.cos(a), math.sin(a));

    // Progress arc from the top to the needle.
    const double from = _top;
    final double to = a;
    final Paint progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(arcRect, from, to - from, false, progress);

    // Needle.
    final Offset tip = center + dir * (radius - 4);
    final Offset base = center + dir * 26;
    final Paint needleGlow = Paint()
      ..color = color.withValues(alpha: 0.5 + 0.4 * glow)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawLine(base, tip, needleGlow);

    final Paint needle = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(base, tip, needle);

    // Glowing tip dot.
    final Paint tipGlow = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12);
    canvas.drawCircle(tip, 7, tipGlow);
    canvas.drawCircle(tip, 6, Paint()..color = color);

    _drawHub(canvas, center, color);
  }

  void _drawHub(Canvas canvas, Offset center, Color color) {
    canvas.drawCircle(
      center,
      14,
      Paint()..color = AppColors.surfaceElevated,
    );
    canvas.drawCircle(
      center,
      14,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant TunerGaugePainter oldDelegate) =>
      oldDelegate.cents != cents ||
      oldDelegate.active != active ||
      oldDelegate.inTune != inTune ||
      oldDelegate.glow != glow;
}
