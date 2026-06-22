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

/// Brand color associated with a triad quality.
Color colorForQuality(TriadQuality quality) {
  switch (quality) {
    case TriadQuality.major:
    case TriadQuality.augmented:
      return AppColors.primary;
    case TriadQuality.minor:
      return AppColors.secondary;
    case TriadQuality.diminished:
      return AppColors.tertiary;
  }
}

/// Draws the harmonic field as an interactive circle of 7 degrees. Nodes are
/// color-coded by chord quality, the tonic and the selected degree glow, and
/// the [pulse] value (0..1) animates that glow for a living feel.
class HarmonicCirclePainter extends CustomPainter {
  HarmonicCirclePainter({
    required this.field,
    required this.selectedIndex,
    this.pulse = 0,
    this.notation = Notation.letters,
  });

  final HarmonicField field;
  final int? selectedIndex;
  final double pulse;
  final Notation notation;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = min(size.width, size.height) / 2 - 48;
    final List<Offset> nodes = degreeOffsets(center, radius);

    // Connecting ring with a subtle gradient.
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = SweepGradient(
        colors: <Color>[
          AppColors.primary.withOpacity(0.5),
          AppColors.secondary.withOpacity(0.5),
          AppColors.tertiary.withOpacity(0.5),
          AppColors.primary.withOpacity(0.5),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, ring);

    // Spokes from center to each degree.
    final Paint spoke = Paint()
      ..color = AppColors.border.withOpacity(0.4)
      ..strokeWidth = 1.5;
    for (final Offset node in nodes) {
      canvas.drawLine(center, node, spoke);
    }

    // Center tonic plate.
    final Color tonicColor = colorForQuality(field.degrees[0].chord.quality);
    canvas.drawCircle(
      center,
      40,
      Paint()..color = AppColors.surface.withOpacity(0.85),
    );
    canvas.drawCircle(
      center,
      40,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = tonicColor.withOpacity(0.7),
    );
    _drawText(
      canvas,
      PitchNames.name(field.tonicPitchClass, notation: notation),
      center + const Offset(0, -6),
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
    );
    _drawText(
      canvas,
      field.scaleType == ScaleType.major ? 'Maior' : 'Menor',
      center + const Offset(0, 18),
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
    );

    for (int i = 0; i < 7; i++) {
      final Offset node = nodes[i];
      final HarmonicDegree degree = field.degrees[i];
      final bool isTonic = i == 0;
      final bool isSelected = i == selectedIndex;
      final Color color = colorForQuality(degree.chord.quality);
      final double r = isTonic ? 32 : 26;

      // Glow (tonic always; selected pulses).
      if (isTonic || isSelected) {
        final double glowAlpha = isSelected ? 0.35 + 0.35 * pulse : 0.4;
        final Paint glow = Paint()
          ..color = color.withOpacity(glowAlpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.outer, isSelected ? 18 : 14);
        canvas.drawCircle(node, r + (isSelected ? 4 * pulse : 0), glow);
      }

      // Node fill — radial gradient for depth.
      final Paint fill = Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Color.lerp(color, Colors.white, 0.25)!,
            color,
            Color.lerp(color, Colors.black, 0.35)!,
          ],
          stops: const <double>[0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: node, radius: r));
      canvas.drawCircle(node, r, fill);

      // Outer ring — brighter when selected.
      final Paint border = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3 : 2
        ..color = isSelected
            ? Colors.white.withOpacity(0.9)
            : color.withOpacity(0.4);
      canvas.drawCircle(node, r, border);

      // Chord name inside the node.
      _drawText(
        canvas,
        degree.chord.name(notation: notation),
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
        node + Offset(0, r + 14),
        style: TextStyle(
          color: isSelected ? Colors.white : color,
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
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.notation != notation ||
      oldDelegate.pulse != pulse;
}
