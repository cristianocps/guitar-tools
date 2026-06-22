import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

/// Emitted when an onset (transient) is detected in the audio stream.
class OnsetEvent {
  OnsetEvent({required this.timestamp});

  /// System timestamp when the onset was detected.
  final DateTime timestamp;
}

/// Detects rhythmic onsets in a raw PCM16 mono audio stream.
///
/// Rather than gating on absolute loudness (which misses softer plucks and
/// dilutes transients when the audio arrives in large chunks), this scans the
/// audio in short frames and flags an onset whenever the energy *rises*
/// sharply above a slowly-tracked baseline — i.e. an attack — while staying
/// above a small noise floor. One onset is reported per attack; it re-arms once
/// the energy settles back down, so a sustained note doesn't retrigger.
class RhythmDetector {
  RhythmDetector({
    required this.sampleRate,
    this.noiseFloor = 0.02,
    this.riseFactor = 1.6,
    this.cooldownMs = 120,
    this.frameSize = 256,
  });

  final int sampleRate;

  /// Minimum frame RMS to be considered sound at all.
  final double noiseFloor;

  /// A frame must exceed `baseline * riseFactor` to count as an attack.
  final double riseFactor;

  /// Minimum time between consecutive onsets.
  final int cooldownMs;

  /// Analysis frame length in samples (time resolution of detection).
  final int frameSize;

  final StreamController<OnsetEvent> _onsetController =
      StreamController<OnsetEvent>.broadcast();

  Stream<OnsetEvent> get onsets => _onsetController.stream;

  DateTime? _lastOnset;
  double _baseline = 0;
  bool _armed = true;

  /// Feeds a chunk of PCM16 bytes and emits onsets when detected.
  void processChunk(Uint8List bytes) {
    final Float64List samples = _pcm16ToFloat(bytes);
    final int n = samples.length;
    if (n == 0) {
      return;
    }
    for (int start = 0; start < n; start += frameSize) {
      final int end = min(start + frameSize, n);
      _processFrame(samples, start, end);
    }
  }

  void _processFrame(Float64List samples, int start, int end) {
    final int count = end - start;
    if (count <= 0) {
      return;
    }
    double sum = 0;
    for (int i = start; i < end; i++) {
      final double v = samples[i];
      sum += v * v;
    }
    final double energy = sqrt(sum / count);

    final bool loudEnough = energy > noiseFloor;
    final bool isRise = energy > _baseline * riseFactor;
    final DateTime now = DateTime.now();
    final bool cooldownOk = _lastOnset == null ||
        now.difference(_lastOnset!).inMilliseconds >= cooldownMs;

    if (loudEnough && isRise && _armed && cooldownOk) {
      _lastOnset = now;
      _armed = false;
      _onsetController.add(OnsetEvent(timestamp: now));
    }

    // Re-arm once the energy falls back near the running baseline, so the next
    // attack can be detected (but a sustained note doesn't keep firing).
    if (energy < _baseline * 1.1 || energy < noiseFloor) {
      _armed = true;
    }

    // Envelope follower: track the slowly-varying background level.
    const double smoothing = 0.05;
    _baseline += smoothing * (energy - _baseline);
  }

  static Float64List _pcm16ToFloat(Uint8List bytes) {
    final int sampleCount = bytes.length ~/ 2;
    final Float64List out = Float64List(sampleCount);
    final ByteData view = ByteData.sublistView(bytes);
    for (int i = 0; i < sampleCount; i++) {
      out[i] = view.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return out;
  }

  void dispose() {
    _onsetController.close();
  }
}
