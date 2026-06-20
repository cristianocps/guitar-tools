import 'package:flutter_test/flutter_test.dart';
import 'package:music_tools/core/metronome_engine/metronome_engine.dart';

void main() {
  group('MetronomeEngine beat counting (drift)', () {
    test('beats produced over 5s match BPM exactly (<0.5% drift)', () {
      final List<(int, bool)> beats = <(int, bool)>[];
      final MetronomeEngine engine = MetronomeEngine(
        onBeat: (int n, bool a) => beats.add((n, a)),
        bpm: 120,
        beatsPerBar: 4,
      );

      engine.start(now: Duration.zero);
      for (int t = 0; t < 5000; t += 16) {
        engine.processFrame(Duration(milliseconds: t));
      }

      // 120 BPM => 500ms/beat => 10 beats in 5s.
      const int expected = 10;
      expect(beats.length, expected);
      final double drift = (beats.length - expected).abs() / expected;
      expect(drift, lessThan(0.005));
    });

    test('handles higher BPM (200) over 3s', () {
      final List<(int, bool)> beats = <(int, bool)>[];
      final MetronomeEngine engine = MetronomeEngine(
        onBeat: (int n, bool a) => beats.add((n, a)),
        bpm: 200,
        beatsPerBar: 4,
      );
      engine.start(now: Duration.zero);
      for (int t = 0; t < 3000; t += 8) {
        engine.processFrame(Duration(milliseconds: t));
      }
      // 200 BPM => 300ms/beat => 10 beats in 3s.
      expect(beats.length, 10);
    });
  });

  group('MetronomeEngine accents', () {
    test('accent only on beat 1 of each bar', () {
      final List<int> accents = <int>[];
      final MetronomeEngine engine = MetronomeEngine(
        onBeat: (int n, bool a) {
          if (a) {
            accents.add(n);
          }
        },
        bpm: 120,
        beatsPerBar: 4,
      );
      engine.start(now: Duration.zero);
      for (int t = 0; t < 5000; t += 16) {
        engine.processFrame(Duration(milliseconds: t));
      }
      // 10 beats across 3 bars => accents on beat 1 of each bar.
      expect(accents, <int>[1, 1, 1]);
    });
  });

  group('MetronomeEngine configuration', () {
    test('BPM clamps to 20..280', () {
      final MetronomeEngine engine =
          MetronomeEngine(onBeat: (_, __) {}, bpm: 120);
      engine.setBpm(10);
      expect(engine.bpm, 20);
      engine.setBpm(1000);
      expect(engine.bpm, 280);
    });

    test('phase stays within 0..1 while playing', () {
      final MetronomeEngine engine = MetronomeEngine(
        onBeat: (_, __) {},
        bpm: 120,
      );
      engine.start(now: Duration.zero);
      engine.processFrame(const Duration(milliseconds: 100));
      expect(engine.phase, inInclusiveRange(0, 1));
    });
  });
}
