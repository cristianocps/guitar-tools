import 'note.dart';

/// A string of a guitar in a given tuning.
class GuitarString {
  const GuitarString({
    required this.number,
    required this.note,
    required this.commonName,
  });

  /// 1 = high E ... 6 = low E (standard numbering).
  final int number;

  final Note note;

  /// Short label, e.g. "6E" (low E), "1E" (high E).
  final String commonName;

  /// Frequency of the open string for a configurable [a4Reference].
  double frequencyOf(double a4Reference) => note.frequencyOf(a4Reference);

  @override
  String toString() => '$commonName (${note.fullName()})';
}

/// A guitar tuning: a display name plus its open strings ordered low → high
/// (string 6 down to string 1).
class Tuning {
  const Tuning({required this.name, required this.strings});

  final String name;

  /// Low → high (string 6 down to string 1).
  final List<GuitarString> strings;

  @override
  bool operator ==(Object other) =>
      other is Tuning && name == other.name && _sameStrings(other.strings);

  bool _sameStrings(List<GuitarString> other) {
    if (strings.length != other.length) {
      return false;
    }
    for (int i = 0; i < strings.length; i++) {
      if (strings[i].note != other[i].note ||
          strings[i].number != other[i].number) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(name, Object.hashAll(strings));

  @override
  String toString() => name;
}

/// Identifiers for the built-in tuning presets.
enum TuningPresetId { standard, dropD, dadgad, openG, halfStepDown }

/// A built-in tuning preset.
class TuningPreset {
  const TuningPreset._(this.id, this.tuning);

  final TuningPresetId id;

  final Tuning tuning;

  /// All built-in presets, in display order.
  static const List<TuningPreset> all = <TuningPreset>[
    standard,
    dropD,
    dadgad,
    openG,
    halfStepDown,
  ];

  /// Resolves a preset [id] to its [TuningPreset].
  static TuningPreset byId(TuningPresetId id) => all.firstWhere(
        (TuningPreset preset) => preset.id == id,
        orElse: () => standard,
      );

  /// Standard tuning (E2 A2 D3 G3 B3 E4), low → high.
  static const TuningPreset standard = TuningPreset._(
    TuningPresetId.standard,
    Tuning(
      name: 'Padrão (E A D G B E)',
      strings: _standardStrings,
    ),
  );

  /// Drop D (D2 A2 D3 G3 B3 E4), low → high.
  static const TuningPreset dropD = TuningPreset._(
    TuningPresetId.dropD,
    Tuning(
      name: 'Drop D',
      strings: <GuitarString>[
        GuitarString(number: 6, note: Note(2, 2), commonName: '6D'),
        GuitarString(number: 5, note: Note(9, 2), commonName: '5A'),
        GuitarString(number: 4, note: Note(2, 3), commonName: '4D'),
        GuitarString(number: 3, note: Note(7, 3), commonName: '3G'),
        GuitarString(number: 2, note: Note(11, 3), commonName: '2B'),
        GuitarString(number: 1, note: Note(4, 4), commonName: '1E'),
      ],
    ),
  );

  /// DADGAD (D2 A2 D3 G3 A3 D4), low → high.
  static const TuningPreset dadgad = TuningPreset._(
    TuningPresetId.dadgad,
    Tuning(
      name: 'DADGAD',
      strings: <GuitarString>[
        GuitarString(number: 6, note: Note(2, 2), commonName: '6D'),
        GuitarString(number: 5, note: Note(9, 2), commonName: '5A'),
        GuitarString(number: 4, note: Note(2, 3), commonName: '4D'),
        GuitarString(number: 3, note: Note(7, 3), commonName: '3G'),
        GuitarString(number: 2, note: Note(9, 3), commonName: '2A'),
        GuitarString(number: 1, note: Note(2, 4), commonName: '1D'),
      ],
    ),
  );

  /// Open G (D2 G2 D3 G3 B3 D4), low → high.
  static const TuningPreset openG = TuningPreset._(
    TuningPresetId.openG,
    Tuning(
      name: 'Open G',
      strings: <GuitarString>[
        GuitarString(number: 6, note: Note(2, 2), commonName: '6D'),
        GuitarString(number: 5, note: Note(7, 2), commonName: '5G'),
        GuitarString(number: 4, note: Note(2, 3), commonName: '4D'),
        GuitarString(number: 3, note: Note(7, 3), commonName: '3G'),
        GuitarString(number: 2, note: Note(11, 3), commonName: '2B'),
        GuitarString(number: 1, note: Note(2, 4), commonName: '1D'),
      ],
    ),
  );

  /// Half-step down (E♭2 A♭2 D♭3 G♭3 B♭3 E♭4), low → high.
  static const TuningPreset halfStepDown = TuningPreset._(
    TuningPresetId.halfStepDown,
    Tuning(
      name: 'Half-Step Down',
      strings: <GuitarString>[
        GuitarString(number: 6, note: Note(3, 2), commonName: '6Eb'),
        GuitarString(number: 5, note: Note(8, 2), commonName: '5Ab'),
        GuitarString(number: 4, note: Note(1, 3), commonName: '4Db'),
        GuitarString(number: 3, note: Note(6, 3), commonName: '3Gb'),
        GuitarString(number: 2, note: Note(10, 3), commonName: '2Bb'),
        GuitarString(number: 1, note: Note(3, 4), commonName: '1Eb'),
      ],
    ),
  );
}

/// Standard tuning strings (E2 A2 D3 G3 B3 E4), low → high.
const List<GuitarString> _standardStrings = <GuitarString>[
  GuitarString(number: 6, note: Note(4, 2), commonName: '6E'),
  GuitarString(number: 5, note: Note(9, 2), commonName: '5A'),
  GuitarString(number: 4, note: Note(2, 3), commonName: '4D'),
  GuitarString(number: 3, note: Note(7, 3), commonName: '3G'),
  GuitarString(number: 2, note: Note(11, 3), commonName: '2B'),
  GuitarString(number: 1, note: Note(4, 4), commonName: '1E'),
];

/// Standard tuning, ordered low → high (string 6 down to string 1).
///
/// Prefer [TuningPreset.standard.tuning.strings] in new code.
@Deprecated('Use TuningPreset.standard.tuning.strings instead.')
const List<GuitarString> standardTuning = _standardStrings;
