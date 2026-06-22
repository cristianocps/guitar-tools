import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/training/models/exercise_definition.dart';
import '../../../core/training/providers/training_providers.dart';
import 'ear_training_controller.dart';
import 'ear_training_generator.dart';

final _earTrainingControllerProvider = StateNotifierProvider.autoDispose
    .family<EarTrainingController, EarTrainingSessionState,
        ExerciseDefinition>((Ref ref, ExerciseDefinition definition) {
  final pitchStream = ref.watch(rawPitchStreamProvider);
  final validator = ref.watch(pitchChallengeValidatorProvider);
  final repository = ref.watch(trainingProgressRepositoryProvider);
  final player = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);

  final controller = EarTrainingController(
    definition: definition,
    pitchStream: pitchStream,
    validator: validator,
    repository: repository,
    player: player,
    onFinished: () {},
  );
  ref.onDispose(controller.dispose);
  return controller;
});

/// Ear training exercise screen.
class EarTrainingScreen extends ConsumerWidget {
  const EarTrainingScreen({required this.definition, super.key});

  final ExerciseDefinition definition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_earTrainingControllerProvider(definition));
    final controller =
        ref.read(_earTrainingControllerProvider(definition).notifier);

    return Scaffold(
      appBar: AppBar(title: Text(definition.title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Toque a segunda nota do intervalo',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              state.challenge != null
                  ? '${pitchClassName(state.challenge!.root.pitchClass)} → ?'
                  : '',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 16),
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
                  onPressed: controller.repeat,
                  icon: const Icon(Icons.replay),
                  label: const Text('Repetir'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed:
                      state.isListening ? controller.stopListening : controller.startListening,
                  icon: Icon(
                    state.isListening ? Icons.mic : Icons.mic_none,
                  ),
                  label: Text(state.isListening ? 'Ouvindo...' : 'Ouvir'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.result == EarTrainingResult.wrong)
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

  final EarTrainingResult result;

  @override
  Widget build(BuildContext context) {
    switch (result) {
      case EarTrainingResult.correct:
        return _badge('Acertou!', AppColors.inTune);
      case EarTrainingResult.wrong:
        return _badge('Errou', AppColors.sharp);
      case EarTrainingResult.finished:
        return _badge('Concluído!', AppColors.primary);
      case EarTrainingResult.idle:
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
        style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
