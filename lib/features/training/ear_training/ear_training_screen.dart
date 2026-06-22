import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/guitar_synth.dart';
import '../../../core/audio/mic_permission_gate.dart';
import '../../../core/audio/providers.dart';
import '../../../core/settings/settings_providers.dart';
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
  final player = InstrumentPlayer(
    synth: ref.watch(guitarSynthProvider),
    tone: ref.watch(guitarToneProvider),
  );

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
class EarTrainingScreen extends StatelessWidget {
  const EarTrainingScreen({required this.definition, super.key});

  final ExerciseDefinition definition;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(definition.title)),
      body: MicPermissionGate(
        message:
            'Tocamos o intervalo e ouvimos a nota que você toca para conferir o acerto.',
        child: _EarTrainingBody(definition: definition),
      ),
    );
  }
}

class _EarTrainingBody extends ConsumerWidget {
  const _EarTrainingBody({required this.definition});

  final ExerciseDefinition definition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_earTrainingControllerProvider(definition));
    final controller =
        ref.read(_earTrainingControllerProvider(definition).notifier);

    return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Descubra a 2ª nota de ouvido',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Soam duas notas: a 1ª é a referência (mostrada abaixo) e a 2ª é '
              'a resposta. Guarde a distância entre elas, descubra a 2ª e '
              'toque-a no instrumento. Toque em “Repetir” para ouvir de novo.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              definition.description,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              state.challenge != null
                  ? '1ª: ${pitchClassName(state.challenge!.root.pitchClass)}   →   2ª: ?'
                  : '',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _PhaseBanner(state: state),
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
      );
  }
}

/// Tells the user, at a glance, whether the app is currently playing the
/// interval or waiting for them to play the answer.
class _PhaseBanner extends StatelessWidget {
  const _PhaseBanner({required this.state});

  final EarTrainingSessionState state;

  @override
  Widget build(BuildContext context) {
    if (state.result == EarTrainingResult.finished) {
      return const SizedBox.shrink();
    }

    final bool listening = state.isListening;
    final Color color = listening ? AppColors.inTune : AppColors.primary;
    final IconData icon = listening ? Icons.graphic_eq : Icons.volume_up;
    final String label = listening
        ? 'Sua vez — toque a 2ª nota'
        : 'Ouça o intervalo...';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
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
