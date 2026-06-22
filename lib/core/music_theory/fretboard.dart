import 'note.dart';

/// Standard guitar tuning from lowest (6th string) to highest (1st string).
const List<Note> standardGuitarTuning = <Note>[
  Note(4, 2), // E2
  Note(9, 2), // A2
  Note(2, 3), // D3
  Note(7, 3), // G3
  Note(11, 3), // B3
  Note(4, 4), // E4
];

/// Number of frets to model on the guitar fretboard.
const int guitarFretCount = 15;

/// Returns the note at [stringIndex] (0 = 6th/low E) and [fret].
Note noteAtFretPosition(int stringIndex, int fret) {
  assert(
    stringIndex >= 0 && stringIndex < standardGuitarTuning.length,
    'stringIndex must be within standard guitar strings',
  );
  assert(fret >= 0 && fret <= guitarFretCount, 'fret out of range');
  final Note open = standardGuitarTuning[stringIndex];
  return Note.fromMidi(open.midi + fret);
}

/// Returns all (string, fret) positions that produce [pitchClass] within the
/// modeled fretboard range. Strings are 0-based from low E.
List<({int string, int fret})> findFretPositions(int pitchClass) {
  final List<({int string, int fret})> positions = <({int string, int fret})>[];
  final int target = ((pitchClass % 12) + 12) % 12;
  for (int s = 0; s < standardGuitarTuning.length; s++) {
    final int openPc = standardGuitarTuning[s].pitchClass;
    for (int f = 0; f <= guitarFretCount; f++) {
      if ((openPc + f) % 12 == target) {
        positions.add((string: s, fret: f));
      }
    }
  }
  return positions;
}
