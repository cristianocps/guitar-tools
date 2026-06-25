import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:music_tools/core/audio/audio_capture_service.dart';
import 'package:music_tools/core/audio/guitar_synth.dart';
import 'package:music_tools/core/audio/pitch_challenge_validator.dart';
import 'package:music_tools/core/audio/pitch_detector.dart';
import 'package:music_tools/core/audio/providers.dart';
import 'package:music_tools/core/chords/chord_diagram_painter.dart';
import 'package:music_tools/core/chords/chord_models.dart';
import 'package:music_tools/core/chords/chord_repository.dart';
import 'package:music_tools/core/settings/settings.dart';
import 'package:music_tools/core/settings/settings_providers.dart';
import 'package:music_tools/core/theme/app_colors.dart';
import 'package:music_tools/core/training/models/exercise_definition.dart';
import 'package:music_tools/core/training/providers/training_providers.dart';
import 'package:music_tools/core/training/repositories/training_progress_repository.dart';

import 'chord_learn_controller.dart';

final _chordLearnControllerProvider = StateNotifierProvider.autoDispose.family
    <ChordLearnController, ChordLearnSessionState, ExerciseDefinition>(
  (Ref ref, ExerciseDefinition definition) {
    final String chordKey = definition.parameters['key'] as String;
    final String chordSuffix = definition.parameters['suffix'] as String;
    final AsyncValue<ChordRepository> repoAsync = ref.watch(chordRepositoryProvider);
    final Chord chord = repoAsync.when(
      data: (ChordRepository repo) => repo.find(chordKey, chordSuffix)!,
      loading: () => throw StateError('Chord database not loaded'),
      error: (Object e, _) => throw StateError('Failed to load chord database: $e'),
    );

    final Stream<PitchEvent> pitchStream = ref.watch(rawPitchStreamProvider);
    final AudioCaptureService capture = ref.watch(audioCaptureServiceProvider);
    final PitchChallengeValidator validator = ref.watch(pitchChallengeValidatorProvider);
    final TrainingProgressRepository repository = ref.watch(trainingProgressRepositoryProvider);
    final GuitarSynth synth = ref.watch(guitarSynthProvider);
    final GuitarTone tone = ref.watch(guitarToneProvider);
    final InstrumentPlayer player = InstrumentPlayer(synth: synth, tone: tone);

    final AppSettings settings = ref.watch(settingsProvider);

    final ChordLearnController controller = ChordLearnController(
      definition: definition,
      chord: chord,
      pitchStream: pitchStream,
      capture: capture,
      validator: validator,
      repository: repository,
      player: player,
      onFinished: () {},
      loopEnabled: settings.chordLoopEnabled,
      loopBpm: settings.chordLoopBpm,
      loopBeatsPerBar: settings.chordLoopBeatsPerBar,
    );
    ref.onDispose(controller.dispose);
    return controller;
  },
);

/// Chord learning screen.
class ChordLearnScreen extends ConsumerWidget {
  const ChordLearnScreen({required this.definition, super.key});

  final ExerciseDefinition definition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ChordLearnSessionState state = ref.watch(_chordLearnControllerProvider(definition));
    final ChordLearnController controller =
        ref.read(_chordLearnControllerProvider(definition).notifier);

    return Scaffold(
      appBar: AppBar(title: Text(state.chord.displayName)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              state.chord.displayName,
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 24),
            ChordDiagram(
              position: state.currentPosition,
              size: const Size(200, 240),
            ),
            const SizedBox(height: 24),
            if (state.chord.positions.length > 1)
              Wrap(
                spacing: 8,
                children: List<Widget>.generate(
                  state.chord.positions.length,
                  (int index) => ChoiceChip(
                    label: Text('Posição ${index + 1}'),
                    selected: state.positionIndex == index,
                    onSelected: (_) => controller.selectPosition(index),
                  ),
                ),
              ),
            const SizedBox(height: 32),
            _FeedbackBadge(result: state.result),
            const SizedBox(height: 16),
            Text(
              controller.loopEnabled
                  ? 'Tocando em loop...'
                  : state.isPlayingReference
                      ? 'Ouça o acorde...'
                      : state.isListening
                          ? 'Toque o acorde...'
                          : state.result == ChordLearnResult.correct
                              ? 'Correto!'
                              : state.result == ChordLearnResult.wrong
                                  ? 'Tente novamente'
                                  : '',
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
            ElevatedButton.icon(
              onPressed: controller.playReference,
              icon: const Icon(Icons.replay),
              label: const Text('Ouvir de novo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackBadge extends StatelessWidget {
  const _FeedbackBadge({required this.result});

  final ChordLearnResult result;

  @override
  Widget build(BuildContext context) {
    switch (result) {
      case ChordLearnResult.correct:
        return _badge('Acertou!', AppColors.inTune);
      case ChordLearnResult.wrong:
        return _badge('Errou', AppColors.sharp);
      case ChordLearnResult.idle:
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
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
