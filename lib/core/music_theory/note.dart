import 'dart:math';

import 'pitch.dart';

/// A musical note: a pitch class (0..11) plus an octave (e.g. A4 = pc 9, octave 4).
class Note {
  const Note(this.pitchClass, this.octave)
      : assert(pitchClass >= 0 && pitchClass < 12),
        assert(octave >= 0);

  /// 0..11 (C=0).
  final int pitchClass;

  /// Scientific pitch octave (e.g. 4 for A4).
  final int octave;

  /// MIDI note number.
  int get midi => (octave + 1) * 12 + pitchClass;

  /// Frequency in Hz for a configurable A4 reference (12-TET).
  double frequencyOf(double a4Reference) =>
      a4Reference * pow(2, (midi - 69) / 12).toDouble();

  /// Frequency in Hz using the default A4 = 440 Hz (12-TET).
  double get frequency => frequencyOf(440);

  /// Human-readable name (without octave).
  String name({
    Notation notation = Notation.letters,
    AccidentalStyle accidental = AccidentalStyle.sharp,
  }) =>
      PitchNames.name(pitchClass, notation: notation, accidental: accidental);

  /// Name with octave, e.g. "A4".
  String fullName({
    Notation notation = Notation.letters,
    AccidentalStyle accidental = AccidentalStyle.sharp,
  }) =>
      '${name(notation: notation, accidental: accidental)}$octave';

  /// Builds a [Note] from a MIDI note number.
  factory Note.fromMidi(int midi) {
    final int pc = ((midi % 12) + 12) % 12;
    final int oct = (midi ~/ 12) - 1;
    return Note(pc, oct);
  }

  @override
  bool operator ==(Object other) =>
      other is Note && pitchClass == other.pitchClass && octave == other.octave;

  @override
  int get hashCode => Object.hash(pitchClass, octave);

  @override
  String toString() => fullName();
}

/// Result of classifying a detected frequency against the 12-TET grid.
class TuningReading {
  const TuningReading({
    required this.frequency,
    required this.nearest,
    required this.cents,
  });

  /// The raw detected frequency in Hz (0 if unknown).
  final double frequency;

  /// The nearest note on the equal-tempered grid.
  final Note nearest;

  /// Detuning in cents relative to [nearest] (range -50..50).
  final double cents;

  /// Absolute distance from being perfectly in tune, in cents.
  double get centsOff => cents.abs();

  /// True when within [tolerance] cents of the target note.
  bool isInTune({double tolerance = 5}) => centsOff <= tolerance;

  /// Classifies the note as flat, in-tune or sharp.
  TuningState get state {
    if (centsOff <= 5) {
      return TuningState.inTune;
    }
    return cents < 0 ? TuningState.flat : TuningState.sharp;
  }
}

enum TuningState { flat, inTune, sharp }

/// Converts a frequency to its nearest [Note] and the cents offset, using a
/// configurable A4 reference (default 440 Hz).
///
/// Returns null for non-positive frequencies.
TuningReading? noteFromFrequency(
  double frequency, {
  double a4Reference = 440,
}) {
  if (frequency <= 0) {
    return null;
  }
  final double midiFloat = 69 + 12 * (log(frequency / a4Reference) / ln2);
  final int midi = midiFloat.round();
  final double cents = (midiFloat - midi) * 100;
  return TuningReading(
    frequency: frequency,
    nearest: Note.fromMidi(midi),
    cents: cents,
  );
}
