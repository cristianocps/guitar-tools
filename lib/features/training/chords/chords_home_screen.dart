import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:music_tools/core/chords/chord_models.dart';
import 'package:music_tools/core/chords/chord_repository.dart';
import 'package:music_tools/core/training/models/exercise_definition.dart';
import 'package:music_tools/core/training/models/exercise_type.dart';
import 'package:music_tools/features/training/exercise_list_screen.dart';

import 'challenge/chord_challenge_catalog.dart';
import 'challenge/chord_challenge_screen.dart';
import 'learn/chord_learn_screen.dart';
import 'sequence/chord_sequence_catalog.dart';
import 'sequence/chord_sequence_screen.dart';

/// Home screen for the chords module.
class ChordsHomeScreen extends StatelessWidget {
  const ChordsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acordes')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _ModuleCard(
              icon: Icons.school,
              title: 'Aprender',
              subtitle: 'Aprenda acordes com som e diagrama',
              onTap: () => _openLearnList(context),
            ),
            const SizedBox(height: 12),
            _ModuleCard(
              icon: Icons.emoji_events,
              title: 'Desafio',
              subtitle: 'Toque os acordes solicitados contra o tempo',
              onTap: () => _openChallengeList(context),
            ),
            const SizedBox(height: 12),
            _ModuleCard(
              icon: Icons.queue_music,
              title: 'Sequência',
              subtitle: 'Troque de acorde no tempo do metrônomo',
              onTap: () => _openSequenceList(context),
            ),
          ],
        ),
      ),
    );
  }

  void _openLearnList(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => Consumer(
          builder: (BuildContext context, WidgetRef ref, _) {
            final AsyncValue<ChordRepository> repoAsync = ref.watch(chordRepositoryProvider);
            return repoAsync.when(
              data: (ChordRepository repo) => ExerciseListScreen(
                title: 'Aprender Acordes',
                definitions: _buildLearnDefinitions(repo),
                exerciseBuilder: (ExerciseDefinition d) => ChordLearnScreen(definition: d),
              ),
              loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (Object e, _) => Scaffold(
                body: Center(child: Text('Erro: $e')),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openChallengeList(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ExerciseListScreen(
          title: 'Desafio de Acordes',
          definitions: ChordChallengeCatalog.buildDefinitions(),
          exerciseBuilder: (ExerciseDefinition d) => ChordChallengeScreen(definition: d),
        ),
      ),
    );
  }

  void _openSequenceList(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ExerciseListScreen(
          title: 'Sequência de Acordes',
          definitions: ChordSequenceCatalog.buildDefinitions(),
          exerciseBuilder: (ExerciseDefinition d) => ChordSequenceScreen(definition: d),
        ),
      ),
    );
  }

  List<ExerciseDefinition> _buildLearnDefinitions(ChordRepository repo) {
    final List<Chord> chords = repo.forLevel(1);
    return chords.map((Chord chord) {
      return ExerciseDefinition(
        id: 'chord-learn-${chord.key}-${chord.suffix}',
        type: ExerciseType.techniqueExercises,
        level: 1,
        title: chord.displayName,
        description: 'Aprenda o acorde ${chord.displayName}',
        parameters: <String, dynamic>{
          'key': chord.key,
          'suffix': chord.suffix,
        },
        unlockedByDefault: true,
      );
    }).toList(growable: false);
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
