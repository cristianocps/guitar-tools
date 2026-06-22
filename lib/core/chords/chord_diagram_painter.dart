import 'package:flutter/material.dart';

import '../../core/chords/chord_models.dart';

/// Paints a guitar chord diagram for a single [ChordPosition].
class ChordDiagramPainter extends CustomPainter {
  ChordDiagramPainter({
    required this.position,
    this.highlightedString,
    required this.stringColor,
    required this.fretColor,
    required this.dotColor,
    required this.textColor,
    required this.barreColor,
  });

  final ChordPosition position;
  final int? highlightedString;
  final Color stringColor;
  final Color fretColor;
  final Color dotColor;
  final Color textColor;
  final Color barreColor;

  static const int _stringCount = 6;
  static const int _fretCount = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double topPadding = height * 0.12;
    final double diagramHeight = height * 0.7;
    final double stringSpacing = width / (_stringCount - 1);
    final double fretSpacing = diagramHeight / _fretCount;

    final Paint stringPaint = Paint()
      ..color = stringColor
      ..strokeWidth = 2;
    final Paint fretPaint = Paint()
      ..color = fretColor
      ..strokeWidth = 2;

    for (int i = 0; i < _stringCount; i++) {
      final double x = i * stringSpacing;
      canvas.drawLine(
        Offset(x, topPadding),
        Offset(x, topPadding + diagramHeight),
        stringPaint,
      );
    }

    for (int i = 0; i <= _fretCount; i++) {
      final double y = topPadding + i * fretSpacing;
      canvas.drawLine(Offset(0, y), Offset(width, y), fretPaint);
    }

    if (position.baseFret > 1) {
      final TextSpan span = TextSpan(
        text: '${position.baseFret}fr',
        style: TextStyle(color: textColor, fontSize: height * 0.08),
      );
      final TextPainter painter = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
      );
      painter.layout();
      painter.paint(
        canvas,
        Offset(width + 4, topPadding - painter.height / 2),
      );
    }

    for (final int barreFret in position.barres) {
      final double y = topPadding + (barreFret - position.baseFret + 0.5) * fretSpacing;
      final Paint barrePaint = Paint()
        ..color = barreColor
        ..strokeWidth = fretSpacing * 0.55
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(0, y),
        Offset(width, y),
        barrePaint,
      );
    }

    for (int s = 0; s < _stringCount; s++) {
      final int fret = position.frets[s];
      final int finger = position.fingers[s];

      if (fret == -1 || fret == 0) {
        continue;
      }

      final double x = s * stringSpacing;
      final double y = topPadding + (fret - position.baseFret + 0.5) * fretSpacing;
      final double radius = stringSpacing * 0.35;

      final Paint dotPaint = Paint()
        ..color = highlightedString == s ? AppColorsOverride.highlight : dotColor;
      canvas.drawCircle(Offset(x, y), radius, dotPaint);

      if (finger > 0 && position.barres.isEmpty) {
        final TextSpan span = TextSpan(
          text: '$finger',
          style: TextStyle(
            color: textColor,
            fontSize: radius,
            fontWeight: FontWeight.bold,
          ),
        );
        final TextPainter painter = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        painter.layout();
        painter.paint(
          canvas,
          Offset(x - painter.width / 2, y - painter.height / 2),
        );
      }
    }

    final TextStyle indicatorStyle = TextStyle(
      color: textColor,
      fontSize: height * 0.1,
      fontWeight: FontWeight.bold,
    );
    for (int s = 0; s < _stringCount; s++) {
      final int fret = position.frets[s];
      final String? label = fret == 0 ? 'O' : fret == -1 ? 'X' : null;
      if (label == null) {
        continue;
      }
      final TextSpan span = TextSpan(text: label, style: indicatorStyle);
      final TextPainter painter = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      painter.layout();
      painter.paint(
        canvas,
        Offset(s * stringSpacing - painter.width / 2, 0),
      );
    }
  }

  @override
  bool shouldRepaint(covariant ChordDiagramPainter oldDelegate) =>
      oldDelegate.position != position ||
      oldDelegate.highlightedString != highlightedString;
}

class AppColorsOverride {
  static const Color highlight = Color(0xFFFFB627);
}

/// Reusable widget that renders a chord diagram.
class ChordDiagram extends StatelessWidget {
  const ChordDiagram({
    required this.position,
    this.highlightedString,
    this.size = const Size(160, 200),
    super.key,
  });

  final ChordPosition position;
  final int? highlightedString;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color onSurface = theme.colorScheme.onSurface;
    return CustomPaint(
      size: size,
      painter: ChordDiagramPainter(
        position: position,
        highlightedString: highlightedString,
        stringColor: onSurface.withOpacity(0.7),
        fretColor: onSurface.withOpacity(0.7),
        dotColor: theme.colorScheme.primary,
        textColor: theme.colorScheme.onPrimary,
        barreColor: theme.colorScheme.primary,
      ),
    );
  }
}
