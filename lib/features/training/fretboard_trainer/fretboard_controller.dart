import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/pitch_challenge_validator.dart';
import '../../../core/audio/pitch_detector.dart';
import '../../../core/audio/tone_cache.dart';
import '../../../core/audio/tone_generator.dart';
import '../../../core/music_theory/fretboard.dart';
import '../../../core/music_theory/note.dart';
import '../../../core/music_theory/pitch.dart';
import '../../../core/training/models/exercise_definition.dart';
import '../../../core/training/repositories/training_progress_repository.dart';
import 'fretboard_challenge_generator.dart';

/// State of a fretboard trainer session.
class FretboardSessionState {
  FretboardSessionState({
    required this.definition,
    this.challenge,
    this.scaleSequence = const <FretboardChallenge>[],
    this.sequenceIndex = 0,
    this.detectedNote,
    this.result = FretboardResult.idle,
    this.correctCount = 0,
    this.totalCount = 0,
    this.isListening = false,
  });

  final ExerciseDefinition definition;
  final FretboardChallenge? challenge;
  final List<FretboardChallenge> scaleSequence;
  final int sequenceIndex;
  final String? detectedNote;
  final FretboardResult result;
  final int correctCount;
  final int totalCount;
  final bool isListening;

  FretboardSessionState copyWith({
    FretboardChallenge? challenge,
    List<FretboardChallenge>? scaleSequence,
    int? sequenceIndex,
    String? detectedNote,
    FretboardResult? result,
    int? correctCount,
    int? totalCount,
    bool? isListening,
  }) {
    return FretboardSessionState(
      definition: definition,
      challenge: challenge ?? this.challenge,
      scaleSequence: scaleSequence ?? this.scaleSequence,
      sequenceIndex: sequenceIndex ?? this.sequenceIndex,
      detectedNote: detectedNote ?? this.detectedNote,
      result: result ?? this.result,
      correctCount: correctCount ?? this.correctCount,
      totalCount: totalCount ?? this.totalCount,
      isListening: isListening ?? this.isListening,
    );
  }
}

enum FretboardResult { idle, correct, wrong, finished }

/// Controller for the fretboard trainer.
class FretboardController extends StateNotifier<FretboardSessionState> {
  FretboardController({
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
        super(FretboardSessionState(definition: definition)) {
    _init();
  }

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

  void _init() {
    final FretboardMode mode =
        FretboardChallengeGenerator.modeFrom(state.definition);
    if (mode == FretboardMode.scaleRunner) {
      final List<FretboardChallenge> sequence =
          FretboardChallengeGenerator.generateScaleSequence(state.definition);
      state = state.copyWith(
        scaleSequence: sequence,
        challenge: sequence.first,
      );
    } else {
      _nextLocateChallenge();
    }
  }

  void _nextLocateChallenge() {
    final FretboardChallenge challenge =
        FretboardChallengeGenerator.generateLocate(state.definition);
    state = state.copyWith(
      challenge: challenge,
      result: FretboardResult.idle,
      detectedNote: null,
    );
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

    // Match the exact requested note (string + fret), not just the pitch class,
    // so the same note played an octave away on another string is not accepted.
    if (_validator.matchesNote(
      event.frequency,
      state.challenge!.expectedNote.midi,
    )) {
      _handleCorrect();
    }
  }

  void _handleCorrect() {
    stopListening();
    final int newCorrect = state.correctCount + 1;
    final int newTotal = state.totalCount + 1;
    final FretboardMode mode =
        FretboardChallengeGenerator.modeFrom(state.definition);

    if (mode == FretboardMode.scaleRunner) {
      final int nextIndex = state.sequenceIndex + 1;
      if (nextIndex >= state.scaleSequence.length) {
        _finish(newCorrect, newTotal);
      } else {
        state = state.copyWith(
          correctCount: newCorrect,
          totalCount: newTotal,
          sequenceIndex: nextIndex,
          challenge: state.scaleSequence[nextIndex],
          result: FretboardResult.correct,
        );
      }
    } else {
      state = state.copyWith(
        correctCount: newCorrect,
        totalCount: newTotal,
        result: FretboardResult.correct,
      );
      Future<void>.delayed(const Duration(milliseconds: 600), _nextLocateChallenge);
    }
  }

  void markWrong() {
    stopListening();
    final int newTotal = state.totalCount + 1;
    state = state.copyWith(
      totalCount: newTotal,
      result: FretboardResult.wrong,
    );
    final FretboardMode mode =
        FretboardChallengeGenerator.modeFrom(state.definition);
    if (mode == FretboardMode.locateNote) {
      Future<void>.delayed(const Duration(milliseconds: 600), _nextLocateChallenge);
    }
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
      <ExerciseDefinition>[
        ...FretboardChallengeGenerator.buildLocateDefinitions(),
        ...FretboardChallengeGenerator.buildScaleDefinitions(),
      ],
    );
    state = state.copyWith(result: FretboardResult.finished);
    onFinished();
  }

  Future<void> playTarget() async {
    final FretboardChallenge? challenge = state.challenge;
    if (challenge == null) {
      return;
    }
    final Note note = noteAtFretPosition(challenge.stringIndex, challenge.fret);
    final Uint8List wav = ToneGenerator.buildTone(
      frequency: note.frequency,
      sampleRate: _sampleRate,
      duration: 0.6,
    );
    final String path = await writeTempWav(wav);
    await _player.play(DeviceFileSource(path));
  }
}

typedef VoidCallback = void Function();
