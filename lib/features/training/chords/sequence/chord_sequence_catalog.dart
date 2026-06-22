import 'package:music_tools/core/chords/chord_models.dart';
import 'package:music_tools/core/chords/chord_repository.dart';
import 'package:music_tools/core/training/models/exercise_definition.dart';
import 'package:music_tools/core/training/models/exercise_type.dart';

/// Catalog of chord sequence levels / progressions.
class ChordSequenceCatalog {
  static List<ExerciseDefinition> buildDefinitions({int count = 6}) {
    return List<ExerciseDefinition>.generate(
      count,
      (int index) {
        final int level = index + 1;
        final int bpm = 60 + (index * 8);
        final List<String> progression = _progressionForLevel(level);
        return ExerciseDefinition(
          id: 'chord-sequence-$level',
          type: ExerciseType.techniqueExercises,
          level: level,
          title: 'Sequência de Acordes $level',
          description: 'Toque a progressão: ${progression.join(' - ')}',
          parameters: <String, dynamic>{
            'mode': 'chordSequence',
            'level': level,
            'bpm': bpm,
            'progression': progression,
            'barsPerChord': 1,
          },
          unlockedByDefault: level == 1,
        );
      },
    );
  }

  static List<Chord> resolveProgression(
    ExerciseDefinition definition,
    ChordRepository repository,
  ) {
    final List<dynamic> raw = definition.parameters['progression'] as List<dynamic>;
    final List<String> names = raw.cast<String>();
    return names
        .map((String name) {
          final List<String> parts = _parseChordName(name);
          return repository.find(parts[0], parts[1]);
        })
        .whereType<Chord>()
        .toList(growable: false);
  }

  static List<String> _progressionForLevel(int level) {
    switch (level) {
      case 1:
        return <String>['C', 'G', 'Am', 'F'];
      case 2:
        return <String>['G', 'D', 'Em', 'C'];
      case 3:
        return <String>['C', 'Am', 'F', 'G'];
      case 4:
        return <String>['D', 'G', 'Bm', 'A'];
      case 5:
        return <String>['E', 'C#m', 'A', 'B'];
      default:
        return <String>['F', 'Dm', 'Bb', 'C'];
    }
  }

  static List<String> _parseChordName(String name) {
    if (name.endsWith('m')) {
      return <String>[name.substring(0, name.length - 1), 'minor'];
    }
    return <String>[name, 'major'];
  }
}
