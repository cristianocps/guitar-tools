import 'dart:typed_data';

/// YIN fundamental-frequency estimator (de Cheveigné & Kawahara, 2002).
///
/// Operates on a window of mono samples normalized to [-1, 1] and returns the
/// detected pitch in Hz, or null when no reliable pitch is found.
class YinPitchDetector {
  YinPitchDetector({
    this.sampleRate = 44100,
    this.threshold = 0.15,
    this.minFrequency = 60,
    this.maxFrequency = 1200,
  });

  final int sampleRate;
  final double threshold;
  final double minFrequency;
  final double maxFrequency;

  /// Confidence of the last detection (0..1). 0 when no pitch was found.
  double confidence = 0;

  /// Runs YIN over [buffer] and returns the detected frequency, or null.
  double? detect(Float64List buffer) {
    final int halfSize = buffer.length ~/ 2;
    if (halfSize < 2) {
      confidence = 0;
      return null;
    }

    final Float64List yin = Float64List(halfSize);
    yin[0] = 1;

    // Difference function + cumulative mean normalized difference.
    double runningSum = 0;
    for (int tau = 1; tau < halfSize; tau++) {
      double sum = 0;
      for (int j = 0; j < halfSize; j++) {
        final double delta = buffer[j] - buffer[j + tau];
        sum += delta * delta;
      }
      runningSum += sum;
      yin[tau] = runningSum == 0 ? 0 : sum * tau / runningSum;
    }

    // Constrain the search to the playable frequency range.
    final int tauMin = (sampleRate / maxFrequency).floor().clamp(1, halfSize - 1);
    final int tauMax =
        (sampleRate / minFrequency).ceil().clamp(tauMin + 1, halfSize);

    int tauEstimate = -1;
    for (int tau = tauMin; tau < tauMax; tau++) {
      if (yin[tau] < threshold) {
        // Descend to the local minimum of this dip.
        while (tau + 1 < tauMax && yin[tau + 1] < yin[tau]) {
          tau++;
        }
        tauEstimate = tau;
        break;
      }
    }

    if (tauEstimate < 0) {
      confidence = 0;
      return null;
    }

    confidence = 1 - yin[tauEstimate];
    final double refined = _parabolicInterpolation(yin, tauEstimate);
    final double frequency = sampleRate / refined;
    if (frequency < minFrequency || frequency > maxFrequency) {
      confidence = 0;
      return null;
    }
    return frequency;
  }

  double _parabolicInterpolation(Float64List yin, int tau) {
    final int x0 = tau > 0 ? tau - 1 : tau;
    final int x2 = tau + 1 < yin.length ? tau + 1 : tau;
    if (x0 == tau || x2 == tau) {
      return tau.toDouble();
    }
    final double s0 = yin[x0];
    final double s1 = yin[tau];
    final double s2 = yin[x2];
    final double denom = (s0 - 2 * s1 + s2);
    if (denom == 0) {
      return tau.toDouble();
    }
    return tau + 0.5 * (s0 - s2) / denom;
  }
}

/// Root-mean-square amplitude of [samples].
double rms(Float64List samples) {
  if (samples.isEmpty) {
    return 0;
  }
  double sum = 0;
  for (final double s in samples) {
    sum += s * s;
  }
  return sum / samples.length;
}
