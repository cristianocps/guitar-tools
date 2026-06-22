import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_capture_service.dart';
import '../../../core/audio/rhythm_detector.dart';
import '../../../core/metronome_engine/click_player.dart';
import '../../../core/metronome_engine/metronome_engine.dart';
import '../../../core/training/models/exercise_definition.dart';
import '../../../core/training/repositories/training_progress_repository.dart';
import 'rhythm_pattern_catalog.dart';

/// State of a rhythm exercise session.
class RhythmSessionState {
  RhythmSessionState({
    required this.definition,
    this.expectedBeats = const <DateTime>[],
    this.onsetCount = 0,
    this.hits = 0,
    this.result = RhythmResult.idle,
    this.isPlaying = false,
    this.elapsedMs = 0,
    this.countInValue = 0,
  });

  final ExerciseDefinition definition;
  final List<DateTime> expectedBeats;
  final int onsetCount;
  final int hits;
  final RhythmResult result;
  final bool isPlaying;
  final int elapsedMs;

  /// During the count-in, the beat number currently being counted (1..N);
  /// 0 when not counting in.
  final int countInValue;

  bool get isCountingIn => result == RhythmResult.countIn;

  double get accuracy =>
      expectedBeats.isEmpty ? 0 : hits / expectedBeats.length;

  RhythmSessionState copyWith({
    List<DateTime>? expectedBeats,
    int? onsetCount,
    int? hits,
    RhythmResult? result,
    bool? isPlaying,
    int? elapsedMs,
    int? countInValue,
  }) {
    return RhythmSessionState(
      definition: definition,
      expectedBeats: expectedBeats ?? this.expectedBeats,
      onsetCount: onsetCount ?? this.onsetCount,
      hits: hits ?? this.hits,
      result: result ?? this.result,
      isPlaying: isPlaying ?? this.isPlaying,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      countInValue: countInValue ?? this.countInValue,
    );
  }
}

enum RhythmResult { idle, countIn, playing, finished }

/// Controller for rhythm exercises.
class RhythmExerciseController extends StateNotifier<RhythmSessionState> {
  RhythmExerciseController({
    required ExerciseDefinition definition,
    required MetronomeEngine engine,
    required ClickPlayer clickPlayer,
    required RhythmDetector rhythmDetector,
    required AudioCaptureService capture,
    required TrainingProgressRepository repository,
    required this.onFinished,
  })  : _engine = engine,
        _clickPlayer = clickPlayer,
        _rhythmDetector = rhythmDetector,
        _capture = capture,
        _repository = repository,
        super(RhythmSessionState(definition: definition)) {
    unawaited(start());
  }

  static const int _toleranceMs = 140;

  /// Count-in length (one 4/4 bar) the user hears before scoring begins.
  static const int _beatsPerBar = 4;

  final MetronomeEngine _engine;
  final ClickPlayer _clickPlayer;
  final RhythmDetector _rhythmDetector;
  final AudioCaptureService _capture;
  final TrainingProgressRepository _repository;
  final VoidCallback onFinished;

  StreamSubscription<Uint8List>? _audioSubscription;
  StreamSubscription<OnsetEvent>? _onsetSubscription;
  Timer? _timer;
  DateTime? _startedAt;
  RhythmPattern? _pattern;
  double _beatDurationMs = 500;
  double _countInMs = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _audioSubscription?.cancel();
    _onsetSubscription?.cancel();
    _engine.stop();
    _clickPlayer.dispose();
    _rhythmDetector.dispose();
    super.dispose();
  }

  Future<void> start() async {
    if (state.isPlaying || state.isCountingIn) {
      return;
    }
    final int bpm = definitionBpm;
    _beatDurationMs = 60000 / bpm;
    _countInMs = _beatsPerBar * _beatDurationMs;
    _pattern = RhythmPatternCatalog.patternFor(state.definition);

    _engine
      ..setBeatsPerBar(_beatsPerBar)
      ..setBpm(bpm)
      ..start(now: Duration.zero);
    _lastBeat = 0;

    // Start capturing immediately so the mic is warm, but only score onsets
    // once the count-in finishes.
    final Stream<Uint8List> stream = await _capture.start();
    _audioSubscription = stream.listen(_rhythmDetector.processChunk);
    _onsetSubscription = _rhythmDetector.onsets.listen(_onOnset);

    _startedAt = DateTime.now();
    state = state.copyWith(
      result: RhythmResult.countIn,
      isPlaying: false,
      countInValue: 1,
      onsetCount: 0,
      hits: 0,
      expectedBeats: const <DateTime>[],
    );

    _timer = Timer.periodic(const Duration(milliseconds: 16), _tick);
  }

  void _tick(Timer timer) {
    if (_startedAt == null) {
      return;
    }
    final int elapsed = DateTime.now().difference(_startedAt!).inMilliseconds;
    _engine.processFrame(Duration(milliseconds: elapsed));
    if (_engine.currentBeat != _lastBeat) {
      _lastBeat = _engine.currentBeat;
      _clickPlayer.play(accent: _engine.isCurrentBeatAccent);
    }

    // Count-in phase: let the player hear a full bar before scoring.
    if (elapsed < _countInMs) {
      final int value =
          (elapsed / _beatDurationMs).floor().clamp(0, _beatsPerBar - 1) + 1;
      if (state.countInValue != value || !state.isCountingIn) {
        state = state.copyWith(
          result: RhythmResult.countIn,
          countInValue: value,
        );
      }
      return;
    }

    // Transition into the scored phase exactly once.
    if (!state.isPlaying) {
      final DateTime scoringStart =
          _startedAt!.add(Duration(milliseconds: _countInMs.round()));
      final List<DateTime> expected = <DateTime>[];
      DateTime next = scoringStart;
      for (final double duration in _pattern!.durations) {
        expected.add(next);
        next = next
            .add(Duration(milliseconds: (duration * _beatDurationMs).round()));
      }
      state = state.copyWith(
        isPlaying: true,
        result: RhythmResult.playing,
        expectedBeats: expected,
        countInValue: 0,
      );
    }

    state = state.copyWith(elapsedMs: elapsed - _countInMs.round());
    if (DateTime.now().isAfter(
      state.expectedBeats.last.add(
        const Duration(milliseconds: _toleranceMs),
      ),
    )) {
      _finish();
    }
  }

  int _lastBeat = 0;

  void _onOnset(OnsetEvent event) {
    if (!state.isPlaying) {
      return;
    }
    final DateTime onsetTime = event.timestamp;
    bool matched = false;
    for (final DateTime expected in state.expectedBeats) {
      if (onsetTime.difference(expected).inMilliseconds.abs() <= _toleranceMs) {
        matched = true;
        break;
      }
    }
    state = state.copyWith(
      onsetCount: state.onsetCount + 1,
      hits: matched ? state.hits + 1 : state.hits,
    );
  }

  Future<void> _finish() async {
    _timer?.cancel();
    await _audioSubscription?.cancel();
    await _onsetSubscription?.cancel();
    _engine.stop();
    await _capture.stop();

    final double accuracy = state.accuracy;
    await _repository.saveAttempt(
      exerciseId: state.definition.id,
      accuracy: accuracy,
      durationMs: state.elapsedMs,
    );
    await _repository.unlockNextLevel(
      state.definition,
      RhythmPatternCatalog.buildDefinitions(),
    );

    state = state.copyWith(
      isPlaying: false,
      result: RhythmResult.finished,
    );
    onFinished();
  }

  int get definitionBpm =>
      (state.definition.parameters['bpm'] as int?)?.clamp(20, 280) ?? 80;
}

typedef VoidCallback = void Function();
