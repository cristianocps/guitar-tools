import 'package:flutter_test/flutter_test.dart';
import 'package:music_tools/core/music_theory/note.dart';
import 'package:music_tools/core/music_theory/tuning.dart';

void main() {
  group('Tuning presets', () {
    test('all five presets are present and ordered', () {
      expect(
        TuningPreset.all.map((TuningPreset p) => p.id).toList(),
        <TuningPresetId>[
          TuningPresetId.standard,
          TuningPresetId.dropD,
          TuningPresetId.dadgad,
          TuningPresetId.openG,
          TuningPresetId.halfStepDown,
        ],
      );
    });

    test('byId resolves and falls back to standard', () {
      expect(TuningPreset.byId(TuningPresetId.dropD), TuningPreset.dropD);
      expect(TuningPreset.byId(TuningPresetId.standard), TuningPreset.standard);
    });

    void expectPitches(
      TuningPresetId id,
      List<Note> expected,
    ) {
      final List<Note> actual = TuningPreset.byId(id)
          .tuning
          .strings
          .map((GuitarString s) => s.note)
          .toList();
      expect(actual, expected);
    }

    test('Standard: E2 A2 D3 G3 B3 E4 (low → high)', () {
      expectPitches(
        TuningPresetId.standard,
        <Note>[
          const Note(4, 2),
          const Note(9, 2),
          const Note(2, 3),
          const Note(7, 3),
          const Note(11, 3),
          const Note(4, 4),
        ],
      );
    });

    test('Drop D: D2 A2 D3 G3 B3 E4 (low → high)', () {
      expectPitches(
        TuningPresetId.dropD,
        <Note>[
          const Note(2, 2),
          const Note(9, 2),
          const Note(2, 3),
          const Note(7, 3),
          const Note(11, 3),
          const Note(4, 4),
        ],
      );
    });

    test('DADGAD: D2 A2 D3 G3 A3 D4 (low → high)', () {
      expectPitches(
        TuningPresetId.dadgad,
        <Note>[
          const Note(2, 2),
          const Note(9, 2),
          const Note(2, 3),
          const Note(7, 3),
          const Note(9, 3),
          const Note(2, 4),
        ],
      );
    });

    test('Open G: D2 G2 D3 G3 B3 D4 (low → high)', () {
      expectPitches(
        TuningPresetId.openG,
        <Note>[
          const Note(2, 2),
          const Note(7, 2),
          const Note(2, 3),
          const Note(7, 3),
          const Note(11, 3),
          const Note(2, 4),
        ],
      );
    });

    test('Half-Step Down: Eb2 Ab2 Db3 Gb3 Bb3 Eb4 (low → high)', () {
      expectPitches(
        TuningPresetId.halfStepDown,
        <Note>[
          const Note(3, 2),
          const Note(8, 2),
          const Note(1, 3),
          const Note(6, 3),
          const Note(10, 3),
          const Note(3, 4),
        ],
      );
    });

    test('every preset has 6 strings numbered 6..1 low → high', () {
      for (final TuningPreset preset in TuningPreset.all) {
        final List<int> numbers = preset.tuning.strings
            .map((GuitarString s) => s.number)
            .toList();
        expect(numbers, <int>[6, 5, 4, 3, 2, 1]);
      }
    });

    test('GuitarString.frequencyOf honors A4 reference', () {
      const GuitarString a2 = GuitarString(
        number: 5,
        note: Note(9, 2),
        commonName: '5A',
      );
      // A2 is exactly two octaves below A4.
      expect(a2.frequencyOf(440), closeTo(110, 0.001));
      expect(a2.frequencyOf(442), closeTo(110.5, 0.01));
    });
  });
}
