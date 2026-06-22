import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:music_tools/core/audio/audio_capture_service.dart';
import 'package:music_tools/core/audio/pitch_detector.dart';
import 'package:music_tools/core/audio/rhythm_detector.dart';
import 'package:music_tools/core/chords/chord_models.dart';
import 'package:music_tools/core/metronome_engine/click_player.dart';
import 'package:music_tools/core/metronome_engine/metronome_engine.dart';
import 'package:music_tools/core/music_theory/note.dart';
import 'package:music_tools/core/music_theory/pitch.dart';
import 'package:music_tools/core/training/models/exercise_definition.dart';
import 'package:music_tools/core/training/repositories/training_progress_repository.dart';

import 'chord_sequence_catalog.dart';

/// State of a chord sequence session.
class ChordSequenceSessionState {
  ChordSequenceSessionState({
    required this.definition,
    required this.chords,
    this.currentIndex = 0,
    this.detectedNote,
    this.correctCount = 0,
    this.result = ChordSequenceResult.idle,
    this.isPlaying = false,
    this.elapsedMs = 0,
  });

  final ExerciseDefinition definition;
  final List<Chord> chords;
  final int currentIndex;
  final String? detectedNote;
  final int correctCount;
  final ChordSequenceResult result;
  final bool isPlaying;
  final int elapsedMs;

  Chord get currentChord => chords[currentIndex];

  Chord? get nextChord =>
      currentIndex + 1 < chords.length ? chords[currentIndex + 1] : null;

  ChordSequenceSessionState copyWith({
    int? currentIndex,
    String? detectedNote,
    int? correctCount,
    ChordSequenceResult? result,
    bool? isPlaying,
    int? elapsedMs,
  }) {
    return ChordSequenceSessionState(
      definition: definition,
      chords: chords,
      currentIndex: currentIndex ?? this.currentIndex,
      detectedNote: detectedNote ?? this.detectedNote,
      correctCount: correctCount ?? this.correctCount,
      result: result ?? this.result,
      isPlaying: isPlaying ?? this.isPlaying,
      elapsedMs: elapsedMs ?? this.elapsedMs,
    );
  }
}

enum ChordSequenceResult { idle, playing, correct, wrong, finished }

/// Controller for chord sequence mode.
class ChordSequenceController extends StateNotifier<ChordSequenceSessionState> {
  ChordSequenceController({
    required ExerciseDefinition definition,
    required List<Chord> chords,
    required Stream<PitchEvent> pitchStream,
    required MetronomeEngine engine,
    required ClickPlayer clickPlayer,
    required RhythmDetector rhythmDetector,
    required AudioCaptureService capture,
    required TrainingProgressRepository repository,
    required this.onFinished,
  })  : _pitchStream = pitchStream,
        _engine = engine,
        _clickPlayer = clickPlayer,
        _rhythmDetector = rhythmDetector,
        _capture = capture,
        _repository = repository,
        super(
          ChordSequenceSessionState(
            definition: definition,
            chords: chords,
          ),
        ) {
    _init();
  }

  final Stream<PitchEvent> _pitchStream;
  final MetronomeEngine _engine;
  final ClickPlayer _clickPlayer;
  final RhythmDetector _rhythmDetector;
  final AudioCaptureService _capture;
  final TrainingProgressRepository _repository;
  final VoidCallback onFinished;

  StreamSubscription<PitchEvent>? _pitchSubscription;
  StreamSubscription<OnsetEvent>? _onsetSubscription;
  StreamSubscription<Uint8List>? _audioSubscription;
  Timer? _timer;

  int _lastBeat = 0;
  int _beatsOnCurrentChord = 0;

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    await _pitchSubscription?.cancel();
    await _onsetSubscription?.cancel();
    await _audioSubscription?.cancel();
    _engine.stop();
    await _clickPlayer.dispose();
    _rhythmDetector.dispose();
    await _capture.stop();
    super.dispose();
  }

  void _init() {
    final int bpm =
        (state.definition.parameters['bpm'] as int?)?.clamp(20, 200) ?? 80;
    _engine.setBpm(bpm);
  }

  Future<void> start() async {
    if (state.isPlaying) {
      return;
    }
    state = state.copyWith(
      isPlaying: true,
      result: ChordSequenceResult.playing,
      currentIndex: 0,
      correctCount: 0,
    );
    _engine.start(now: Duration.zero);
    _timer = Timer.periodic(const Duration(milliseconds: 16), _tick);
    _pitchSubscription = _pitchStream.listen(_onPitch);

    final Stream<Uint8List> stream = await _capture.start();
    _audioSubscription = stream.listen(_rhythmDetector.processChunk);
    _onsetSubscription = _rhythmDetector.onsets.listen(_onOnset);
  }

  void _tick(Timer timer) {
    state = state.copyWith(elapsedMs: state.elapsedMs + 16);
    _engine.processFrame(Duration(milliseconds: state.elapsedMs));

    if (_engine.currentBeat != _lastBeat) {
      _lastBeat = _engine.currentBeat;
      unawaited(_clickPlayer.play(accent: _engine.isCurrentBeatAccent));
      _beatsOnCurrentChord++;

      final int barsPerChord =
          state.definition.parameters['barsPerChord'] as int? ?? 1;
      if (_beatsOnCurrentChord >= barsPerChord * _engine.beatsPerBar) {
        _advanceChord();
      }
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
  }

  void _onOnset(OnsetEvent event) {
    final Set<int> expected = state.currentChord.pitchClasses;
    if (expected.isEmpty) {
      return;
    }
    final bool correct = expected.every(_detectedPitchClasses.contains);
    if (correct) {
      state = state.copyWith(
        correctCount: state.correctCount + 1,
        result: ChordSequenceResult.correct,
      );
    }
  }

  final Set<int> _detectedPitchClasses = <int>{};

  void _advanceChord() {
    _detectedPitchClasses.clear();
    final int nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.chords.length) {
      _finish();
      return;
    }
    state = state.copyWith(
      currentIndex: nextIndex,
      detectedNote: null,
      result: ChordSequenceResult.playing,
    );
    _beatsOnCurrentChord = 0;
  }

  Future<void> _finish() async {
    _timer?.cancel();
    await _pitchSubscription?.cancel();
    await _onsetSubscription?.cancel();
    await _audioSubscription?.cancel();
    _engine.stop();
    await _capture.stop();

    final double accuracy =
        state.chords.isEmpty ? 0 : state.correctCount / state.chords.length;
    await _repository.saveAttempt(
      exerciseId: state.definition.id,
      accuracy: accuracy,
      durationMs: state.elapsedMs,
    );
    await _repository.unlockNextLevel(
      state.definition,
      ChordSequenceCatalog.buildDefinitions(),
    );

    state = state.copyWith(
      result: ChordSequenceResult.finished,
      isPlaying: false,
    );
    onFinished();
  }
}

typedef VoidCallback = void Function();
