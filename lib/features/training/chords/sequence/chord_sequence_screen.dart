import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:music_tools/core/audio/audio_capture_service.dart';
import 'package:music_tools/core/audio/pitch_detector.dart';
import 'package:music_tools/core/audio/providers.dart';
import 'package:music_tools/core/audio/rhythm_detector.dart';
import 'package:music_tools/core/chords/chord_diagram_painter.dart';
import 'package:music_tools/core/chords/chord_models.dart';
import 'package:music_tools/core/chords/chord_repository.dart';
import 'package:music_tools/core/metronome_engine/click_player.dart';
import 'package:music_tools/core/metronome_engine/metronome_engine.dart';
import 'package:music_tools/core/theme/app_colors.dart';
import 'package:music_tools/core/training/models/exercise_definition.dart';
import 'package:music_tools/core/training/providers/training_providers.dart';
import 'package:music_tools/core/training/repositories/training_progress_repository.dart';

import 'chord_sequence_catalog.dart';
import 'chord_sequence_controller.dart';

final _chordSequenceControllerProvider = StateNotifierProvider.autoDispose
    .family<ChordSequenceController, ChordSequenceSessionState,
        ExerciseDefinition>(
  (Ref ref, ExerciseDefinition definition) {
    final AsyncValue<ChordRepository> repoAsync = ref.watch(chordRepositoryProvider);
    final List<Chord> chords = repoAsync.when(
      data: (ChordRepository repo) => ChordSequenceCatalog.resolveProgression(definition, repo),
      loading: () => throw StateError('Chord database not loaded'),
      error: (Object e, _) => throw StateError('Failed to load chord database: $e'),
    );

    final Stream<PitchEvent> pitchStream = ref.watch(rawPitchStreamProvider);
    final AudioCaptureService capture = ref.watch(audioCaptureServiceProvider);
    final RhythmDetector rhythmDetector = ref.watch(rhythmDetectorProvider);
    final TrainingProgressRepository repository = ref.watch(trainingProgressRepositoryProvider);
    final int bpm = (definition.parameters['bpm'] as int?)?.clamp(20, 200) ?? 80;
    final MetronomeEngine engine = MetronomeEngine(
      onBeat: (_, __) {},
      bpm: bpm,
    );
    final ClickPlayer clickPlayer = ClickPlayer();

    final ChordSequenceController controller = ChordSequenceController(
      definition: definition,
      chords: chords,
      pitchStream: pitchStream,
      engine: engine,
      clickPlayer: clickPlayer,
      rhythmDetector: rhythmDetector,
      capture: capture,
      repository: repository,
      onFinished: () {},
    );
    ref.onDispose(controller.dispose);
    return controller;
  },
);

/// Chord sequence screen.
class ChordSequenceScreen extends ConsumerWidget {
  const ChordSequenceScreen({required this.definition, super.key});

  final ExerciseDefinition definition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ChordSequenceSessionState state = ref.watch(_chordSequenceControllerProvider(definition));
    final ChordSequenceController controller =
        ref.read(_chordSequenceControllerProvider(definition).notifier);

    return Scaffold(
      appBar: AppBar(title: Text(definition.title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Agora',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.result == ChordSequenceResult.finished
                  ? 'Concluído!'
                  : state.currentChord.displayName,
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 24),
            if (state.result != ChordSequenceResult.finished)
              ChordDiagram(
                position: state.currentChord.positions.first,
                size: const Size(180, 220),
              ),
            const SizedBox(height: 24),
            if (state.nextChord != null)
              Text(
                'Próximo: ${state.nextChord!.displayName}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            const SizedBox(height: 32),
            Text(
              'Acertos: ${state.correctCount}/${state.chords.length}',
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
            const SizedBox(height: 32),
            if (!state.isPlaying && state.result != ChordSequenceResult.finished)
              ElevatedButton.icon(
                onPressed: controller.start,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar'),
              )
            else if (state.isPlaying)
              const Text('Tocando...')
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
