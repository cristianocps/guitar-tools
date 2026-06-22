import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/providers.dart';
import '../../../core/metronome_engine/click_player.dart';
import '../../../core/metronome_engine/metronome_engine.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/training/models/exercise_definition.dart';
import '../../../core/training/providers/training_providers.dart';
import 'rhythm_exercise_controller.dart';
import 'rhythm_pattern_catalog.dart';

final _rhythmControllerProvider = StateNotifierProvider.autoDispose
    .family<RhythmExerciseController, RhythmSessionState, ExerciseDefinition>(
  (Ref ref, ExerciseDefinition definition) {
    final capture = ref.watch(audioCaptureServiceProvider);
    final rhythmDetector = ref.watch(rhythmDetectorProvider);
    final repository = ref.watch(trainingProgressRepositoryProvider);
    final engine = MetronomeEngine(
      onBeat: (_, __) {},
      bpm: (definition.parameters['bpm'] as int?)?.clamp(20, 280) ?? 80,
    );
    final player = ClickPlayer();

    final controller = RhythmExerciseController(
      definition: definition,
      engine: engine,
      clickPlayer: player,
      rhythmDetector: rhythmDetector,
      capture: capture,
      repository: repository,
      onFinished: () {},
    );
    ref.onDispose(controller.dispose);
    return controller;
  },
);

/// Rhythm exercise screen.
class RhythmExercisesScreen extends ConsumerWidget {
  const RhythmExercisesScreen({required this.definition, super.key});

  final ExerciseDefinition definition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_rhythmControllerProvider(definition));
    final controller =
        ref.read(_rhythmControllerProvider(definition).notifier);
    final pattern = RhythmPatternCatalog.patternFor(definition);

    return Scaffold(
      appBar: AppBar(title: Text(definition.title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              pattern.name,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${pattern.durations.length} batidas a ${controller.definitionBpm} BPM',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            Text(
              'Acertos: ${state.hits}/${state.expectedBeats.length}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Onsets detectados: ${state.onsetCount}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            _FeedbackBadge(result: state.result),
            const SizedBox(height: 32),
            if (!state.isPlaying && state.result != RhythmResult.finished)
              ElevatedButton.icon(
                onPressed: controller.start,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar'),
              )
            else if (state.isPlaying)
              ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.mic),
                label: const Text('Tocando...'),
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

  final RhythmResult result;

  @override
  Widget build(BuildContext context) {
    switch (result) {
      case RhythmResult.playing:
        return _badge('Toque junto!', AppColors.primary);
      case RhythmResult.finished:
        return _badge('Concluído!', AppColors.inTune);
      case RhythmResult.idle:
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
