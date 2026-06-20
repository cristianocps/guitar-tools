/// Pitch-class utilities (12-tone equal temperament, A4 = 440 Hz).
///
/// A pitch class is an integer 0..11 where C = 0:
/// C=0, C#/Db=1, D=2, D#/Eb=3, E=4, F=5, F#/Gb=6, G=7, G#/Ab=8, A=9, A#/Bb=10, B=11.
library;

/// How note names are rendered to users.
enum Notation {
  /// C, C#, D, ... B
  letters,

  /// Dó, Ré, Mi, ... Si (Brazilian solfège).
  solfeggio,
}

/// Accidental preference when a pitch class has two names (e.g. C#/Db).
enum AccidentalStyle {
  /// Prefer sharps (C#, D#, ...).
  sharp,

  /// Prefer flats (Db, Eb, ...).
  flat,
}

/// Pitch-class name tables.
abstract final class PitchNames {
  static const List<String> _sharp = <String>[
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];
  static const List<String> _flat = <String>[
    'C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B',
  ];
  static const List<String> _solfeggioSharp = <String>[
    'Dó', 'Dó#', 'Ré', 'Ré#', 'Mi', 'Fá', 'Fá#', 'Sol', 'Sol#', 'Lá', 'Lá#', 'Si',
  ];
  static const List<String> _solfeggioFlat = <String>[
    'Dó', 'Réb', 'Ré', 'Mib', 'Mi', 'Fá', 'Solb', 'Sol', 'Láb', 'Lá', 'Sib', 'Si',
  ];

  /// Human-readable name for [pitchClass] (0..11).
  static String name(
    int pitchClass, {
    Notation notation = Notation.letters,
    AccidentalStyle accidental = AccidentalStyle.sharp,
  }) {
    final int pc = ((pitchClass % 12) + 12) % 12;
    switch (notation) {
      case Notation.letters:
        return accidental == AccidentalStyle.flat ? _flat[pc] : _sharp[pc];
      case Notation.solfeggio:
        return accidental == AccidentalStyle.flat
            ? _solfeggioFlat[pc]
            : _solfeggioSharp[pc];
    }
  }
}
