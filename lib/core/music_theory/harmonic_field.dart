import 'chord.dart';
import 'scale.dart';

export 'chord.dart';
export 'scale.dart';

/// Builds the campo harmônico (harmonic field): the seven diatonic triads of a
/// key, by stacking thirds over each scale degree.
List<HarmonicDegree> buildHarmonicField(
  int tonicPitchClass,
  ScaleType type,
) {
  final int tonic = ((tonicPitchClass % 12) + 12) % 12;
  final List<int> pattern = scaleIntervals(type);

  HarmonicDegree degree(int i) {
    final int root = tonic + pattern[i];
    final int thirdAbs =
        tonic + pattern[(i + 2) % 7] + (i + 2 >= 7 ? 12 : 0);
    final int fifthAbs =
        tonic + pattern[(i + 4) % 7] + (i + 4 >= 7 ? 12 : 0);
    final int thirdInterval = thirdAbs - root;
    final int fifthInterval = fifthAbs - root;
    final TriadQuality quality = classifyTriadQuality(
      third: thirdInterval,
      fifth: fifthInterval,
    );
    return HarmonicDegree(
      index: i,
      chord: Chord(rootPitchClass: root % 12, quality: quality),
      scaleType: type,
    );
  }

  return List<HarmonicDegree>.generate(7, degree, growable: false);
}

/// Snapshot of a harmonic field for a given key.
class HarmonicField {
  const HarmonicField({
    required this.tonicPitchClass,
    required this.scaleType,
    required this.degrees,
  });

  final int tonicPitchClass;
  final ScaleType scaleType;
  final List<HarmonicDegree> degrees;

  factory HarmonicField.of(int tonicPitchClass, ScaleType scaleType) {
    return HarmonicField(
      tonicPitchClass: ((tonicPitchClass % 12) + 12) % 12,
      scaleType: scaleType,
      degrees: buildHarmonicField(tonicPitchClass, scaleType),
    );
  }
}
