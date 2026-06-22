import 'package:music_tools/core/chords/chord_models.dart';
import 'package:music_tools/core/chords/chord_repository.dart';
import 'package:music_tools/core/training/models/exercise_definition.dart';
import 'package:music_tools/core/training/models/exercise_type.dart';

/// Catalog of chord challenge levels.
class ChordChallengeCatalog {
  static List<ExerciseDefinition> buildDefinitions({int count = 8}) {
    return List<ExerciseDefinition>.generate(
      count,
      (int index) {
        final int level = index + 1;
        final List<String> keys = _keysForLevel(level);
        final List<String> suffixes = _suffixesForLevel(level);
        return ExerciseDefinition(
          id: 'chord-challenge-$level',
          type: ExerciseType.techniqueExercises,
          level: level,
          title: 'Desafio de Acordes $level',
          description: 'Toque os acordes solicitados (${keys.join(', ')}).',
          parameters: <String, dynamic>{
            'mode': 'chordChallenge',
            'level': level,
            'keys': keys,
            'suffixes': suffixes,
            'timeLimitMs': 5000 + (count - index) * 500,
            'rounds': 5 + level,
          },
          unlockedByDefault: level == 1,
        );
      },
    );
  }

  static List<Chord> chordsForLevel(
    int level,
    ChordRepository repository,
  ) {
    final List<String> keys = _keysForLevel(level);
    final List<String> suffixes = _suffixesForLevel(level);
    final List<Chord> result = <Chord>[];
    for (final String key in keys) {
      for (final String suffix in suffixes) {
        final Chord? chord = repository.find(key, suffix);
        if (chord != null) {
          result.add(chord);
        }
      }
    }
    return result;
  }

  static List<String> _keysForLevel(int level) {
    const List<String> base = <String>[
      'C',
      'G',
      'D',
      'E',
      'A',
      'F',
      'Am',
      'Em',
      'Dm',
    ];
    if (level == 1) {
      return base.sublist(0, 4);
    }
    if (level == 2) {
      return base.sublist(0, 6);
    }
    if (level == 3) {
      return base;
    }
    return <String>[...base, 'Bb', 'Bm', 'C#', 'F#'];
  }

  static List<String> _suffixesForLevel(int level) {
    if (level == 1) {
      return <String>['major', 'minor'];
    }
    if (level == 2) {
      return <String>['major', 'minor', '7'];
    }
    if (level == 3) {
      return <String>['major', 'minor', '7', 'm7'];
    }
    return <String>[
      'major',
      'minor',
      '7',
      'm7',
      'maj7',
      'sus2',
      'sus4',
    ];
  }
}
