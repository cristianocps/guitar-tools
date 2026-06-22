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
    this.expectedBeats = const <Duration>[],
    this.onsetCount = 0,
    this.hits = 0,
    this.result = RhythmResult.idle,
    this.isPlaying = false,
    this.elapsedMs = 0,
    this.countInValue = 0,
  });

  final ExerciseDefinition definition;

  /// Stream positions (from the audio stream start) where a played onset is
  /// expected, used to score the player against the pattern.
  final List<Duration> expectedBeats;
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
    List<Duration>? expectedBeats,
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
        super(RhythmSessionState(definition: definition));

  static const int _toleranceMs = 140;

  /// Extra time after the last expected beat before finishing, so the final
  /// note's (buffered) onset still has time to be captured and scored.
  static const int _tailGuardMs = 450;

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
  double _clickIntervalMs = 500;
  int _clicksPerBar = 4;

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

    // Click the pattern's smallest note value (its base grid) during the
    // count-in, so the audible pulse matches the rate the notes must be played
    // at. A plain beat-rate click feels much slower than e.g. eighths/triplets,
    // which is why the metronome seemed out of sync with the exercise. Clicks
    // are scheduled directly from this interval (not via the metronome engine)
    // so fast grids like sixteenths aren't capped by the engine's max BPM.
    final double subdivision =
        _pattern!.durations.reduce((double a, double b) => a < b ? a : b);
    _clickIntervalMs = subdivision * _beatDurationMs;
    _clicksPerBar = (_beatsPerBar / subdivision).round();
    _lastBeat = -1;

    // Reset the detector's stream clock so onset positions are measured from
    // this capture's first sample, and only score onsets once the count-in bar
    // has elapsed (so the metronome clicks are never counted as notes).
    _rhythmDetector
      ..reset()
      ..detectFrom(Duration(milliseconds: _countInMs.round()));

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
      expectedBeats: const <Duration>[],
    );

    _timer = Timer.periodic(const Duration(milliseconds: 16), _tick);
  }

  void _tick(Timer timer) {
    if (_startedAt == null) {
      return;
    }
    final int elapsed = DateTime.now().difference(_startedAt!).inMilliseconds;
    // Only click during the count-in. Once scoring starts the click would be
    // picked up by the mic (it lands exactly on the beats) and counted as a
    // note the user played, so we go silent and let them keep the tempo.
    if (elapsed < _countInMs) {
      final int gridIndex = (elapsed / _clickIntervalMs).floor();
      if (gridIndex != _lastBeat) {
        _lastBeat = gridIndex;
        _clickPlayer.play(accent: gridIndex % _clicksPerBar == 0);
      }
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
      // Expected onsets as positions in the audio-stream timeline (which starts
      // with the count-in), so they line up with the onset positions the
      // detector reports.
      final List<Duration> expected = <Duration>[];
      double posMs = _countInMs;
      for (final double duration in _pattern!.durations) {
        expected.add(Duration(milliseconds: posMs.round()));
        posMs += duration * _beatDurationMs;
      }
      state = state.copyWith(
        isPlaying: true,
        result: RhythmResult.playing,
        expectedBeats: expected,
        countInValue: 0,
      );
    }

    state = state.copyWith(elapsedMs: elapsed - _countInMs.round());
    final int lastBeatMs = state.expectedBeats.last.inMilliseconds;
    if (elapsed > lastBeatMs + _toleranceMs + _tailGuardMs) {
      _finish();
    }
  }

  int _lastBeat = 0;

  void _onOnset(OnsetEvent event) {
    if (!state.isPlaying) {
      return;
    }
    final Duration onset = event.position;
    bool matched = false;
    for (final Duration expected in state.expectedBeats) {
      if ((onset - expected).inMilliseconds.abs() <= _toleranceMs) {
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
