import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_tools/core/music_theory/pitch.dart';
import 'package:music_tools/core/music_theory/tuning.dart';
import 'package:music_tools/core/settings/settings.dart';
import 'package:music_tools/core/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer makeContainer() {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('defaults when nothing persisted', () {
    final ProviderContainer container = makeContainer();
    expect(container.read(settingsProvider), const AppSettings());
  });

  test('setters persist and update state', () {
    final ProviderContainer container = makeContainer();
    final SettingsNotifier notifier =
        container.read(settingsProvider.notifier);
    notifier.setA4Reference(442);
    notifier.setNotation(Notation.solfeggio);
    notifier.setDefaultTuningPreset(TuningPresetId.dropD);
    notifier.setRememberLast(false);
    notifier.setLastTabIndex(2);
    notifier.setLastBpm(96);
    notifier.setLastBeatsPerBar(6);

    final AppSettings s = container.read(settingsProvider);
    expect(s.a4Reference, 442);
    expect(s.notation, Notation.solfeggio);
    expect(s.defaultTuningPreset, TuningPresetId.dropD);
    expect(s.rememberLast, isFalse);
    expect(s.lastTabIndex, 2);
    expect(s.lastBpm, 96);
    expect(s.lastBeatsPerBar, 6);

    // Backing store was written.
    expect(prefs.getDouble('settings.a4Reference'), 442);
    expect(prefs.getString('settings.notation'), 'solfeggio');
    expect(prefs.getString('settings.defaultTuningPreset'), 'dropD');
    expect(prefs.getBool('settings.rememberLast'), isFalse);
    expect(prefs.getInt('settings.lastTabIndex'), 2);
    expect(prefs.getInt('settings.lastBpm'), 96);
    expect(prefs.getInt('settings.lastBeatsPerBar'), 6);
  });

  test('round-trip across containers sharing the store', () {
    final ProviderContainer c1 = makeContainer();
    c1.read(settingsProvider.notifier).setA4Reference(445);
    c1.read(settingsProvider.notifier).setNotation(Notation.solfeggio);
    c1.read(settingsProvider.notifier)
        .setDefaultTuningPreset(TuningPresetId.openG);

    final ProviderContainer c2 = makeContainer();
    final AppSettings s = c2.read(settingsProvider);
    expect(s.a4Reference, 445);
    expect(s.notation, Notation.solfeggio);
    expect(s.defaultTuningPreset, TuningPresetId.openG);
  });

  test('A4 is clamped to the supported range', () {
    final ProviderContainer container = makeContainer();
    container.read(settingsProvider.notifier).setA4Reference(1000);
    expect(
      container.read(settingsProvider).a4Reference,
      AppSettings.maxA4,
    );
    container.read(settingsProvider.notifier).setA4Reference(100);
    expect(
      container.read(settingsProvider).a4Reference,
      AppSettings.minA4,
    );
  });

  test('selectedTuningProvider follows the configured default', () {
    final ProviderContainer container = makeContainer();
    expect(container.read(selectedTuningProvider), TuningPreset.standard);
    container.read(settingsProvider.notifier)
        .setDefaultTuningPreset(TuningPresetId.dadgad);
    expect(container.read(selectedTuningProvider), TuningPreset.dadgad);
  });

  test('garbage persisted values fall back to defaults', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'settings.notation': 'bogus',
      'settings.defaultTuningPreset': 'bogus',
      'settings.a4Reference': 9999.0,
    });
    prefs = await SharedPreferences.getInstance();
    final ProviderContainer container = makeContainer();
    final AppSettings s = container.read(settingsProvider);
    expect(s.notation, Notation.letters);
    expect(s.defaultTuningPreset, TuningPresetId.standard);
    expect(s.a4Reference, AppSettings.maxA4);
  });
}
