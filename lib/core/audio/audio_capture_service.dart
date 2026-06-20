import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

/// Captures raw mono 16-bit PCM from the microphone as a stream of bytes.
abstract class AudioCaptureService {
  /// Sample rate (Hz) of the captured audio.
  int get sampleRate;

  /// Whether the app is allowed to record audio.
  Future<bool> hasPermission();

  /// Starts capture and returns the PCM byte stream.
  Future<Stream<Uint8List>> start();

  /// Stops capture.
  Future<void> stop();

  /// Releases resources.
  Future<void> dispose();
}

/// [AudioCaptureService] backed by the `record` package (Android + iOS).
class RecordAudioCaptureService implements AudioCaptureService {
  RecordAudioCaptureService({this.sampleRate = 44100});

  @override
  final int sampleRate;

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _subscription;
  bool _running = false;

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<Stream<Uint8List>> start() async {
    if (_running) {
      throw StateError('Audio capture already running');
    }
    _running = true;
    return _recorder.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
      ),
    );
  }

  @override
  Future<void> stop() async {
    if (!_running) {
      return;
    }
    _running = false;
    await _subscription?.cancel();
    _subscription = null;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
  }
}

/// In-memory capture service for tests: emits provided PCM chunks.
class FakeAudioCaptureService implements AudioCaptureService {
  FakeAudioCaptureService({this.sampleRate = 44100});

  @override
  final int sampleRate;

  final StreamController<Uint8List> _controller =
      StreamController<Uint8List>.broadcast();

  void emit(Uint8List chunk) => _controller.add(chunk);

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<Stream<Uint8List>> start() async => _controller.stream;

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async => _controller.close();
}
