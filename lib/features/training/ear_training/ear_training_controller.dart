import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/pitch_challenge_validator.dart';
import '../../../core/audio/pitch_detector.dart';
import '../../../core/audio/tone_generator.dart';
import '../../../core/music_theory/note.dart';
import '../../../core/music_theory/pitch.dart';
import '../../../core/training/models/exercise_definition.dart';
import '../../../core/training/repositories/training_progress_repository.dart';
import 'ear_training_generator.dart';

/// State of an ear-training exercise session.
class EarTrainingSessionState {
  EarTrainingSessionState({
    required this.definition,
    this.challenge,
    this.detectedNote,
    this.result = EarTrainingResult.idle,
    this.correctCount = 0,
    this.totalCount = 0,
    this.isListening = false,
  });

  final ExerciseDefinition definition;
  final EarTrainingChallenge? challenge;
  final String? detectedNote;
  final EarTrainingResult result;
  final int correctCount;
  final int totalCount;
  final bool isListening;

  EarTrainingSessionState copyWith({
    EarTrainingChallenge? challenge,
    String? detectedNote,
    EarTrainingResult? result,
    int? correctCount,
    int? totalCount,
    bool? isListening,
  }) {
    return EarTrainingSessionState(
      definition: definition,
      challenge: challenge ?? this.challenge,
      detectedNote: detectedNote ?? this.detectedNote,
      result: result ?? this.result,
      correctCount: correctCount ?? this.correctCount,
      totalCount: totalCount ?? this.totalCount,
      isListening: isListening ?? this.isListening,
    );
  }
}

enum EarTrainingResult { idle, correct, wrong, finished }

/// Controller for an ear-training exercise session.
class EarTrainingController extends StateNotifier<EarTrainingSessionState> {
  EarTrainingController({
    required ExerciseDefinition definition,
    required Stream<PitchEvent> pitchStream,
    required PitchChallengeValidator validator,
    required TrainingProgressRepository repository,
    required AudioPlayer player,
    required this.onFinished,
  })  : _pitchStream = pitchStream,
        _validator = validator,
        _repository = repository,
        _player = player,
        super(EarTrainingSessionState(definition: definition)) {
    _startRound();
  }

  static const int _roundsPerSession = 10;
  static const int _sampleRate = 44100;

  final Stream<PitchEvent> _pitchStream;
  final PitchChallengeValidator _validator;
  final TrainingProgressRepository _repository;
  final AudioPlayer _player;
  final VoidCallback onFinished;

  StreamSubscription<PitchEvent>? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _startRound() {
    final EarTrainingChallenge challenge =
        EarTrainingLevelGenerator.generate(state.definition);
    state = state.copyWith(
      challenge: challenge,
      result: EarTrainingResult.idle,
      detectedNote: null,
    );
    unawaited(_playInterval(challenge));
  }

  Future<void> _playTone(Note note, double duration) async {
    final Uint8List wav = ToneGenerator.buildTone(
      frequency: note.frequency,
      sampleRate: _sampleRate,
      duration: duration,
    );
    await _player.play(BytesSource(wav));
  }

  Future<void> _playInterval(EarTrainingChallenge challenge) async {
    await _playTone(challenge.root, 0.5);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await _playTone(challenge.target, 0.5);
  }

  void startListening() {
    if (state.isListening) {
      return;
    }
    state = state.copyWith(isListening: true);
    _subscription = _pitchStream.listen(_onPitch);
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    state = state.copyWith(isListening: false);
  }

  void _onPitch(PitchEvent event) {
    if (!event.hasPitch || state.challenge == null) {
      return;
    }
    final TuningReading? reading = noteFromFrequency(event.frequency);
    if (reading == null) {
      return;
    }
    final String name = reading.nearest.name(
      notation: Notation.solfeggio,
      accidental: AccidentalStyle.sharp,
    );
    state = state.copyWith(detectedNote: name);

    if (_validator.matches(event.frequency, state.challenge!.target.pitchClass)) {
      _handleCorrect();
    }
  }

  void _handleCorrect() {
    stopListening();
    final int newCorrect = state.correctCount + 1;
    final int newTotal = state.totalCount + 1;
    state = state.copyWith(
      correctCount: newCorrect,
      totalCount: newTotal,
      result: EarTrainingResult.correct,
    );
    _maybeFinishOrNext(newTotal);
  }

  void markWrong() {
    stopListening();
    final int newTotal = state.totalCount + 1;
    state = state.copyWith(
      totalCount: newTotal,
      result: EarTrainingResult.wrong,
    );
    _maybeFinishOrNext(newTotal);
  }

  void _maybeFinishOrNext(int total) {
    if (total >= _roundsPerSession) {
      _finish();
    } else {
      Future<void>.delayed(const Duration(milliseconds: 800), _startRound);
    }
  }

  Future<void> _finish() async {
    final double accuracy =
        state.totalCount == 0 ? 0 : state.correctCount / state.totalCount;
    await _repository.saveAttempt(
      exerciseId: state.definition.id,
      accuracy: accuracy,
      durationMs: 0,
    );
    await _repository.unlockNextLevel(
      state.definition,
      EarTrainingLevelGenerator.buildDefinitions(),
    );
    state = state.copyWith(result: EarTrainingResult.finished);
    onFinished();
  }

  Future<void> repeat() async {
    if (state.challenge != null) {
      await _playInterval(state.challenge!);
    }
  }
}

typedef VoidCallback = void Function();
