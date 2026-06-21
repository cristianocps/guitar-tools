import 'package:flutter_test/flutter_test.dart';
import 'package:music_tools/core/music_theory/note.dart';

void main() {
  group('Note + frequency conversion', () {
    test('A4 == 440 Hz', () {
      const Note a4 = Note(9, 4);
      expect(a4.midi, 69);
      expect(a4.frequency.toStringAsFixed(2), '440.00');
      expect(a4.fullName(), 'A4');
    });

    test('Note.fromMidi round trip', () {
      const Note a4 = Note(9, 4);
      expect(Note.fromMidi(69), a4);
      // Middle C (C4) is MIDI 60.
      expect(Note.fromMidi(60), const Note(0, 4));
    });

    test('noteFromFrequency classifies cents', () {
      final TuningReading? r = noteFromFrequency(440);
      expect(r, isNotNull);
      expect(r!.nearest, const Note(9, 4));
      expect(r.cents.abs(), lessThan(0.5));

      // 1% sharp of A4 → ~17 cents sharp.
      final TuningReading? sharp = noteFromFrequency(440 * 1.01);
      expect(sharp!.nearest, const Note(9, 4));
      expect(sharp.cents, greaterThan(10));
      expect(sharp.state, TuningState.sharp);

      // A bit flat of A4 (still nearest A4): 432 Hz ≈ -31.8 cents.
      final TuningReading? flat = noteFromFrequency(432);
      expect(flat!.nearest, const Note(9, 4));
      expect(flat.cents, lessThan(0));
      expect(flat.state, TuningState.flat);
    });

    test('noteFromFrequency returns null for non-positive', () {
      expect(noteFromFrequency(0), isNull);
      expect(noteFromFrequency(-1), isNull);
    });

    test('frequencyOf honors a configurable A4 reference', () {
      const Note a4 = Note(9, 4);
      // A4 reference of 442 Hz shifts A4's frequency accordingly.
      expect(a4.frequencyOf(442).toStringAsFixed(2), '442.00');
      // Default getter still returns 440 Hz.
      expect(a4.frequency.toStringAsFixed(2), '440.00');
      // Semitone relationship is preserved regardless of the reference.
      const Note a5 = Note(9, 5);
      expect(a5.frequencyOf(442), closeTo(442 * 2, 0.001));
    });

    test('noteFromFrequency honors a configurable A4 reference', () {
      // With A4 = 442 Hz, 442 Hz is exactly in tune (0 cents).
      final TuningReading? inTune = noteFromFrequency(442, a4Reference: 442);
      expect(inTune, isNotNull);
      expect(inTune!.nearest, const Note(9, 4));
      expect(inTune.cents.abs(), lessThan(0.5));

      // With A4 = 442 Hz, 440 Hz is now slightly flat.
      final TuningReading? flat = noteFromFrequency(440, a4Reference: 442);
      expect(flat, isNotNull);
      expect(flat!.nearest, const Note(9, 4));
      expect(flat.cents, lessThan(0));
      expect(flat.state, TuningState.flat);
    });
  });
}
