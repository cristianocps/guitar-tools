import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/guitar_synth.dart';
import '../../../core/audio/providers.dart';
import '../../../core/metronome_engine/click_player.dart';
import '../../../core/metronome_engine/metronome_engine.dart';
import '../../../core/music_theory/pitch.dart';
import '../../../core/settings/settings_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/training/models/exercise_definition.dart';
import '../../../core/training/providers/training_providers.dart';
import 'technique_exercise_controller.dart';

final _techniqueControllerProvider = StateNotifierProvider.autoDispose.family
    <TechniqueExerciseController, TechniqueSessionState, ExerciseDefinition>(
  (Ref ref, ExerciseDefinition definition) {
    final pitchStream = ref.watch(rawPitchStreamProvider);
    final validator = ref.watch(pitchChallengeValidatorProvider);
    final repository = ref.watch(trainingProgressRepositoryProvider);
    final engine = MetronomeEngine(
      onBeat: (_, __) {},
      bpm: (definition.parameters['bpm'] as int?)?.clamp(20, 200) ?? 80,
    );
    final clickPlayer = ClickPlayer();
    final player = InstrumentPlayer(
      synth: ref.watch(guitarSynthProvider),
      tone: ref.watch(guitarToneProvider),
    );

    final controller = TechniqueExerciseController(
      definition: definition,
      pitchStream: pitchStream,
      validator: validator,
      repository: repository,
      engine: engine,
      clickPlayer: clickPlayer,
      player: player,
      onFinished: () {},
    );
    ref.onDispose(controller.dispose);
    return controller;
  },
);

/// Technique exercise screen.
class TechniqueExercisesScreen extends ConsumerWidget {
  const TechniqueExercisesScreen({required this.definition, super.key});

  final ExerciseDefinition definition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_techniqueControllerProvider(definition));
    final controller =
        ref.read(_techniqueControllerProvider(definition).notifier);
    final currentNote = state.currentNote;

    return Scaffold(
      appBar: AppBar(title: Text(definition.title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              definition.description,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              currentNote != null
                  ? PitchNames.name(
                      currentNote.pitchClass,
                      notation: Notation.solfeggio,
                    )
                  : '-',
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
            const SizedBox(height: 8),
            Text(
              'Nota ${state.currentIndex + 1}/${state.sequence.length}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            if (!state.isPlaying && state.result != TechniqueResult.finished)
              ElevatedButton.icon(
                onPressed: controller.start,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar'),
              )
            else if (state.isPlaying)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton.icon(
                    onPressed: controller.markWrong,
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Pular'),
                  ),
                ],
              )
            else
              Text(
                'Concluído!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.inTune,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackBadge extends StatelessWidget {
  const _FeedbackBadge({required this.result});

  final TechniqueResult result;

  @override
  Widget build(BuildContext context) {
    switch (result) {
      case TechniqueResult.correct:
        return _badge('Acertou!', AppColors.inTune);
      case TechniqueResult.wrong:
        return _badge('Errou', AppColors.sharp);
      case TechniqueResult.finished:
        return _badge('Concluído!', AppColors.primary);
      case TechniqueResult.idle:
      case TechniqueResult.playing:
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
