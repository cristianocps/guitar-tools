import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_tools/core/audio/audio_capture_service.dart';
import 'package:music_tools/core/audio/pitch_detector.dart';

/// Builds little-endian 16-bit PCM bytes for a sine wave.
Uint8List pcmSine({
  required double frequency,
  required int sampleRate,
  required int frames,
  double amplitude = 0.85,
}) {
  final Uint8List bytes = Uint8List(frames * 2);
  final ByteData view = ByteData.view(bytes.buffer);
  for (int i = 0; i < frames; i++) {
    final double s = amplitude * sin(2 * pi * frequency * i / sampleRate);
    final int raw = (s * 32767).round();
    view.setInt16(i * 2, raw, Endian.little);
  }
  return bytes;
}

void main() {
  const int sampleRate = 44100;

  test('emits a stabilized pitch for a 440 Hz sine feed', () async {
    final FakeAudioCaptureService capture =
        FakeAudioCaptureService(sampleRate: sampleRate);
    final PitchDetector detector =
        PitchDetector(capture: capture, windowSize: 1024, smoothingFrames: 3);
    final List<PitchEvent> events = <PitchEvent>[];
    detector.start().listen(events.add);
    await Future<void>.delayed(Duration.zero);

    final Uint8List bytes =
        pcmSine(frequency: 440, sampleRate: sampleRate, frames: 8000);
    for (int i = 0; i < bytes.length; i += 512) {
      final int end = min<int>(i + 512, bytes.length);
      capture.emit(Uint8List.fromList(bytes.sublist(i, end)));
    }
    await Future<void>.delayed(Duration.zero);

    final List<PitchEvent> pitched =
        events.where((PitchEvent e) => e.hasPitch).toList();
    expect(pitched, isNotEmpty);
    expect(pitched.last.frequency, closeTo(440, 5));
  });

  test('emits silence (0 Hz) for a quiet feed', () async {
    final FakeAudioCaptureService capture =
        FakeAudioCaptureService(sampleRate: sampleRate);
    final PitchDetector detector =
        PitchDetector(capture: capture, windowSize: 1024, smoothingFrames: 3);
    final List<PitchEvent> events = <PitchEvent>[];
    detector.start().listen(events.add);
    await Future<void>.delayed(Duration.zero);

    // Near-silence.
    capture.emit(Uint8List(8000));
    await Future<void>.delayed(Duration.zero);

    expect(events, isNotEmpty);
    for (final PitchEvent e in events) {
      expect(e.hasPitch, isFalse);
    }
  });
}
