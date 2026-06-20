import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_tools/core/audio/yin_pitch.dart';

Float64List sineWave({
  required double frequency,
  required int sampleRate,
  required int size,
  double amplitude = 0.8,
}) {
  final Float64List samples = Float64List(size);
  for (int i = 0; i < size; i++) {
    samples[i] = amplitude * sin(2 * pi * frequency * i / sampleRate);
  }
  return samples;
}

void main() {
  const int sampleRate = 44100;

  group('YinPitchDetector', () {
    test('detects 440 Hz (A4)', () {
      final YinPitchDetector yin = YinPitchDetector(sampleRate: sampleRate);
      final Float64List signal =
          sineWave(frequency: 440, sampleRate: sampleRate, size: 2048);
      final double? f = yin.detect(signal);
      expect(f, isNotNull);
      expect(f!, closeTo(440, 3));
      expect(yin.confidence, greaterThan(0.7));
    });

    test('detects 220 Hz (A3)', () {
      final YinPitchDetector yin = YinPitchDetector(sampleRate: sampleRate);
      final double? f = yin.detect(
        sineWave(frequency: 220, sampleRate: sampleRate, size: 2048),
      );
      expect(f, closeTo(220, 3));
    });

    test('detects 110 Hz (A2)', () {
      final YinPitchDetector yin = YinPitchDetector(sampleRate: sampleRate);
      final double? f = yin.detect(
        sineWave(frequency: 110, sampleRate: sampleRate, size: 2048),
      );
      expect(f, closeTo(110, 3));
    });

    test('detects low 82 Hz (E2) with a larger window', () {
      final YinPitchDetector yin = YinPitchDetector(sampleRate: sampleRate);
      final double? f = yin.detect(
        sineWave(frequency: 82, sampleRate: sampleRate, size: 8192),
      );
      expect(f, closeTo(82, 3));
    });

    test('returns null for silence', () {
      final YinPitchDetector yin = YinPitchDetector(sampleRate: sampleRate);
      final Float64List silence = Float64List(2048); // all zeros
      final double? f = yin.detect(silence);
      expect(f, isNull);
    });
  });

  group('rms', () {
    test('zero for silence, positive for signal', () {
      expect(rms(Float64List(2048)), 0);
      expect(
        rms(sineWave(frequency: 440, sampleRate: sampleRate, size: 2048)),
        greaterThan(0),
      );
    });
  });
}
