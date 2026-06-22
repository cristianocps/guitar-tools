import '../music_theory/note.dart';

/// Validates whether a detected pitch matches an expected pitch class,
/// ignoring octave differences.
class PitchChallengeValidator {
  const PitchChallengeValidator();

  /// Tolerance in cents for considering a detected note as the target.
  static const double centsTolerance = 50;

  /// Returns true if [detectedFrequency] corresponds to [expectedPitchClass].
  bool matches(double detectedFrequency, int expectedPitchClass) {
    final TuningReading? reading = noteFromFrequency(detectedFrequency);
    if (reading == null) {
      return false;
    }
    if (reading.centsOff > centsTolerance) {
      return false;
    }
    return reading.nearest.pitchClass ==
        (((expectedPitchClass % 12) + 12) % 12);
  }
}
