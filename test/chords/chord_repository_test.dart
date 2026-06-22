import 'package:flutter_test/flutter_test.dart';

import 'package:music_tools/core/chords/chord_models.dart';
import 'package:music_tools/core/chords/chord_repository.dart';

void main() {
  final List<Chord> chords = <Chord>[
    const Chord(
      key: 'C',
      suffix: 'major',
      positions: <ChordPosition>[
        ChordPosition(
          frets: <int>[-1, 3, 2, 0, 1, 0],
          fingers: <int>[0, 3, 2, 0, 1, 0],
          baseFret: 1,
          barres: <int>[],
          midi: <int>[48, 52, 55, 60, 64],
        ),
      ],
    ),
    const Chord(
      key: 'G',
      suffix: 'major',
      positions: <ChordPosition>[
        ChordPosition(
          frets: <int>[3, 2, 0, 0, 0, 3],
          fingers: <int>[2, 1, 0, 0, 0, 3],
          baseFret: 1,
          barres: <int>[],
          midi: <int>[43, 47, 50, 55, 59, 67],
        ),
      ],
    ),
    const Chord(
      key: 'F',
      suffix: 'major',
      positions: <ChordPosition>[
        ChordPosition(
          frets: <int>[1, 3, 3, 2, 1, 1],
          fingers: <int>[1, 3, 4, 2, 1, 1],
          baseFret: 1,
          barres: <int>[1],
          midi: <int>[41, 48, 53, 57, 60, 65],
        ),
      ],
    ),
  ];

  group('ChordRepository', () {
    test('find returns matching chord', () {
      final ChordRepository repo = ChordRepository(chords);
      final Chord? chord = repo.find('C', 'major');
      expect(chord, isNotNull);
      expect(chord!.displayName, 'C');
    });

    test('find returns null for missing chord', () {
      final ChordRepository repo = ChordRepository(chords);
      expect(repo.find('X', 'major'), isNull);
    });

    test('forLevel returns open chords for level 1', () {
      final ChordRepository repo = ChordRepository(chords);
      final List<Chord> level1 = repo.forLevel(1);
      expect(level1.length, 3);
    });

    test('pitchClasses are derived from midi', () {
      final Chord chord = chords.first;
      expect(chord.positions.first.pitchClasses, <int>{0, 4, 7});
    });
  });
}
