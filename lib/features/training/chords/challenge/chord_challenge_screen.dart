import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:music_tools/core/audio/audio_capture_service.dart';
import 'package:music_tools/core/audio/pitch_challenge_validator.dart';
import 'package:music_tools/core/audio/pitch_detector.dart';
import 'package:music_tools/core/audio/providers.dart';
import 'package:music_tools/core/chords/chord_diagram_painter.dart';
import 'package:music_tools/core/chords/chord_models.dart';
import 'package:music_tools/core/chords/chord_repository.dart';
import 'package:music_tools/core/theme/app_colors.dart';
import 'package:music_tools/core/training/models/exercise_definition.dart';
import 'package:music_tools/core/training/providers/training_providers.dart';
import 'package:music_tools/core/training/repositories/training_progress_repository.dart';

import 'chord_challenge_catalog.dart';
import 'chord_challenge_controller.dart';

final _chordChallengeControllerProvider = StateNotifierProvider.autoDispose
    .family<ChordChallengeController, ChordChallengeSessionState,
        ExerciseDefinition>(
  (Ref ref, ExerciseDefinition definition) {
    final AsyncValue<ChordRepository> repoAsync = ref.watch(chordRepositoryProvider);
    final List<Chord> chords = repoAsync.when(
      data: (ChordRepository repo) => ChordChallengeCatalog.chordsForLevel(
        definition.parameters['level'] as int,
        repo,
      )..shuffle(),
      loading: () => throw StateError('Chord database not loaded'),
      error: (Object e, _) => throw StateError('Failed to load chord database: $e'),
    );

    final Stream<PitchEvent> pitchStream = ref.watch(rawPitchStreamProvider);
    final AudioCaptureService capture = ref.watch(audioCaptureServiceProvider);
    final PitchChallengeValidator validator = ref.watch(pitchChallengeValidatorProvider);
    final TrainingProgressRepository repository = ref.watch(trainingProgressRepositoryProvider);

    final ChordChallengeController controller = ChordChallengeController(
      definition: definition,
      chords: chords,
      pitchStream: pitchStream,
      capture: capture,
      validator: validator,
      repository: repository,
      onFinished: () {},
    );
    ref.onDispose(controller.dispose);
    return controller;
  },
);

/// Chord challenge screen.
class ChordChallengeScreen extends ConsumerWidget {
  const ChordChallengeScreen({required this.definition, super.key});

  final ExerciseDefinition definition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ChordChallengeSessionState state = ref.watch(_chordChallengeControllerProvider(definition));

    return Scaffold(
      appBar: AppBar(title: Text(definition.title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Toque o acorde',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              state.result == ChordChallengeResult.finished
                  ? 'Concluído!'
                  : state.currentChord.displayName,
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 24),
            if (state.result != ChordChallengeResult.finished)
              ChordDiagram(
                position: state.currentChord.positions.first,
                size: const Size(200, 240),
              ),
            const SizedBox(height: 24),
            if (state.result != ChordChallengeResult.finished)
              LinearProgressIndicator(
                value: state.timeRemainingMs /
                    (state.definition.parameters['timeLimitMs'] as int),
                backgroundColor: AppColors.surface,
                valueColor: AlwaysStoppedAnimation<Color>(
                  state.timeRemainingMs < 1500
                      ? AppColors.sharp
                      : AppColors.primary,
                ),
              ),
            const SizedBox(height: 24),
            Text(
              'Acertos: ${state.correctCount}/${state.currentIndex + (state.result == ChordChallengeResult.finished ? 0 : 1)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (state.detectedNote != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Detectado: ${state.detectedNote}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            const SizedBox(height: 24),
            _FeedbackBadge(result: state.result),
          ],
        ),
      ),
    );
  }
}

class _FeedbackBadge extends StatelessWidget {
  const _FeedbackBadge({required this.result});

  final ChordChallengeResult result;

  @override
  Widget build(BuildContext context) {
    switch (result) {
      case ChordChallengeResult.correct:
        return _badge('Acertou!', AppColors.inTune);
      case ChordChallengeResult.wrong:
        return _badge('Errou', AppColors.sharp);
      case ChordChallengeResult.finished:
        return _badge('Fim!', AppColors.primary);
      case ChordChallengeResult.idle:
        return const SizedBox.shrink();
    }
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
