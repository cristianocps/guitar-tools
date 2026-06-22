import 'dart:math';

import '../../../core/music_theory/fretboard.dart';
import '../../../core/music_theory/note.dart';
import '../../../core/music_theory/pitch.dart';
import '../../../core/music_theory/scale.dart';
import '../../../core/training/models/exercise_definition.dart';
import '../../../core/training/models/exercise_type.dart';

/// Modes of the fretboard trainer.
enum FretboardMode { locateNote, scaleRunner }

/// A challenge for the fretboard trainer.
class FretboardChallenge {
  FretboardChallenge({
    required this.targetPitchClass,
    required this.stringIndex,
    required this.fret,
    this.scaleNotes,
    this.currentScaleIndex,
  });

  final int targetPitchClass;
  final int stringIndex;
  final int fret;
  final List<int>? scaleNotes;
  final int? currentScaleIndex;

  Note get expectedNote => noteAtFretPosition(stringIndex, fret);
}

/// Generates fretboard trainer challenges.
class FretboardChallengeGenerator {
  static final Random _random = Random();

  static List<ExerciseDefinition> buildLocateDefinitions({int count = 12}) {
    return List<ExerciseDefinition>.generate(
      count,
      (int index) {
        final int level = index + 1;
        return ExerciseDefinition(
          id: 'fretboard-locate-$level',
          type: ExerciseType.fretboardTrainer,
          level: level,
          title: 'Localize a nota $level',
          description: 'Toque a nota solicitada na corda e casa indicadas.',
          parameters: <String, dynamic>{
            'mode': 'locateNote',
            'allowedStrings': level <= 4
                ? <int>[0, 1, 2, 3, 4, 5]
                : <int>[0, 1, 2, 3, 4, 5],
          },
          unlockedByDefault: level == 1,
        );
      },
    );
  }

  static List<ExerciseDefinition> buildScaleDefinitions({int count = 8}) {
    final List<ScaleType> scales = <ScaleType>[
      ScaleType.major,
      ScaleType.naturalMinor,
      ScaleType.pentatonicMajor,
      ScaleType.pentatonicMinor,
    ];
    return List<ExerciseDefinition>.generate(
      count,
      (int index) {
        final int level = index + 1;
        final ScaleType scale = scales[index % scales.length];
        final int tonic = _random.nextInt(12);
        return ExerciseDefinition(
          id: 'fretboard-scale-$level',
          type: ExerciseType.fretboardTrainer,
          level: level,
          title: 'Scale Runner $level',
          description:
              'Toque a escala ${PitchNames.name(tonic, notation: Notation.solfeggio)}.',
          parameters: <String, dynamic>{
            'mode': 'scaleRunner',
            'scaleType': scale.index,
            'tonic': tonic,
          },
          unlockedByDefault: level == 1,
        );
      },
    );
  }

  static FretboardMode modeFrom(ExerciseDefinition definition) {
    final String mode = definition.parameters['mode'] as String? ?? 'locateNote';
    return mode == 'scaleRunner'
        ? FretboardMode.scaleRunner
        : FretboardMode.locateNote;
  }

  static FretboardChallenge generateLocate(ExerciseDefinition definition) {
    final int stringIndex = _random.nextInt(standardGuitarTuning.length);
    final int fret = _random.nextInt(guitarFretCount + 1);
    final Note note = noteAtFretPosition(stringIndex, fret);
    return FretboardChallenge(
      targetPitchClass: note.pitchClass,
      stringIndex: stringIndex,
      fret: fret,
    );
  }

  static List<FretboardChallenge> generateScaleSequence(
    ExerciseDefinition definition,
  ) {
    final int scaleIndex = definition.parameters['scaleType'] as int;
    final int tonic = definition.parameters['tonic'] as int;
    final ScaleType scaleType = ScaleType.values[scaleIndex];
    final List<int> notes = scalePitchClasses(tonic, scaleType);

    // Build one challenge per scale degree using any valid position.
    final List<FretboardChallenge> challenges = <FretboardChallenge>[];
    for (int i = 0; i < notes.length; i++) {
      final int pc = notes[i];
      final List<({int string, int fret})> positions = findFretPositions(pc);
      final ({int string, int fret}) pos =
          positions[_random.nextInt(positions.length)];
      challenges.add(
        FretboardChallenge(
          targetPitchClass: pc,
          stringIndex: pos.string,
          fret: pos.fret,
          scaleNotes: notes,
          currentScaleIndex: i,
        ),
      );
    }
    return challenges;
  }
}

/// Human-readable string for a guitar string (1 = high E).
String guitarStringName(int stringIndex) {
  const List<String> names = <String>['E (6ª)', 'A (5ª)', 'D (4ª)', 'G (3ª)', 'B (2ª)', 'E (1ª)'];
  return names[stringIndex];
}
