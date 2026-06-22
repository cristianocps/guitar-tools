import 'dart:math';

import '../../../core/music_theory/fretboard.dart';
import '../../../core/music_theory/note.dart';
import '../../../core/music_theory/pitch.dart';
import '../../../core/music_theory/scale.dart';
import '../../../core/training/models/exercise_definition.dart';
import '../../../core/training/models/exercise_type.dart';

/// A technique exercise definition.
class TechniqueExercise {
  TechniqueExercise({
    required this.scaleType,
    required this.tonic,
    required this.baseBpm,
    required this.direction,
  });

  final ScaleType scaleType;
  final int tonic;
  final int baseBpm;
  final TechniqueDirection direction;
}

enum TechniqueDirection { ascending, descending }

/// Catalog of technique exercises (scales/arpeggios) by level.
class TechniqueExerciseCatalog {
  static List<ExerciseDefinition> buildDefinitions({int count = 12}) {
    final Random random = Random();
    return List<ExerciseDefinition>.generate(
      count,
      (int index) {
        final int level = index + 1;
        final ScaleType scaleType = ScaleType.values[index % ScaleType.values.length];
        final int tonic = random.nextInt(12);
        final int bpm = 60 + (index * 5);
        final TechniqueDirection direction =
            index.isEven ? TechniqueDirection.ascending : TechniqueDirection.descending;
        return ExerciseDefinition(
          id: 'technique-$level',
          type: ExerciseType.techniqueExercises,
          level: level,
          title: 'Digitação $level',
          description:
              'Escala ${PitchNames.name(tonic, notation: Notation.solfeggio)} '
              '${_scaleName(scaleType)} ${direction == TechniqueDirection.ascending ? 'ascendente' : 'descendente'}.',
          parameters: <String, dynamic>{
            'scaleType': scaleType.index,
            'tonic': tonic,
            'bpm': bpm,
            'direction': direction.index,
          },
          unlockedByDefault: level == 1,
        );
      },
    );
  }

  static TechniqueExercise exerciseFor(ExerciseDefinition definition) {
    final int scaleIndex = definition.parameters['scaleType'] as int;
    final int tonic = definition.parameters['tonic'] as int;
    final int bpm = (definition.parameters['bpm'] as int?)?.clamp(20, 200) ?? 80;
    final int directionIndex = definition.parameters['direction'] as int;
    return TechniqueExercise(
      scaleType: ScaleType.values[scaleIndex],
      tonic: tonic,
      baseBpm: bpm,
      direction: TechniqueDirection.values[directionIndex],
    );
  }

  static List<Note> buildNoteSequence(ExerciseDefinition definition) {
    final TechniqueExercise exercise = exerciseFor(definition);
    final List<int> pitchClasses = scalePitchClasses(
      exercise.tonic,
      exercise.scaleType,
    );
    final List<Note> notes = <Note>[];
    for (final int pc in pitchClasses) {
      final List<({int string, int fret})> positions = findFretPositions(pc);
      final ({int string, int fret}) pos = positions.first;
      notes.add(noteAtFretPosition(pos.string, pos.fret));
    }
    if (exercise.direction == TechniqueDirection.descending) {
      notes.add(
        noteAtFretPosition(
          0,
          findFretPositions(exercise.tonic).first.fret + 12,
        ),
      );
      return notes.reversed.toList(growable: false);
    }
    // Add octave to complete the scale.
    notes.add(Note.fromMidi(notes.last.midi + 12));
    return notes;
  }

  static String _scaleName(ScaleType type) {
    switch (type) {
      case ScaleType.major:
        return 'maior';
      case ScaleType.naturalMinor:
        return 'menor natural';
      case ScaleType.pentatonicMajor:
        return 'pentatônica maior';
      case ScaleType.pentatonicMinor:
        return 'pentatônica menor';
    }
  }
}
