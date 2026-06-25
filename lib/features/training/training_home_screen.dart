import 'package:flutter/material.dart';

import '../../core/training/models/exercise_definition.dart';
import '../../core/training/models/exercise_type.dart';
import 'chords/chords_home_screen.dart';
import 'ear_training/ear_training_generator.dart';
import 'ear_training/ear_training_screen.dart';
import 'exercise_list_screen.dart';
import 'fretboard_trainer/fretboard_challenge_generator.dart';
import 'fretboard_trainer/fretboard_trainer_screen.dart';
import 'rhythm_exercises/rhythm_exercises_screen.dart';
import 'rhythm_exercises/rhythm_pattern_catalog.dart';
import 'technique_exercises/technique_exercise_catalog.dart';
import 'technique_exercises/technique_exercises_screen.dart';

/// Home screen for the training tab.
class TrainingHomeScreen extends StatelessWidget {
  const TrainingHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Treino')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _ModuleCard(
              icon: Icons.hearing,
              title: 'Ear Training',
              subtitle: 'Identifique intervalos',
              onTap: () => _openList(
                context,
                ExerciseType.earTraining,
                'Ear Training',
                EarTrainingLevelGenerator.buildDefinitions(),
                (ExerciseDefinition d) => EarTrainingScreen(definition: d),
              ),
            ),
            const SizedBox(height: 12),
            _ModuleCard(
              icon: Icons.grid_on,
              title: 'Fretboard Trainer',
              subtitle: 'Localize notas e escalas',
              onTap: () => _openList(
                context,
                ExerciseType.fretboardTrainer,
                'Fretboard Trainer',
                <ExerciseDefinition>[
                  ...FretboardChallengeGenerator.buildLocateDefinitions(),
                  ...FretboardChallengeGenerator.buildScaleDefinitions(),
                ],
                (ExerciseDefinition d) => FretboardTrainerScreen(definition: d),
              ),
            ),
            const SizedBox(height: 12),
            _ModuleCard(
              icon: Icons.music_note,
              title: 'Ritmo',
              subtitle: 'Exercícios rítmicos com metrônomo',
              onTap: () => _openList(
                context,
                ExerciseType.rhythmExercises,
                'Ritmo',
                RhythmPatternCatalog.buildDefinitions(),
                (ExerciseDefinition d) => RhythmExercisesScreen(definition: d),
              ),
            ),
            const SizedBox(height: 12),
            _ModuleCard(
              icon: Icons.fitness_center,
              title: 'Digitação',
              subtitle: 'Escalas e arpégios',
              onTap: () => _openList(
                context,
                ExerciseType.techniqueExercises,
                'Digitação',
                TechniqueExerciseCatalog.buildDefinitions(),
                (ExerciseDefinition d) => TechniqueExercisesScreen(definition: d),
              ),
            ),
            const SizedBox(height: 12),
            _ModuleCard(
              icon: Icons.queue_music,
              title: 'Acordes',
              subtitle: 'Aprenda e pratique acordes',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const ChordsHomeScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openList(
    BuildContext context,
    ExerciseType type,
    String title,
    List<ExerciseDefinition> definitions,
    Widget Function(ExerciseDefinition) builder,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ExerciseListScreen(
          title: title,
          definitions: definitions,
          exerciseBuilder: builder,
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
