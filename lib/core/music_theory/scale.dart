// Scales and modes as semitone-offset patterns from a tonic pitch class.

/// Supported scale qualities for harmonic-field generation.
enum ScaleType {
  major,
  naturalMinor,
  pentatonicMajor,
  pentatonicMinor,
}

/// Semitone offsets of the major (Ionian) scale.
const List<int> majorScaleIntervals = <int>[0, 2, 4, 5, 7, 9, 11];

/// Semitone offsets of the natural minor (Aeolian) scale.
const List<int> naturalMinorScaleIntervals = <int>[0, 2, 3, 5, 7, 8, 10];

/// Semitone offsets of the major pentatonic scale.
const List<int> pentatonicMajorScaleIntervals = <int>[0, 2, 4, 7, 9];

/// Semitone offsets of the minor pentatonic scale.
const List<int> pentatonicMinorScaleIntervals = <int>[0, 3, 5, 7, 10];

/// Returns the interval list for [type].
List<int> scaleIntervals(ScaleType type) {
  switch (type) {
    case ScaleType.major:
      return majorScaleIntervals;
    case ScaleType.naturalMinor:
      return naturalMinorScaleIntervals;
    case ScaleType.pentatonicMajor:
      return pentatonicMajorScaleIntervals;
    case ScaleType.pentatonicMinor:
      return pentatonicMinorScaleIntervals;
  }
}

/// The pitch classes of [type] built on [tonicPitchClass].
List<int> scalePitchClasses(int tonicPitchClass, ScaleType type) {
  final int tonic = ((tonicPitchClass % 12) + 12) % 12;
  return scaleIntervals(type)
      .map((int offset) => (tonic + offset) % 12)
      .toList(growable: false);
}
