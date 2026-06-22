import 'dart:math';

import '../../../core/music_theory/interval.dart';
import '../../../core/music_theory/note.dart';
import '../../../core/music_theory/pitch.dart';
import '../../../core/training/models/exercise_definition.dart';
import '../../../core/training/models/exercise_type.dart';

/// Challenge produced by [EarTrainingLevelGenerator].
class EarTrainingChallenge {
  EarTrainingChallenge({
    required this.root,
    required this.target,
    required this.interval,
  });

  final Note root;
  final Note target;
  final DiatonicInterval interval;
}

/// Generates ear-training interval challenges.
class EarTrainingLevelGenerator {
  static final Random _random = Random();

  /// Creates a list of [count] interval definitions for [level].
  static List<ExerciseDefinition> buildDefinitions({int count = 12}) {
    return List<ExerciseDefinition>.generate(
      count,
      (int index) {
        final int level = index + 1;
        final List<int> semitones = _semitonesForLevel(level);
        return ExerciseDefinition(
          id: 'ear-training-$level',
          type: ExerciseType.earTraining,
          level: level,
          title: 'Intervalos $level',
          description:
              'Identifique ${_intervalNames(semitones).join(', ')} ascendentes.',
          parameters: <String, dynamic>{
            'semitones': semitones,
          },
          unlockedByDefault: level == 1,
        );
      },
    );
  }

  /// Generates a random challenge for a given level definition.
  static EarTrainingChallenge generate(ExerciseDefinition definition) {
    final List<dynamic> raw = definition.parameters['semitones'] as List<dynamic>;
    final List<int> semitones = raw.cast<int>();
    final int semitonesDistance = semitones[_random.nextInt(semitones.length)];
    final int rootPc = _random.nextInt(12);
    // Keep root in a guitar-friendly octave (C3..B4).
    final int octave = 3 + _random.nextInt(2);
    final Note root = Note(rootPc, octave);
    final Note target = noteAtInterval(root, semitonesDistance);
    final DiatonicInterval interval = DiatonicInterval.fromSemitones(
      semitonesDistance,
    )!;
    return EarTrainingChallenge(
      root: root,
      target: target,
      interval: interval,
    );
  }

  static List<int> _semitonesForLevel(int level) {
    switch (level) {
      case 1:
        return <int>[4, 7]; // 3ª maior, 5ª justa
      case 2:
        return <int>[2, 4, 7]; // 2ª maior, 3ª maior, 5ª justa
      case 3:
        return <int>[2, 4, 5, 7]; // + 4ª justa
      case 4:
        return <int>[2, 3, 4, 5, 7]; // + 3ª menor
      case 5:
        return <int>[2, 3, 4, 5, 7, 9]; // + 6ª maior
      case 6:
        return <int>[1, 2, 3, 4, 5, 7, 9]; // + 2ª menor
      case 7:
        return <int>[1, 2, 3, 4, 5, 7, 8, 9]; // + 6ª menor
      case 8:
        return <int>[1, 2, 3, 4, 5, 7, 8, 9, 11]; // + 7ª maior
      case 9:
        return <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 11]; // + trítono
      case 10:
        return <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]; // + 7ª menor
      case 11:
        return <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]; // + oitava
      default:
        return <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
    }
  }

  static List<String> _intervalNames(List<int> semitones) {
    return semitones
        .map(
          (int s) => DiatonicInterval.fromSemitones(s)?.displayName ?? '$s st',
        )
        .toList(growable: false);
  }
}

/// Human-readable name for a pitch class (solfeggio, sharps).
String pitchClassName(int pitchClass) {
  return PitchNames.name(pitchClass, notation: Notation.solfeggio);
}
