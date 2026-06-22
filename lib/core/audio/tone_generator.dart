import 'dart:math';
import 'dart:typed_data';

/// Synthesizes short plucked-string notes as 16-bit PCM mono WAV buffers.
///
/// Uses the Karplus–Strong algorithm: a short burst of noise excites a tuned
/// delay line whose feedback low-pass filter makes the upper harmonics decay
/// faster than the fundamental, producing a natural plucked-string timbre —
/// far closer to a guitar than a pure sine, and with no audio assets or extra
/// dependencies. Works for any pitch.
class ToneGenerator {
  const ToneGenerator._();

  static final Random _random = Random();

  /// Builds a plucked-string note at [frequency] Hz.
  ///
  /// The signature is kept compatible with the previous sine generator so all
  /// callers work unchanged: [amplitude] sets the normalized peak level and
  /// [attack]/[release] are short fades (seconds) that avoid start/end clicks.
  static Uint8List buildTone({
    required double frequency,
    required int sampleRate,
    double duration = 0.6,
    double amplitude = 0.8,
    double attack = 0.005,
    double release = 0.06,
  }) {
    final int frames = (sampleRate * duration).round();
    final Float64List samples = _karplusStrong(
      frequency: frequency,
      sampleRate: sampleRate,
      frames: frames,
    );

    // Normalize so the loudest sample reaches `amplitude`.
    double peak = 0;
    for (final double s in samples) {
      final double a = s.abs();
      if (a > peak) {
        peak = a;
      }
    }
    final double gain = peak > 0 ? amplitude / peak : 0;

    final int attackFrames = (sampleRate * attack).round().clamp(0, frames);
    final int releaseFrames = (sampleRate * release).round().clamp(0, frames);

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

    for (int i = 0; i < frames; i++) {
      double env = gain;
      if (attackFrames > 0 && i < attackFrames) {
        env *= i / attackFrames;
      }
      final int fromEnd = frames - 1 - i;
      if (releaseFrames > 0 && fromEnd < releaseFrames) {
        env *= fromEnd / releaseFrames;
      }
      final double s = samples[i] * env;
      view.setInt16(
        44 + i * 2,
        (s * 32767).round().clamp(-32768, 32767),
        Endian.little,
      );
    }
    return buffer;
  }

  /// Runs the Karplus–Strong delay line and returns the raw (un-normalized)
  /// samples.
  static Float64List _karplusStrong({
    required double frequency,
    required int sampleRate,
    required int frames,
  }) {
    final int n = (sampleRate / frequency).round().clamp(2, sampleRate);

    // Excite the delay line with white noise (the "pluck").
    final Float64List delay = Float64List(n);
    for (int i = 0; i < n; i++) {
      delay[i] = _random.nextDouble() * 2 - 1;
    }
    // Lightly low-pass the excitation for a warmer pick attack.
    for (int i = 0; i < n; i++) {
      delay[i] = 0.5 * (delay[i] + delay[(i + 1) % n]);
    }

    // Per-sample energy loss; tuned so a note rings then settles within the
    // clip rather than being abruptly cut.
    const double decay = 0.9997;

    final Float64List out = Float64List(frames);
    int idx = 0;
    for (int i = 0; i < frames; i++) {
      final double current = delay[idx];
      final int next = (idx + 1) % n;
      // Feedback low-pass: average the two oldest samples and feed back.
      delay[idx] = decay * 0.5 * (current + delay[next]);
      out[i] = current;
      idx = next;
    }
    return out;
  }
}
