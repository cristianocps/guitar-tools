// Clock-anchored metronome scheduler.
//
// Beats are scheduled at [start] + k * beatInterval, so the number of beats
// produced over time tracks the configured BPM exactly (zero cumulative
// drift). Per-frame jitter from the UI ticker does not affect the beat count,
// which is what the <0.5% drift requirement targets.

/// Fired on each scheduled beat. [beatNumber] is 1-based within the bar;
/// [isAccent] is true for the downbeat (beat 1).
typedef OnBeat = void Function(int beatNumber, bool isAccent);

class MetronomeEngine {
  MetronomeEngine({
    required this.onBeat,
    int bpm = 120,
    int beatsPerBar = 4,
  })  : _bpm = bpm.clamp(_minBpm, _maxBpm),
        _beatsPerBar = beatsPerBar;

  static const int _minBpm = 20;
  static const int _maxBpm = 280;

  final OnBeat onBeat;

  int _bpm;
  int _beatsPerBar;

  bool _playing = false;
  Duration _start = Duration.zero;
  Duration _lastNow = Duration.zero;
  int _beatIndex = 0;

  bool get isPlaying => _playing;
  int get bpm => _bpm;
  int get beatsPerBar => _beatsPerBar;

  Duration get _beatInterval =>
      Duration(microseconds: (60000000 / _bpm).round());

  void setBpm(int value) {
    _bpm = value.clamp(_minBpm, _maxBpm).toInt();
  }

  void setBeatsPerBar(int value) {
    _beatsPerBar = value < 1 ? 1 : value;
  }

  void start({required Duration now}) {
    _playing = true;
    _start = now;
    _lastNow = now;
    _beatIndex = 0;
  }

  void stop() {
    _playing = false;
  }

  /// Advances the engine to [now], firing any due beats.
  void processFrame(Duration now) {
    _lastNow = now;
    if (!_playing) {
      return;
    }
    final int intervalUs = _beatInterval.inMicroseconds;
    while ((now - _start).inMicroseconds >= _beatIndex * intervalUs) {
      final int positionInBar = _beatIndex % _beatsPerBar;
      final int beatNumber = positionInBar + 1;
      onBeat(beatNumber, positionInBar == 0);
      _beatIndex++;
    }
  }

  /// 1-based position within the bar of the most recently fired beat (0 when
  /// not playing).
  int get currentBeat =>
      _playing && _beatIndex > 0 ? ((_beatIndex - 1) % _beatsPerBar) + 1 : 0;

  /// Progress through the current beat (0..1), for pendulum/animation sync.
  double get phase {
    if (!_playing || _beatIndex <= 0) {
      return 0;
    }
    final int intervalUs = _beatInterval.inMicroseconds;
    final int beatStartUs =
        _start.inMicroseconds + (_beatIndex - 1) * intervalUs;
    final int intoBeatUs = _lastNow.inMicroseconds - beatStartUs;
    return (intoBeatUs / intervalUs).clamp(0.0, 1.0);
  }

  /// True when [now] is in the first half of the current beat (pendulum at one
  /// extreme) vs the second half (other extreme).
  bool get isCurrentBeatAccent =>
      _playing && _beatIndex > 0 && (_beatIndex - 1) % _beatsPerBar == 0;
}
