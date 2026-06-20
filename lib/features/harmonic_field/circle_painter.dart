import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/music_theory/harmonic_field.dart';
import '../../core/music_theory/pitch.dart';
import '../../core/theme/app_colors.dart';

/// Returns the 7 degree node positions arranged on a circle (tonic at top).
List<Offset> degreeOffsets(Offset center, double radius) {
  return List<Offset>.generate(7, (int i) {
    final double angle = -pi / 2 + i * 2 * pi / 7;
    return Offset(
      center.dx + cos(angle) * radius,
      center.dy + sin(angle) * radius,
    );
  });
}

/// Draws the harmonic field as an interactive circle of 7 degrees, with the
/// tonic highlighted and the selected degree emphasized.
class HarmonicCirclePainter extends CustomPainter {
  HarmonicCirclePainter({
    required this.field,
    required this.selectedIndex,
  });

  final HarmonicField field;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = min(size.width, size.height) / 2 - 48;
    final List<Offset> nodes = degreeOffsets(center, radius);

    // Connecting ring.
    final Paint ring = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, ring);

    // Spokes from center to each degree.
    final Paint spoke = Paint()
      ..color = AppColors.border.withOpacity(0.5)
      ..strokeWidth = 1.5;
    for (final Offset node in nodes) {
      canvas.drawLine(center, node, spoke);
    }

    // Center tonic label.
    final String tonicName = PitchNames.name(field.tonicPitchClass);
    _drawText(
      canvas,
      tonicName,
      center,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 26,
        fontWeight: FontWeight.w800,
      ),
    );
    _drawText(
      canvas,
      field.scaleType == ScaleType.major ? 'Maior' : 'Menor',
      center + const Offset(0, 26),
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
    );

    for (int i = 0; i < 7; i++) {
      final Offset node = nodes[i];
      final HarmonicDegree degree = field.degrees[i];
      final bool isTonic = i == 0;
      final bool isSelected = i == selectedIndex;

      final Color color = isTonic
          ? AppColors.primary
          : (isSelected ? AppColors.accent : AppColors.surfaceElevated);

      if (isTonic || isSelected) {
        final Paint glow = Paint()
          ..color = color.withOpacity(0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 16);
        canvas.drawCircle(node, 34, glow);
      }

      final Paint nodePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(node, isTonic ? 34 : 28, nodePaint);

      final Paint border = Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(node, isTonic ? 34 : 28, border);

      // Chord name inside the node.
      _drawText(
        canvas,
        degree.chord.name(),
        node,
        style: TextStyle(
          color: AppColors.background,
          fontSize: isTonic ? 16 : 14,
          fontWeight: FontWeight.w800,
        ),
      );
      // Roman numeral beneath the node.
      _drawText(
        canvas,
        degree.romanNumeral,
        node + Offset(0, isTonic ? 50 : 44),
        style: TextStyle(
          color: isTonic ? AppColors.primary : AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center, {
    required TextStyle style,
  }) {
    final TextSpan span = TextSpan(text: text, style: style);
    final TextPainter tp = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant HarmonicCirclePainter oldDelegate) =>
      oldDelegate.field.tonicPitchClass != field.tonicPitchClass ||
      oldDelegate.field.scaleType != field.scaleType ||
      oldDelegate.selectedIndex != selectedIndex;
}
