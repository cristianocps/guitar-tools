import 'dart:math';
import 'dart:typed_data';

/// Synthesizes a pure-tone note as a 16-bit PCM mono WAV byte buffer.
class ToneGenerator {
  const ToneGenerator._();

  /// Builds a sine wave tone at [frequency] Hz.
  static Uint8List buildTone({
    required double frequency,
    required int sampleRate,
    double duration = 0.5,
    double amplitude = 0.8,
    double attack = 0.02,
    double release = 0.05,
  }) {
    final int frames = (sampleRate * duration).round();
    final int dataSize = frames * 2;
    final Uint8List buffer = Uint8List(44 + dataSize);
    final ByteData view = ByteData.view(buffer.buffer);

    void writeString(int offset, String value) {
      for (int i = 0; i < value.length; i++) {
        buffer[offset + i] = value.codeUnitAt(i);
      }
    }

    // RIFF/WAVE header.
    writeString(0, 'RIFF');
    view.setUint32(4, 36 + dataSize, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    view.setUint32(16, 16, Endian.little);
    view.setUint16(20, 1, Endian.little); // PCM
    view.setUint16(22, 1, Endian.little); // mono
    view.setUint32(24, sampleRate, Endian.little);
    view.setUint32(28, sampleRate * 2, Endian.little);
    view.setUint16(32, 2, Endian.little);
    view.setUint16(34, 16, Endian.little);
    writeString(36, 'data');
    view.setUint32(40, dataSize, Endian.little);

    final int attackFrames = (sampleRate * attack).round().clamp(0, frames ~/ 2);
    final int releaseFrames =
        (sampleRate * release).round().clamp(0, frames - attackFrames);

    for (int i = 0; i < frames; i++) {
      final double t = i / sampleRate;
      double env = amplitude;
      if (i < attackFrames) {
        env *= i / attackFrames;
      } else if (i >= frames - releaseFrames) {
        env *= (frames - i) / releaseFrames;
      }
      final double s = env * sin(2 * pi * frequency * t);
      view.setInt16(
        44 + i * 2,
        (s * 32767).round().clamp(-32768, 32767),
        Endian.little,
      );
    }
    return buffer;
  }
}
