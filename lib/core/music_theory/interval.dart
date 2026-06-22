import 'note.dart';

/// Diatonic intervals by semitone distance.
enum DiatonicInterval {
  minorSecond('2ª menor', 1),
  majorSecond('2ª maior', 2),
  minorThird('3ª menor', 3),
  majorThird('3ª maior', 4),
  perfectFourth('4ª justa', 5),
  tritone('4ª aumentada / 5ª diminuta', 6),
  perfectFifth('5ª justa', 7),
  minorSixth('6ª menor', 8),
  majorSixth('6ª maior', 9),
  minorSeventh('7ª menor', 10),
  majorSeventh('7ª maior', 11),
  octave('8ª justa', 12);

  const DiatonicInterval(this.displayName, this.semitones);

  final String displayName;
  final int semitones;

  static DiatonicInterval? fromSemitones(int semitones) {
    final int normalized = ((semitones % 12) + 12) % 12;
    for (final DiatonicInterval interval in values) {
      if (interval.semitones == normalized) {
        return interval;
      }
    }
    return null;
  }
}

/// Builds the note that is [semitones] above [root].
Note noteAtInterval(Note root, int semitones) {
  final int totalSemitones = root.midi + semitones;
  return Note.fromMidi(totalSemitones);
}

/// Returns the normalized semitone distance from [fromPitchClass] to [toPitchClass].
int pitchClassInterval(int fromPitchClass, int toPitchClass) {
  final int from = ((fromPitchClass % 12) + 12) % 12;
  final int to = ((toPitchClass % 12) + 12) % 12;
  return (to - from + 12) % 12;
}
