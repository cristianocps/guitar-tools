import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/mic_permission_gate.dart';
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
class RhythmExercisesScreen extends StatelessWidget {
  const RhythmExercisesScreen({required this.definition, super.key});

  final ExerciseDefinition definition;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(definition.title)),
      body: MicPermissionGate(
        message:
            'Você ouve uma contagem de 1 compasso e depois toca o ritmo; ouvimos pelo microfone para medir sua precisão.',
        child: _RhythmBody(definition: definition),
      ),
    );
  }
}

class _RhythmBody extends ConsumerWidget {
  const _RhythmBody({required this.definition});

  final ExerciseDefinition definition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_rhythmControllerProvider(definition));
    final controller =
        ref.read(_rhythmControllerProvider(definition).notifier);
    final pattern = RhythmPatternCatalog.patternFor(definition);

    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          children: <Widget>[
            Text(
              pattern.name,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '${pattern.durations.length} batidas · ${controller.definitionBpm} BPM',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.textTheme.bodySmall?.color),
            ),
            const Spacer(),
            _RhythmStage(state: state),
            const SizedBox(height: 24),
            _StatusLine(state: state),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: _ActionButton(state: state, onStart: controller.start),
            ),
          ],
        ),
      ),
    );
  }
}

/// The large circular focal point that adapts to the session phase.
class _RhythmStage extends StatelessWidget {
  const _RhythmStage({required this.state});

  final RhythmSessionState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    late final Color color;
    late final Widget center;
    late final String caption;

    switch (state.result) {
      case RhythmResult.idle:
        color = AppColors.primary;
        caption = 'Toque o botão para começar';
        center = Icon(Icons.music_note, size: 64, color: color);
      case RhythmResult.countIn:
        color = AppColors.primary;
        caption = 'Ouça o tempo (1 compasso)';
        center = Text(
          '${state.countInValue}',
          style: theme.textTheme.displayLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        );
      case RhythmResult.playing:
        color = AppColors.primary;
        caption = 'Toque o ritmo (sem metrônomo)';
        center = Icon(Icons.graphic_eq, size: 64, color: color);
      case RhythmResult.finished:
        color = AppColors.inTune;
        caption = 'Concluído';
        center = Text(
          '${(state.accuracy * 100).round()}%',
          style: theme.textTheme.displaySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        );
    }

    return Column(
      children: <Widget>[
        Container(
          width: 200,
          height: 200,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.08),
            border: Border.all(color: color.withOpacity(0.5), width: 2),
          ),
          child: center,
        ),
        const SizedBox(height: 16),
        Text(
          caption,
          style: theme.textTheme.titleMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}

/// Hits / detected-onsets summary shown under the stage.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.state});

  final RhythmSessionState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        _stat(theme, 'Acertos', '${state.hits}/${state.expectedBeats.length}'),
        _stat(theme, 'Detectadas', '${state.onsetCount}'),
      ],
    );
  }

  Widget _stat(ThemeData theme, String label, String value) {
    return Column(
      children: <Widget>[
        Text(value, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.state, required this.onStart});

  final RhythmSessionState state;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    switch (state.result) {
      case RhythmResult.idle:
        return FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Iniciar'),
        );
      case RhythmResult.countIn:
        return FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.hourglass_top),
          label: const Text('Prepare-se...'),
        );
      case RhythmResult.playing:
        return FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.mic),
          label: const Text('Toque o ritmo!'),
        );
      case RhythmResult.finished:
        return FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.replay),
          label: const Text('Repetir'),
        );
    }
  }
}

