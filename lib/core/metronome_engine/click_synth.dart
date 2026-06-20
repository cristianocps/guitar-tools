import 'dart:math';
import 'dart:typed_data';

/// Synthesizes a short click as a 16-bit PCM WAV byte buffer for the metronome.
class ClickSynth {
  const ClickSynth._();

  /// Builds a damped-sine click.
  ///
  /// [frequency] sets the timbre (use higher values for the accent).
  static Uint8List buildClick({
    required int sampleRate,
    double frequency = 1000,
    double duration = 0.05,
    double amplitude = 0.9,
    double decay = 28,
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
    view.setUint32(16, 16, Endian.little); // PCM chunk size
    view.setUint16(20, 1, Endian.little); // PCM format
    view.setUint16(22, 1, Endian.little); // mono
    view.setUint32(24, sampleRate, Endian.little);
    view.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    view.setUint16(32, 2, Endian.little); // block align
    view.setUint16(34, 16, Endian.little); // bits per sample
    writeString(36, 'data');
    view.setUint32(40, dataSize, Endian.little);

    for (int i = 0; i < frames; i++) {
      final double t = i / sampleRate;
      final double env = amplitude * exp(-decay * t);
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
