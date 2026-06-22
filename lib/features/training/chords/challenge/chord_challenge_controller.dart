import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:music_tools/core/audio/audio_capture_service.dart';
import 'package:music_tools/core/audio/pitch_challenge_validator.dart';
import 'package:music_tools/core/audio/pitch_detector.dart';
import 'package:music_tools/core/chords/chord_models.dart';
import 'package:music_tools/core/music_theory/note.dart';
import 'package:music_tools/core/music_theory/pitch.dart';
import 'package:music_tools/core/training/models/exercise_definition.dart';
import 'package:music_tools/core/training/repositories/training_progress_repository.dart';

import 'chord_challenge_catalog.dart';

/// State of a chord challenge session.
class ChordChallengeSessionState {
  ChordChallengeSessionState({
    required this.definition,
    required this.chords,
    this.currentIndex = 0,
    this.detectedNote,
    this.correctCount = 0,
    this.result = ChordChallengeResult.idle,
    this.timeRemainingMs = 0,
  });

  final ExerciseDefinition definition;
  final List<Chord> chords;
  final int currentIndex;
  final String? detectedNote;
  final int correctCount;
  final ChordChallengeResult result;
  final int timeRemainingMs;

  Chord get currentChord => chords[currentIndex];

  ChordChallengeSessionState copyWith({
    int? currentIndex,
    String? detectedNote,
    int? correctCount,
    ChordChallengeResult? result,
    int? timeRemainingMs,
  }) {
    return ChordChallengeSessionState(
      definition: definition,
      chords: chords,
      currentIndex: currentIndex ?? this.currentIndex,
      detectedNote: detectedNote ?? this.detectedNote,
      correctCount: correctCount ?? this.correctCount,
      result: result ?? this.result,
      timeRemainingMs: timeRemainingMs ?? this.timeRemainingMs,
    );
  }
}

enum ChordChallengeResult { idle, correct, wrong, finished }

/// Controller for chord challenge mode.
class ChordChallengeController extends StateNotifier<ChordChallengeSessionState> {
  ChordChallengeController({
    required ExerciseDefinition definition,
    required List<Chord> chords,
    required Stream<PitchEvent> pitchStream,
    required AudioCaptureService capture,
    required PitchChallengeValidator validator,
    required TrainingProgressRepository repository,
    required this.onFinished,
  })  : _pitchStream = pitchStream,
        _capture = capture,
        _validator = validator,
        _repository = repository,
        super(
          ChordChallengeSessionState(
            definition: definition,
            chords: chords,
            timeRemainingMs: definition.parameters['timeLimitMs'] as int,
          ),
        ) {
    _init();
  }

  static const int _validationWindowMs = 1000;

  final Stream<PitchEvent> _pitchStream;
  final AudioCaptureService _capture;
  final PitchChallengeValidator _validator;
  final TrainingProgressRepository _repository;
  final VoidCallback onFinished;

  StreamSubscription<PitchEvent>? _subscription;
  Timer? _validationTimer;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _subscription?.cancel();
    _validationTimer?.cancel();
    _countdownTimer?.cancel();
    unawaited(_capture.stop());
    super.dispose();
  }

  Future<void> _init() async {
    await _capture.start();
    _startRound();
  }

  void _startRound() {
    state = state.copyWith(
      detectedNote: null,
      result: ChordChallengeResult.idle,
      timeRemainingMs: state.definition.parameters['timeLimitMs'] as int,
    );
    _subscription = _pitchStream.listen(_onPitch);
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 100), _tick);
  }

  void _tick(Timer timer) {
    final int next = state.timeRemainingMs - 100;
    if (next <= 0) {
      _handleTimeout();
    } else {
      state = state.copyWith(timeRemainingMs: next);
    }
  }

  void _onPitch(PitchEvent event) {
    if (!event.hasPitch) {
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

    final Set<int> expected = state.currentChord.pitchClasses;
    for (final int pitchClass in expected) {
      if (_validator.matches(event.frequency, pitchClass)) {
        _validationTimer?.cancel();
        _validationTimer = Timer(
          const Duration(milliseconds: _validationWindowMs),
          _handleCorrect,
        );
        return;
      }
    }
  }

  void _handleCorrect() {
    _cleanupRound();
    final int newCorrect = state.correctCount + 1;
    final int nextIndex = state.currentIndex + 1;
    final int totalRounds = state.definition.parameters['rounds'] as int;

    if (nextIndex >= totalRounds || nextIndex >= state.chords.length) {
      _finish(newCorrect, nextIndex);
    } else {
      state = state.copyWith(
        correctCount: newCorrect,
        currentIndex: nextIndex,
        result: ChordChallengeResult.correct,
      );
      Future<void>.delayed(const Duration(milliseconds: 600), _startRound);
    }
  }

  void _handleTimeout() {
    _cleanupRound();
    final int nextIndex = state.currentIndex + 1;
    final int totalRounds = state.definition.parameters['rounds'] as int;

    if (nextIndex >= totalRounds || nextIndex >= state.chords.length) {
      _finish(state.correctCount, nextIndex);
    } else {
      state = state.copyWith(
        currentIndex: nextIndex,
        result: ChordChallengeResult.wrong,
      );
      Future<void>.delayed(const Duration(milliseconds: 600), _startRound);
    }
  }

  void _cleanupRound() {
    _subscription?.cancel();
    _subscription = null;
    _validationTimer?.cancel();
    _countdownTimer?.cancel();
  }

  Future<void> _finish(int correct, int total) async {
    final double accuracy = total == 0 ? 0 : correct / total;
    await _repository.saveAttempt(
      exerciseId: state.definition.id,
      accuracy: accuracy,
      durationMs: 0,
    );
    await _repository.unlockNextLevel(
      state.definition,
      ChordChallengeCatalog.buildDefinitions(),
    );
    state = state.copyWith(result: ChordChallengeResult.finished);
    onFinished();
  }
}

typedef VoidCallback = void Function();
