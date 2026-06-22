import '../../../core/training/models/exercise_definition.dart';
import '../../../core/training/models/exercise_type.dart';

/// A rhythmic subdivision pattern expressed as relative durations.
/// 1 = quarter note, 0.5 = eighth, etc.
class RhythmPattern {
  RhythmPattern({
    required this.name,
    required this.durations,
    required this.subdivisionName,
  });

  final String name;
  final List<double> durations;
  final String subdivisionName;
}

/// Catalog of rhythm exercise patterns by level.
class RhythmPatternCatalog {
  static List<ExerciseDefinition> buildDefinitions({int count = 8}) {
    return List<ExerciseDefinition>.generate(
      count,
      (int index) {
        final int level = index + 1;
        final RhythmPattern pattern = _patternForLevel(level);
        return ExerciseDefinition(
          id: 'rhythm-$level',
          type: ExerciseType.rhythmExercises,
          level: level,
          title: 'Ritmo $level',
          description: pattern.name,
          parameters: <String, dynamic>{
            'durations': pattern.durations,
            'subdivisionName': pattern.subdivisionName,
            'bpm': 60 + (level * 5),
          },
          unlockedByDefault: level == 1,
        );
      },
    );
  }

  static RhythmPattern patternFor(ExerciseDefinition definition) {
    final List<dynamic> raw = definition.parameters['durations'] as List<dynamic>;
    return RhythmPattern(
      name: definition.description,
      durations: raw.cast<double>(),
      subdivisionName: definition.parameters['subdivisionName'] as String,
    );
  }

  static RhythmPattern _patternForLevel(int level) {
    switch (level) {
      case 1:
        return RhythmPattern(
          name: 'Semínimas',
          durations: <double>[1, 1, 1, 1],
          subdivisionName: 'Semínimas',
        );
      case 2:
        return RhythmPattern(
          name: 'Colcheias',
          durations: <double>[0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5],
          subdivisionName: 'Colcheias',
        );
      case 3:
        return RhythmPattern(
          name: 'Semínima + colcheias',
          durations: <double>[1, 0.5, 0.5, 1, 0.5, 0.5],
          subdivisionName: 'Colcheias',
        );
      case 4:
        return RhythmPattern(
          name: 'Síncopa básica',
          durations: <double>[0.5, 1, 0.5, 0.5, 1, 0.5],
          subdivisionName: 'Colcheias',
        );
      case 5:
        return RhythmPattern(
          name: 'Síncopa com colcheias',
          durations: <double>[0.5, 0.5, 0.5, 1, 0.5, 0.5, 0.5, 0.5],
          subdivisionName: 'Colcheias',
        );
      case 6:
        return RhythmPattern(
          name: 'Tercinas',
          durations: <double>[
            2 / 3,
            2 / 3,
            2 / 3,
            2 / 3,
            2 / 3,
            2 / 3,
            2 / 3,
            2 / 3,
            2 / 3,
          ],
          subdivisionName: 'Tercinas',
        );
      case 7:
        return RhythmPattern(
          name: 'Colcheia pontuada + semicolcheia',
          durations: <double>[0.75, 0.25, 0.75, 0.25, 0.75, 0.25, 0.75, 0.25],
          subdivisionName: 'Semicolcheias',
        );
      default:
        return RhythmPattern(
          name: 'Misto avançado',
          durations: <double>[1, 0.5, 0.5, 0.75, 0.25, 1, 0.5, 0.5],
          subdivisionName: 'Colcheias / semicolcheias',
        );
    }
  }
}
