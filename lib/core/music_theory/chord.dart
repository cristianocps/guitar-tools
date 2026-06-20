import 'pitch.dart';
import 'scale.dart';

/// Triad quality derived from stacked thirds within a scale.
enum TriadQuality {
  major,
  minor,
  diminished,
  augmented,
}

extension TriadQualityX on TriadQuality {
  /// Interval (in semitones) from the root to the third.
  int get thirdInterval {
    switch (this) {
      case TriadQuality.major:
      case TriadQuality.augmented:
        return 4;
      case TriadQuality.minor:
      case TriadQuality.diminished:
        return 3;
    }
  }

  /// Interval (in semitones) from the root to the fifth.
  int get fifthInterval {
    switch (this) {
      case TriadQuality.major:
      case TriadQuality.minor:
        return 7;
      case TriadQuality.diminished:
        return 6;
      case TriadQuality.augmented:
        return 8;
    }
  }

  /// Chord-symbol suffix (e.g. "" for major, "m" for minor, "°" for diminished).
  String get suffix {
    switch (this) {
      case TriadQuality.major:
        return '';
      case TriadQuality.minor:
        return 'm';
      case TriadQuality.diminished:
        return '°';
      case TriadQuality.augmented:
        return '+';
    }
  }

  /// Uppercase (major/augmented) vs lowercase (minor/diminished) — used for
  /// roman-numeral casing.
  bool get isMajorQuality =>
      this == TriadQuality.major || this == TriadQuality.augmented;
}

/// Classifies a triad from its third and fifth intervals (in semitones).
TriadQuality classifyTriadQuality({required int third, required int fifth}) {
  if (third == 4 && fifth == 8) {
    return TriadQuality.augmented;
  }
  if (third == 3 && fifth == 6) {
    return TriadQuality.diminished;
  }
  if (third == 4) {
    return TriadQuality.major;
  }
  return TriadQuality.minor;
}

/// A triad chord: a root pitch class plus a quality.
class Chord {
  const Chord({required this.rootPitchClass, required this.quality});

  final int rootPitchClass;
  final TriadQuality quality;

  /// Pitch classes that make up the chord (root, third, fifth).
  List<int> get pitchClasses => <int>[
        rootPitchClass,
        (rootPitchClass + quality.thirdInterval) % 12,
        (rootPitchClass + quality.fifthInterval) % 12,
      ];

  /// Root note name plus quality suffix, e.g. "C", "Dm", "B°".
  String name({
    Notation notation = Notation.letters,
    AccidentalStyle accidental = AccidentalStyle.sharp,
  }) =>
      '${PitchNames.name(rootPitchClass, notation: notation, accidental: accidental)}${quality.suffix}';

  @override
  String toString() => name();
}

/// Roman numeral labels for the seven scale degrees.
const List<String> _romanNumerals = <String>[
  'I',
  'II',
  'III',
  'IV',
  'V',
  'VI',
  'VII',
];

/// One degree of a harmonic field.
class HarmonicDegree {
  const HarmonicDegree({
    required this.index,
    required this.chord,
    required this.scaleType,
  });

  /// 0-based degree index (0 = I).
  final int index;

  final Chord chord;

  final ScaleType scaleType;

  /// Roman numeral with correct casing and a quality symbol
  /// (e.g. "I", "ii", "ii°", "IV", "VII"). Minor triads are lowercase without
  /// an "m" suffix; only diminished/augmented carry a symbol.
  String get romanNumeral {
    String numeral = _romanNumerals[index];
    if (!chord.quality.isMajorQuality) {
      numeral = numeral.toLowerCase();
    }
    switch (chord.quality) {
      case TriadQuality.diminished:
        return '$numeral°';
      case TriadQuality.augmented:
        return '$numeral+';
      case TriadQuality.major:
      case TriadQuality.minor:
        return numeral;
    }
  }
}
