import '../music_theory/note.dart';

/// Validates whether a detected pitch matches an expected pitch class,
/// ignoring octave differences.
class PitchChallengeValidator {
  const PitchChallengeValidator();

  /// Tolerance in cents for considering a detected note as the target.
  static const double centsTolerance = 50;

  /// Returns true if [detectedFrequency] corresponds to [expectedPitchClass],
  /// ignoring the octave.
  bool matches(double detectedFrequency, int expectedPitchClass) {
    final TuningReading? reading = noteFromFrequency(detectedFrequency);
    if (reading == null) {
      return false;
    }
    if (reading.centsOff.abs() > centsTolerance) {
      return false;
    }
    return reading.nearest.pitchClass ==
        (((expectedPitchClass % 12) + 12) % 12);
  }

  /// Returns true if [detectedFrequency] corresponds to the exact note
  /// [expectedMidi] (octave-specific). Use this where the exercise asks for a
  /// note at a precise string/fret, so the same pitch class an octave away
  /// (e.g. a different string) is not accepted as correct.
  bool matchesNote(double detectedFrequency, int expectedMidi) {
    final TuningReading? reading = noteFromFrequency(detectedFrequency);
    if (reading == null) {
      return false;
    }
    if (reading.centsOff.abs() > centsTolerance) {
      return false;
    }
    return reading.nearest.midi == expectedMidi;
  }
}
