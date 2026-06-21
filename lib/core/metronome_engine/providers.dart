import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings.dart';
import '../settings/settings_providers.dart';
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
  MetronomeSettings build() {
    final AppSettings settings = ref.read(settingsProvider);
    if (!settings.rememberLast) {
      return const MetronomeSettings();
    }
    return MetronomeSettings(
      bpm: settings.lastBpm.clamp(20, 280),
      beatsPerBar: settings.lastBeatsPerBar,
    );
  }

  /// Live BPM update (e.g. during a slider drag). Updates state only; the
  /// final value should be committed via [setBpm] (e.g. on `onChangeEnd`).
  void previewBpm(int value) {
    state = state.copyWith(bpm: value.clamp(20, 280));
  }

  void setBpm(int value) {
    final int clamped = value.clamp(20, 280);
    state = state.copyWith(bpm: clamped);
    if (ref.read(settingsProvider).rememberLast) {
      ref.read(settingsProvider.notifier).setLastBpm(clamped);
    }
  }

  void setBeatsPerBar(int value) {
    state = state.copyWith(beatsPerBar: value);
    if (ref.read(settingsProvider).rememberLast) {
      ref.read(settingsProvider.notifier).setLastBeatsPerBar(value);
    }
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
