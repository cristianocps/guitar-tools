import 'dart:math' as math;

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
    required this.labelColor,
  });

  final ChordPosition position;
  final int? highlightedString;
  final Color stringColor;
  final Color fretColor;
  final Color dotColor;
  final Color textColor;
  final Color barreColor;

  /// Color used for the fret/string numbers and the open/mute markers.
  final Color labelColor;

  static const int _stringCount = 6;
  static const int _fretCount = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // Reserve gutters around the fretboard so markers and numbers never spill
    // outside the drawing: X/O on top, fret numbers on the left, string
    // numbers on the bottom.
    final double markerZone = height * 0.12;
    final double bottomZone = height * 0.10;
    final double leftZone = width * 0.16;
    final double rightZone = width * 0.05;

    final double boardLeft = leftZone;
    final double boardRight = width - rightZone;
    final double boardTop = markerZone;
    final double boardWidth = boardRight - boardLeft;
    final double boardHeight = height - markerZone - bottomZone;
    final double stringSpacing = boardWidth / (_stringCount - 1);
    final double fretSpacing = boardHeight / _fretCount;

    final Paint stringPaint = Paint()
      ..color = stringColor
      ..strokeWidth = 2;
    final Paint fretPaint = Paint()
      ..color = fretColor
      ..strokeWidth = 2;

    for (int i = 0; i < _stringCount; i++) {
      final double x = boardLeft + i * stringSpacing;
      canvas.drawLine(
        Offset(x, boardTop),
        Offset(x, boardTop + boardHeight),
        stringPaint,
      );
    }

    for (int i = 0; i <= _fretCount; i++) {
      final double y = boardTop + i * fretSpacing;
      // Draw the nut (top edge of an open-position chord) thicker.
      final Paint paint = (i == 0 && position.baseFret == 1)
          ? (Paint()
            ..color = fretColor
            ..strokeWidth = 5)
          : fretPaint;
      canvas.drawLine(Offset(boardLeft, y), Offset(boardRight, y), paint);
    }

    // Fret (casa) numbers down the left gutter, one per fret row.
    for (int i = 0; i < _fretCount; i++) {
      final int fretNumber = position.baseFret + i;
      final double y = boardTop + (i + 0.5) * fretSpacing;
      _paintText(
        canvas,
        '$fretNumber',
        Offset(boardLeft - 6, y),
        color: labelColor,
        fontSize: height * 0.07,
        anchor: _Anchor.centerRight,
      );
    }

    final double radius = math.min(stringSpacing * 0.34, fretSpacing * 0.38);

    // Barre: a single clean rounded bar across the strings it covers. The
    // individual finger dots for those strings are skipped (the bar represents
    // them) so it no longer looks like two circles joined by a line.
    final Set<int> barredStrings = <int>{};
    for (final int barreFret in position.barres) {
      // chords-db fret values are relative to baseFret (relative fret 1 is the
      // first row of the diagram), so the row is simply `fret - 1`.
      final double y = boardTop + (barreFret - 1 + 0.5) * fretSpacing;
      int minString = _stringCount;
      int maxString = -1;
      int barreFinger = 0;
      for (int s = 0; s < _stringCount; s++) {
        if (position.frets[s] == barreFret) {
          barredStrings.add(s);
          if (s < minString) {
            minString = s;
          }
          if (s > maxString) {
            maxString = s;
          }
          if (position.fingers[s] > 0) {
            barreFinger = position.fingers[s];
          }
        }
      }
      if (maxString < 0) {
        // No explicit strings recorded for this barre: span the full board.
        minString = 0;
        maxString = _stringCount - 1;
      }
      final double thickness = radius * 2;
      // Tuck the rounded ends inside the outer barred strings so the barre
      // never bleeds past the edge of the fretboard.
      final double left = boardLeft + minString * stringSpacing;
      final double right = boardLeft + maxString * stringSpacing;
      final RRect bar = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          left - thickness / 2,
          y - thickness / 2,
          right + thickness / 2,
          y + thickness / 2,
        ),
        Radius.circular(thickness / 2),
      );
      canvas.drawRRect(bar, Paint()..color = barreColor);

      if (barreFinger > 0) {
        _paintText(
          canvas,
          '$barreFinger',
          Offset((left + right) / 2, y),
          color: textColor,
          fontSize: radius * 1.1,
          bold: true,
          anchor: _Anchor.center,
        );
      }
    }

    for (int s = 0; s < _stringCount; s++) {
      final int fret = position.frets[s];
      final int finger = position.fingers[s];

      if (fret <= 0 || barredStrings.contains(s)) {
        continue;
      }

      final double x = boardLeft + s * stringSpacing;
      final double y = boardTop + (fret - 1 + 0.5) * fretSpacing;

      final Paint dotPaint = Paint()
        ..color =
            highlightedString == s ? AppColorsOverride.highlight : dotColor;
      canvas.drawCircle(Offset(x, y), radius, dotPaint);

      if (finger > 0) {
        _paintText(
          canvas,
          '$finger',
          Offset(x, y),
          color: textColor,
          fontSize: radius * 1.1,
          bold: true,
          anchor: _Anchor.center,
        );
      }
    }

    // Open (O) / muted (X) markers above the nut.
    for (int s = 0; s < _stringCount; s++) {
      final int fret = position.frets[s];
      final String? label = fret == 0
          ? 'O'
          : fret == -1
              ? 'X'
              : null;
      if (label == null) {
        continue;
      }
      _paintText(
        canvas,
        label,
        Offset(boardLeft + s * stringSpacing, markerZone / 2),
        color: labelColor,
        fontSize: height * 0.085,
        bold: true,
        anchor: _Anchor.center,
      );
    }

    // String numbers along the bottom (6 = low E .. 1 = high E).
    for (int s = 0; s < _stringCount; s++) {
      _paintText(
        canvas,
        '${_stringCount - s}',
        Offset(boardLeft + s * stringSpacing, height - bottomZone / 2),
        color: labelColor,
        fontSize: height * 0.07,
        anchor: _Anchor.center,
      );
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset anchorPoint, {
    required Color color,
    required double fontSize,
    bool bold = false,
    _Anchor anchor = _Anchor.center,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    painter.layout();
    final Offset origin;
    switch (anchor) {
      case _Anchor.center:
        origin = Offset(
          anchorPoint.dx - painter.width / 2,
          anchorPoint.dy - painter.height / 2,
        );
      case _Anchor.centerRight:
        origin = Offset(
          anchorPoint.dx - painter.width,
          anchorPoint.dy - painter.height / 2,
        );
    }
    painter.paint(canvas, origin);
  }

  @override
  bool shouldRepaint(covariant ChordDiagramPainter oldDelegate) =>
      oldDelegate.position != position ||
      oldDelegate.highlightedString != highlightedString;
}

enum _Anchor { center, centerRight }

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
        stringColor: onSurface.withValues(alpha: 0.7),
        fretColor: onSurface.withValues(alpha: 0.7),
        dotColor: theme.colorScheme.primary,
        textColor: theme.colorScheme.onPrimary,
        barreColor: theme.colorScheme.primary,
        labelColor: onSurface,
      ),
    );
  }
}
