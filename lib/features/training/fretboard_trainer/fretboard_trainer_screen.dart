import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/providers.dart';
import '../../../core/music_theory/pitch.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/training/models/exercise_definition.dart';
import '../../../core/training/providers/training_providers.dart';
import 'fretboard_challenge_generator.dart';
import 'fretboard_controller.dart';

final _fretboardControllerProvider = StateNotifierProvider.autoDispose.family
    <FretboardController, FretboardSessionState, ExerciseDefinition>(
  (Ref ref, ExerciseDefinition definition) {
    final pitchStream = ref.watch(rawPitchStreamProvider);
    final validator = ref.watch(pitchChallengeValidatorProvider);
    final repository = ref.watch(trainingProgressRepositoryProvider);
    // Tones are generated as in-memory WAV and played via BytesSource, which
    // the low-latency (SoundPool) backend rejects — use the media player mode.
    final player = AudioPlayer()..setPlayerMode(PlayerMode.mediaPlayer);
    final controller = FretboardController(
      definition: definition,
      pitchStream: pitchStream,
      validator: validator,
      repository: repository,
      player: player,
      onFinished: () {},
    );
    ref.onDispose(controller.dispose);
    return controller;
  },
);

/// Fretboard trainer exercise screen.
class FretboardTrainerScreen extends ConsumerWidget {
  const FretboardTrainerScreen({required this.definition, super.key});

  final ExerciseDefinition definition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_fretboardControllerProvider(definition));
    final controller =
        ref.read(_fretboardControllerProvider(definition).notifier);
    final challenge = state.challenge;

    return Scaffold(
      appBar: AppBar(title: Text(definition.title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              challenge != null
                  ? 'Toque ${PitchNames.name(challenge.targetPitchClass, notation: Notation.solfeggio)}'
                  : '',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              challenge != null
                  ? '${guitarStringName(challenge.stringIndex)} - ${challenge.fret}ª casa'
                  : '',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            Text(
              'Detectado: ${state.detectedNote ?? '-'}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            _FeedbackBadge(result: state.result),
            const SizedBox(height: 32),
            Text(
              '${state.correctCount}/${state.totalCount} acertos',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton.icon(
                  onPressed: controller.playTarget,
                  icon: const Icon(Icons.music_note),
                  label: const Text('Ouvir nota'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed:
                      state.isListening ? controller.stopListening : controller.startListening,
                  icon: Icon(state.isListening ? Icons.mic : Icons.mic_none),
                  label: Text(state.isListening ? 'Ouvindo...' : 'Ouvir'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: controller.markWrong,
              child: const Text('Pular / Marcar erro'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackBadge extends StatelessWidget {
  const _FeedbackBadge({required this.result});

  final FretboardResult result;

  @override
  Widget build(BuildContext context) {
    switch (result) {
      case FretboardResult.correct:
        return _badge('Acertou!', AppColors.inTune);
      case FretboardResult.wrong:
        return _badge('Errou', AppColors.sharp);
      case FretboardResult.finished:
        return _badge('Concluído!', AppColors.primary);
      case FretboardResult.idle:
        return const SizedBox.shrink();
    }
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
