import '../audio/guitar_synth.dart';
import '../music_theory/pitch.dart';
import '../music_theory/tuning.dart';

/// User-configurable, persistent application settings.
class AppSettings {
  const AppSettings({
    this.a4Reference = defaultA4,
    this.notation = Notation.letters,
    this.defaultTuningPreset = TuningPresetId.standard,
    this.rememberLast = true,
    this.lastTabIndex = 0,
    this.lastBpm = defaultBpm,
    this.lastBeatsPerBar = defaultBeatsPerBar,
    this.guitarTone = GuitarTone.acoustic,
    this.chordLoopEnabled = false,
    this.chordLoopBpm = defaultChordLoopBpm,
    this.chordLoopBeatsPerBar = defaultBeatsPerBar,
  });

  static const double defaultA4 = 440;
  static const double minA4 = 415;
  static const double maxA4 = 466;
  static const int defaultBpm = 120;
  static const int defaultBeatsPerBar = 4;
  static const int defaultChordLoopBpm = 80;
  static const int minChordLoopBpm = 20;
  static const int maxChordLoopBpm = 200;

  /// Clamps a chord-loop BPM value to the supported range.
  static int clampChordLoopBpm(int value) =>
      value.clamp(minChordLoopBpm, maxChordLoopBpm);

  /// Tuning reference frequency for A4, in Hz.
  final double a4Reference;

  /// How note names are rendered (letters vs. solfège).
  final Notation notation;

  /// Tuning preset used by default across tools.
  final TuningPresetId defaultTuningPreset;

  /// Whether to restore the last tab / BPM / time signature on relaunch.
  final bool rememberLast;

  /// Index of the last active tab (restored when [rememberLast] is true).
  final int lastTabIndex;

  /// Last metronome BPM (restored when [rememberLast] is true).
  final int lastBpm;

  /// Last metronome beats-per-bar (restored when [rememberLast] is true).
  final int lastBeatsPerBar;

  /// Guitar timbre (SoundFont) used to play notes in the training exercises.
  final GuitarTone guitarTone;

  /// Whether the chord trainer should loop the reference chord automatically.
  final bool chordLoopEnabled;

  /// Tempo (BPM) used for the chord trainer loop.
  final int chordLoopBpm;

  /// Beats per bar (time signature) used for the chord trainer loop.
  final int chordLoopBeatsPerBar;

  /// Clamps an A4 value to the supported range.
  static double clampA4(double value) =>
      value.clamp(minA4, maxA4).toDouble();

  AppSettings copyWith({
    double? a4Reference,
    Notation? notation,
    TuningPresetId? defaultTuningPreset,
    bool? rememberLast,
    int? lastTabIndex,
    int? lastBpm,
    int? lastBeatsPerBar,
    GuitarTone? guitarTone,
    bool? chordLoopEnabled,
    int? chordLoopBpm,
    int? chordLoopBeatsPerBar,
  }) {
    return AppSettings(
      a4Reference: a4Reference ?? this.a4Reference,
      notation: notation ?? this.notation,
      defaultTuningPreset: defaultTuningPreset ?? this.defaultTuningPreset,
      rememberLast: rememberLast ?? this.rememberLast,
      lastTabIndex: lastTabIndex ?? this.lastTabIndex,
      lastBpm: lastBpm ?? this.lastBpm,
      lastBeatsPerBar: lastBeatsPerBar ?? this.lastBeatsPerBar,
      guitarTone: guitarTone ?? this.guitarTone,
      chordLoopEnabled: chordLoopEnabled ?? this.chordLoopEnabled,
      chordLoopBpm: chordLoopBpm ?? this.chordLoopBpm,
      chordLoopBeatsPerBar:
          chordLoopBeatsPerBar ?? this.chordLoopBeatsPerBar,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      a4Reference == other.a4Reference &&
      notation == other.notation &&
      defaultTuningPreset == other.defaultTuningPreset &&
      rememberLast == other.rememberLast &&
      lastTabIndex == other.lastTabIndex &&
      lastBpm == other.lastBpm &&
      lastBeatsPerBar == other.lastBeatsPerBar &&
      guitarTone == other.guitarTone &&
      chordLoopEnabled == other.chordLoopEnabled &&
      chordLoopBpm == other.chordLoopBpm &&
      chordLoopBeatsPerBar == other.chordLoopBeatsPerBar;

  @override
  int get hashCode => Object.hash(
        a4Reference,
        notation,
        defaultTuningPreset,
        rememberLast,
        lastTabIndex,
        lastBpm,
        lastBeatsPerBar,
        guitarTone,
        chordLoopEnabled,
        chordLoopBpm,
        chordLoopBeatsPerBar,
      );
}
