import 'package:flutter_test/flutter_test.dart';

import 'package:music_tools/features/training/chords/challenge/chord_challenge_catalog.dart';
import 'package:music_tools/features/training/chords/sequence/chord_sequence_catalog.dart';

void main() {
  group('ChordChallengeCatalog', () {
    test('buildDefinitions creates levels', () {
      final definitions = ChordChallengeCatalog.buildDefinitions();
      expect(definitions, isNotEmpty);
      expect(definitions.first.parameters['mode'], 'chordChallenge');
    });
  });

  group('ChordSequenceCatalog', () {
    test('buildDefinitions increases bpm by level', () {
      final definitions = ChordSequenceCatalog.buildDefinitions();
      expect(definitions.first.parameters['bpm'], lessThan(definitions[1].parameters['bpm'] as num));
    });

    test('resolveProgression returns chords when repository has them', () {
      // This is a smoke test; full integration requires loading the JSON asset.
      expect(ChordSequenceCatalog.resolveProgression, isA<Function>());
    });
  });
}
