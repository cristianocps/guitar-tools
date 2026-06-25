import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:music_tools/core/audio/audio_capture_service.dart';
import 'package:music_tools/core/audio/guitar_synth.dart';
import 'package:music_tools/core/audio/pitch_challenge_validator.dart';
import 'package:music_tools/core/audio/pitch_detector.dart';
import 'package:music_tools/core/chords/chord_models.dart';
import 'package:music_tools/core/music_theory/note.dart';
import 'package:music_tools/core/music_theory/pitch.dart';
import 'package:music_tools/core/training/models/exercise_definition.dart';
import 'package:music_tools/core/training/repositories/training_progress_repository.dart';

/// State of a chord learning session.
class ChordLearnSessionState {
  ChordLearnSessionState({
    required this.definition,
    required this.chord,
    this.positionIndex = 0,
    this.detectedNote,
    this.isListening = false,
    this.isPlayingReference = false,
    this.result = ChordLearnResult.idle,
  });

  final ExerciseDefinition definition;
  final Chord chord;
  final int positionIndex;
  final String? detectedNote;
  final bool isListening;
  final bool isPlayingReference;
  final ChordLearnResult result;

  ChordPosition get currentPosition => chord.positions[positionIndex];

  ChordLearnSessionState copyWith({
    int? positionIndex,
    String? detectedNote,
    bool? isListening,
    bool? isPlayingReference,
    ChordLearnResult? result,
  }) {
    return ChordLearnSessionState(
      definition: definition,
      chord: chord,
      positionIndex: positionIndex ?? this.positionIndex,
      detectedNote: detectedNote ?? this.detectedNote,
      isListening: isListening ?? this.isListening,
      isPlayingReference: isPlayingReference ?? this.isPlayingReference,
      result: result ?? this.result,
    );
  }
}

enum ChordLearnResult { idle, correct, wrong }

/// Controller for the chord learning mode.
class ChordLearnController extends StateNotifier<ChordLearnSessionState> {
  ChordLearnController({
    required ExerciseDefinition definition,
    required Chord chord,
    required Stream<PitchEvent> pitchStream,
    required AudioCaptureService capture,
    required PitchChallengeValidator validator,
    required TrainingProgressRepository repository,
    required InstrumentPlayer player,
    required this.onFinished,
    this.loopEnabled = false,
    this.loopBpm = 80,
    this.loopBeatsPerBar = 4,
  })  : _pitchStream = pitchStream,
        _capture = capture,
        _validator = validator,
        _repository = repository,
        _instrument = player,
        super(
          ChordLearnSessionState(
            definition: definition,
            chord: chord,
          ),
        ) {
    _init();
  }

  static const int _validationWindowMs = 1200;
  static const int _listenTimeoutMs = 10000;

  final Stream<PitchEvent> _pitchStream;
  final AudioCaptureService _capture;
  final PitchChallengeValidator _validator;
  final TrainingProgressRepository _repository;
  final InstrumentPlayer _instrument;
  final VoidCallback onFinished;

  /// When true, the reference chord is replayed every bar at [loopBpm] /
  /// [loopBeatsPerBar] instead of being played once for validation.
  final bool loopEnabled;
  final int loopBpm;
  final int loopBeatsPerBar;

  StreamSubscription<PitchEvent>? _subscription;
  Timer? _validationTimer;
  Timer? _listenTimeout;
  Timer? _loopTimer;
  int _loopBeat = 0;

  @override
  void dispose() {
    _subscription?.cancel();
    _validationTimer?.cancel();
    _listenTimeout?.cancel();
    _loopTimer?.cancel();
    unawaited(_capture.stop());
    unawaited(_instrument.dispose());
    super.dispose();
  }

  Future<void> _init() async {
    if (loopEnabled) {
      unawaited(_startLoop());
      return;
    }
    try {
      await _capture.start();
    } on Object {
      // Capture may already be running (e.g. when switching positions); the
      // reference should still play in that case.
    }
    unawaited(playReference());
    startListening();
  }

  Future<void> _startLoop() async {
    _loopTimer?.cancel();
    final int bpm = loopBpm.clamp(20, 200);
    final int beats = loopBeatsPerBar < 1 ? 1 : loopBeatsPerBar;
    final int beatMs = (60000 / bpm).round();
    // The chord is re-struck on every beat (so the loop clearly tracks the
    // BPM), and rings for roughly one beat so faster tempos give shorter,
    // tighter strums. The time signature accents the downbeat.
    final double duration = (beatMs / 1000 * 0.95).clamp(0.2, 2.0);
    state = state.copyWith(isPlayingReference: true);
    await _instrument.prepareChord(
      state.currentPosition.midi,
      duration: duration,
    );
    _loopBeat = 0;
    await _instrument.triggerChord(accent: true);
    _loopTimer = Timer.periodic(Duration(milliseconds: beatMs), (_) {
      _loopBeat = (_loopBeat + 1) % beats;
      unawaited(_instrument.triggerChord(accent: _loopBeat == 0));
    });
  }

  void startListening() {
    if (state.isListening) {
      return;
    }
    state = state.copyWith(
      isListening: true,
      detectedNote: null,
      result: ChordLearnResult.idle,
    );
    _subscription = _pitchStream.listen(_onPitch);
    _listenTimeout = Timer(
      const Duration(milliseconds: _listenTimeoutMs),
      _handleWrong,
    );
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _validationTimer?.cancel();
    _listenTimeout?.cancel();
    state = state.copyWith(isListening: false);
  }

  void _onPitch(PitchEvent event) {
    if (_instrument.isOutputActive || !event.hasPitch) {
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

    if (_validator.matches(event.frequency, _expectedPitchClass)) {
      _validationTimer?.cancel();
      _validationTimer = Timer(
        const Duration(milliseconds: _validationWindowMs),
        _validate,
      );
    }
  }

  void _validate() {
    state = state.copyWith(result: ChordLearnResult.correct);
    unawaited(
      _repository.saveAttempt(
        exerciseId: state.definition.id,
        accuracy: 1,
        durationMs: 0,
      ),
    );
    stopListening();
  }

  void _handleWrong() {
    state = state.copyWith(result: ChordLearnResult.wrong);
    stopListening();
  }

  int get _expectedPitchClass {
    return state.currentPosition.pitchClasses.first;
  }

  Future<void> playReference() async {
    state = state.copyWith(isPlayingReference: true);
    // Play the whole chord at once (unison) instead of string by string.
    await _instrument.playChord(
      state.currentPosition.midi,
      duration: 1.6,
      strumMs: 0,
    );
    state = state.copyWith(isPlayingReference: false);
  }

  void selectPosition(int index) {
    if (index < 0 || index >= state.chord.positions.length) {
      return;
    }
    stopListening();
    state = state.copyWith(
      positionIndex: index,
      detectedNote: null,
      result: ChordLearnResult.idle,
    );
    unawaited(_init());
  }

  void retry() {
    state = state.copyWith(
      detectedNote: null,
      result: ChordLearnResult.idle,
    );
    unawaited(_capture.start());
    startListening();
  }
}

typedef VoidCallback = void Function();
