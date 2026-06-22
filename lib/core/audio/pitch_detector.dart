import 'dart:async';
import 'dart:typed_data';

import 'audio_capture_service.dart';
import 'yin_pitch.dart';

/// A single pitch-detection result emitted by [PitchDetector].
class PitchEvent {
  const PitchEvent({required this.frequency, required this.confidence});

  /// Detected frequency in Hz. `0` when no pitch (silence / noise).
  final double frequency;

  /// YIN confidence (0..1). `0` when no pitch.
  final double confidence;

  bool get hasPitch => frequency > 0;
}

/// Subscribes to an [AudioCaptureService], converts the 16-bit PCM stream to
/// samples, runs YIN on a sliding window and emits stabilized [PitchEvent]s.
///
/// Stabilization combines a noise gate (RMS) and a median filter over recent
/// detections to suppress jitter and octave errors.
class PitchDetector {
  PitchDetector({
    required this.capture,
    // A larger window fits several periods of the lowest guitar string (E2,
    // ~82 Hz) so YIN locks onto its true fundamental instead of an octave/
    // harmonic — or missing it entirely.
    this.windowSize = 4096,
    // True-RMS amplitude gate (~-40 dBFS): low enough to catch a softly played
    // string a short distance from the mic, high enough to reject room noise.
    this.noiseGate = 0.01,
    this.smoothingFrames = 5,
    this.holdFrames = 3,
    YinPitchDetector? yin,
  }) : yin = yin ?? YinPitchDetector(sampleRate: capture.sampleRate);

  final AudioCaptureService capture;
  final int windowSize;
  final double noiseGate;
  final int smoothingFrames;
  final int holdFrames;
  final YinPitchDetector yin;

  final List<double> _buffer = <double>[];
  final List<double> _history = <double>[];
  int _silenceFrames = 0;
  double _lastEmitted = 0;

  StreamController<PitchEvent>? _controller;
  StreamSubscription<Uint8List>? _subscription;

  /// Starts detection and returns the stabilized pitch stream.
  Stream<PitchEvent> start() {
    _controller = StreamController<PitchEvent>.broadcast(
      onCancel: stop,
    );
    unawaited(_begin());
    return _controller!.stream;
  }

  Future<void> _begin() async {
    final Stream<Uint8List> stream = await capture.start();
    _subscription = stream.listen(_onData);
  }

  void _onData(Uint8List chunk) {
    final int frameCount = chunk.length ~/ 2;
    for (int i = 0; i < frameCount; i++) {
      int raw = (chunk[i * 2 + 1] << 8) | chunk[i * 2];
      if (raw >= 0x8000) {
        raw -= 0x10000;
      }
      _buffer.add(raw / 32768);
    }

    while (_buffer.length >= windowSize) {
      _processWindow();
      // Overlap by half a window.
      _buffer.removeRange(0, windowSize ~/ 2);
    }
  }

  void _processWindow() {
    final Float64List window = Float64List(windowSize);
    for (int i = 0; i < windowSize; i++) {
      window[i] = _buffer[i];
    }

    final double amplitude = rms(window);
    if (amplitude < noiseGate) {
      _handleSilence();
      return;
    }

    final double? freq = yin.detect(window);
    if (freq == null || freq <= 0) {
      _handleSilence();
      return;
    }

    _silenceFrames = 0;
    _history.add(freq);
    if (_history.length > smoothingFrames) {
      _history.removeAt(0);
    }
    final double smoothed = _median(_history);
    _lastEmitted = smoothed;
    _emit(PitchEvent(frequency: smoothed, confidence: yin.confidence));
  }

  /// Brief hold (hysteresis): keep emitting the last detected pitch for a few
  /// frames of silence to avoid flicker, then fall back to "no pitch".
  void _handleSilence() {
    _silenceFrames++;
    if (_lastEmitted > 0 && _silenceFrames <= holdFrames) {
      _emit(PitchEvent(frequency: _lastEmitted, confidence: 0));
      return;
    }
    _history.clear();
    _lastEmitted = 0;
    _emit(const PitchEvent(frequency: 0, confidence: 0));
  }

  void _emit(PitchEvent event) {
    final StreamController<PitchEvent>? controller = _controller;
    if (controller != null && controller.hasListener && !controller.isClosed) {
      controller.add(event);
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await capture.stop();
    _buffer.clear();
    _history.clear();
  }

  double _median(List<double> values) {
    final List<double> sorted = List<double>.of(values)..sort();
    final int mid = sorted.length ~/ 2;
    if (sorted.length.isEven) {
      return (sorted[mid - 1] + sorted[mid]) / 2;
    }
    return sorted[mid];
  }
}
