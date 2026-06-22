import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:music_tools/core/chords/chord_diagram_painter.dart';
import 'package:music_tools/core/chords/chord_models.dart';

void main() {
  group('ChordDiagram', () {
    const ChordPosition cMajor = ChordPosition(
      frets: <int>[-1, 3, 2, 0, 1, 0],
      fingers: <int>[0, 3, 2, 0, 1, 0],
      baseFret: 1,
      barres: <int>[],
      midi: <int>[48, 52, 55, 60, 64],
    );

    testWidgets('renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChordDiagram(position: cMajor),
          ),
        ),
      );
      expect(find.byType(ChordDiagram), findsOneWidget);
    });
  });
}
