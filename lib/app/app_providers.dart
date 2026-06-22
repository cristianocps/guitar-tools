import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/settings.dart';
import '../core/settings/settings_providers.dart';

/// The app destinations.
enum AppTab { metronome, harmonicField, tuner, training }

/// Active bottom-nav tab. Restores the last tab from settings when
/// "remember last" is enabled, and persists selection on change.
final NotifierProvider<ActiveTabNotifier, AppTab> activeTabProvider =
    NotifierProvider<ActiveTabNotifier, AppTab>(ActiveTabNotifier.new);

class ActiveTabNotifier extends Notifier<AppTab> {
  @override
  AppTab build() {
    final AppSettings settings = ref.read(settingsProvider);
    if (!settings.rememberLast) {
      return AppTab.metronome;
    }
    final int index =
        settings.lastTabIndex.clamp(0, AppTab.values.length - 1);
    return AppTab.values[index];
  }

  /// Selects a tab by nav index and persists the choice.
  void selectIndex(int index) {
    final int clamped = index.clamp(0, AppTab.values.length - 1);
    final AppTab tab = AppTab.values[clamped];
    if (tab == state) {
      return;
    }
    state = tab;
    final AppSettings settings = ref.read(settingsProvider);
    if (settings.rememberLast) {
      ref.read(settingsProvider.notifier).setLastTabIndex(clamped);
    }
  }
}

/// Whether the app is in the foreground (resumed). Mic-using features pause
/// capture when this becomes false.
final StateProvider<bool> appResumedProvider =
    StateProvider<bool>((Ref<bool> ref) => true);
