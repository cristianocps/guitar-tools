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
  });
}
