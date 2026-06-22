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
class RhythmDetector {
  RhythmDetector({
    required this.sampleRate,
    this.threshold = 0.15,
    this.cooldownMs = 150,
  });

  final int sampleRate;
  final double threshold;
  final int cooldownMs;

  final StreamController<OnsetEvent> _onsetController =
      StreamController<OnsetEvent>.broadcast();

  Stream<OnsetEvent> get onsets => _onsetController.stream;

  DateTime? _lastOnset;

  /// Feeds a chunk of PCM16 bytes and emits onsets when detected.
  void processChunk(Uint8List bytes) {
    final Float64List samples = _pcm16ToFloat(bytes);
    final double energy = _rms(samples);
    if (energy < threshold) {
      return;
    }
    final DateTime now = DateTime.now();
    if (_lastOnset != null &&
        now.difference(_lastOnset!).inMilliseconds < cooldownMs) {
      return;
    }
    _lastOnset = now;
    _onsetController.add(OnsetEvent(timestamp: now));
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

  static double _rms(Float64List samples) {
    if (samples.isEmpty) {
      return 0;
    }
    double sum = 0;
    for (final double s in samples) {
      sum += s * s;
    }
    return sqrt(sum / samples.length);
  }

  void dispose() {
    _onsetController.close();
  }
}
