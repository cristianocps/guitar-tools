import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/pitch_challenge_validator.dart';
import '../../../core/audio/pitch_detector.dart';
import '../../../core/audio/tone_generator.dart';
import '../../../core/metronome_engine/click_player.dart';
import '../../../core/metronome_engine/metronome_engine.dart';
import '../../../core/music_theory/note.dart';
import '../../../core/music_theory/pitch.dart';
import '../../../core/training/models/exercise_definition.dart';
import '../../../core/training/repositories/training_progress_repository.dart';
import 'technique_exercise_catalog.dart';

/// State of a technique exercise session.
class TechniqueSessionState {
  TechniqueSessionState({
    required this.definition,
    required this.sequence,
    this.currentIndex = 0,
    this.detectedNote,
    this.result = TechniqueResult.idle,
    this.correctCount = 0,
    this.totalCount = 0,
    this.isPlaying = false,
    this.elapsedMs = 0,
  });

  final ExerciseDefinition definition;
  final List<Note> sequence;
  final int currentIndex;
  final String? detectedNote;
  final TechniqueResult result;
  final int correctCount;
  final int totalCount;
  final bool isPlaying;
  final int elapsedMs;

  Note? get currentNote => sequence.isEmpty || currentIndex >= sequence.length
      ? null
      : sequence[currentIndex];

  TechniqueSessionState copyWith({
    int? currentIndex,
    String? detectedNote,
    TechniqueResult? result,
    int? correctCount,
    int? totalCount,
    bool? isPlaying,
    int? elapsedMs,
  }) {
    return TechniqueSessionState(
      definition: definition,
      sequence: sequence,
      currentIndex: currentIndex ?? this.currentIndex,
      detectedNote: detectedNote ?? this.detectedNote,
      result: result ?? this.result,
      correctCount: correctCount ?? this.correctCount,
      totalCount: totalCount ?? this.totalCount,
      isPlaying: isPlaying ?? this.isPlaying,
      elapsedMs: elapsedMs ?? this.elapsedMs,
    );
  }
}

enum TechniqueResult { idle, playing, correct, wrong, finished }

/// Controller for technique exercises.
class TechniqueExerciseController extends StateNotifier<TechniqueSessionState> {
  TechniqueExerciseController({
    required ExerciseDefinition definition,
    required Stream<PitchEvent> pitchStream,
    required PitchChallengeValidator validator,
    required TrainingProgressRepository repository,
    required MetronomeEngine engine,
    required ClickPlayer clickPlayer,
    required AudioPlayer player,
    required this.onFinished,
  })  : _pitchStream = pitchStream,
        _validator = validator,
        _repository = repository,
        _engine = engine,
        _clickPlayer = clickPlayer,
        _player = player,
        super(
          TechniqueSessionState(
            definition: definition,
            sequence: TechniqueExerciseCatalog.buildNoteSequence(definition),
          ),
        ) {
    _initEngine();
  }

  static const int _sampleRate = 44100;

  final Stream<PitchEvent> _pitchStream;
  final PitchChallengeValidator _validator;
  final TrainingProgressRepository _repository;
  final MetronomeEngine _engine;
  final ClickPlayer _clickPlayer;
  final AudioPlayer _player;
  final VoidCallback onFinished;

  StreamSubscription<PitchEvent>? _subscription;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _subscription?.cancel();
    _engine.stop();
    _clickPlayer.dispose();
    _player.dispose();
    super.dispose();
  }

  void _initEngine() {
    final int bpm = (state.definition.parameters['bpm'] as int?)?.clamp(20, 200) ?? 80;
    _engine.setBpm(bpm);
  }

  void start() {
    if (state.isPlaying) {
      return;
    }
    state = state.copyWith(
      isPlaying: true,
      result: TechniqueResult.playing,
      currentIndex: 0,
      correctCount: 0,
      totalCount: 0,
    );
    _engine.start(now: Duration.zero);
    _timer = Timer.periodic(const Duration(milliseconds: 16), _tick);
    _subscription = _pitchStream.listen(_onPitch);
  }

  void _tick(Timer timer) {
    state = state.copyWith(elapsedMs: state.elapsedMs + 16);
    _engine.processFrame(Duration(milliseconds: state.elapsedMs));
    if (_engine.currentBeat != _lastBeat) {
      _lastBeat = _engine.currentBeat;
      _clickPlayer.play(accent: _engine.isCurrentBeatAccent);
    }
  }

  int _lastBeat = 0;

  void _onPitch(PitchEvent event) {
    final Note? expected = state.currentNote;
    if (!event.hasPitch || expected == null) {
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

    if (_validator.matches(event.frequency, expected.pitchClass)) {
      _handleCorrect();
    }
  }

  void _handleCorrect() {
    final int newCorrect = state.correctCount + 1;
    final int newTotal = state.totalCount + 1;
    final int nextIndex = state.currentIndex + 1;

    if (nextIndex >= state.sequence.length) {
      _finish(newCorrect, newTotal);
    } else {
      state = state.copyWith(
        correctCount: newCorrect,
        totalCount: newTotal,
        currentIndex: nextIndex,
        result: TechniqueResult.correct,
      );
      _playCurrentNote();
    }
  }

  void markWrong() {
    final int newTotal = state.totalCount + 1;
    state = state.copyWith(
      totalCount: newTotal,
      result: TechniqueResult.wrong,
    );
  }

  Future<void> _finish(int correct, int total) async {
    _timer?.cancel();
    await _subscription?.cancel();
    _engine.stop();

    final double accuracy = total == 0 ? 0 : correct / total;
    await _repository.saveAttempt(
      exerciseId: state.definition.id,
      accuracy: accuracy,
      durationMs: state.elapsedMs,
    );
    await _repository.unlockNextLevel(
      state.definition,
      TechniqueExerciseCatalog.buildDefinitions(),
    );

    state = state.copyWith(
      result: TechniqueResult.finished,
      isPlaying: false,
    );
    onFinished();
  }

  Future<void> _playCurrentNote() async {
    final Note? note = state.currentNote;
    if (note == null) {
      return;
    }
    final Uint8List wav = ToneGenerator.buildTone(
      frequency: note.frequency,
      sampleRate: _sampleRate,
      duration: 0.4,
    );
    await _player.play(BytesSource(wav));
  }
}

typedef VoidCallback = void Function();
