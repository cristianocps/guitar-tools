import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'click_player.dart';

/// Available time signatures for the metronome.
const List<int> availableBeatsPerBar = <int>[2, 3, 4, 6];

/// Immutable metronome settings.
class MetronomeSettings {
  const MetronomeSettings({
    this.bpm = 120,
    this.beatsPerBar = 4,
    this.isPlaying = false,
  });

  final int bpm;
  final int beatsPerBar;
  final bool isPlaying;

  MetronomeSettings copyWith({
    int? bpm,
    int? beatsPerBar,
    bool? isPlaying,
  }) {
    return MetronomeSettings(
      bpm: bpm ?? this.bpm,
      beatsPerBar: beatsPerBar ?? this.beatsPerBar,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}

class MetronomeSettingsNotifier extends Notifier<MetronomeSettings> {
  @override
  MetronomeSettings build() => const MetronomeSettings();

  void setBpm(int value) {
    state = state.copyWith(bpm: value.clamp(20, 280));
  }

  void setBeatsPerBar(int value) {
    state = state.copyWith(beatsPerBar: value);
  }

  void togglePlay() {
    state = state.copyWith(isPlaying: !state.isPlaying);
  }
}

final metronomeSettingsProvider =
    NotifierProvider<MetronomeSettingsNotifier, MetronomeSettings>(
  MetronomeSettingsNotifier.new,
);

/// Shared click player for the metronome.
final clickPlayerProvider = Provider<ClickPlayer>((ref) {
  final player = ClickPlayer();
  ref.onDispose(player.dispose);
  return player;
});
