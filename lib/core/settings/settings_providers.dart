import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../music_theory/pitch.dart';
import '../music_theory/tuning.dart';
import 'settings.dart';

/// SharedPreferences instance. Must be overridden (e.g. from `main` after
/// `await SharedPreferences.getInstance()`, or with a mock in tests).
final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>((Ref<SharedPreferences> ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

const String _kA4 = 'settings.a4Reference';
const String _kNotation = 'settings.notation';
const String _kDefaultTuning = 'settings.defaultTuningPreset';
const String _kRememberLast = 'settings.rememberLast';
const String _kLastTab = 'settings.lastTabIndex';
const String _kLastBpm = 'settings.lastBpm';
const String _kLastBeatsPerBar = 'settings.lastBeatsPerBar';

Notation _readNotation(SharedPreferences prefs) {
  final String? raw = prefs.getString(_kNotation);
  if (raw == null) {
    return Notation.letters;
  }
  try {
    return Notation.values.byName(raw);
  } on ArgumentError {
    return Notation.letters;
  }
}

TuningPresetId _readTuningPreset(SharedPreferences prefs) {
  final String? raw = prefs.getString(_kDefaultTuning);
  if (raw == null) {
    return TuningPresetId.standard;
  }
  try {
    return TuningPresetId.values.byName(raw);
  } on ArgumentError {
    return TuningPresetId.standard;
  }
}

/// Persistent application settings backed by [sharedPreferencesProvider].
final NotifierProvider<SettingsNotifier, AppSettings> settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final SharedPreferences prefs = _prefs;
    return AppSettings(
      a4Reference: AppSettings.clampA4(
        prefs.getDouble(_kA4) ?? AppSettings.defaultA4,
      ),
      notation: _readNotation(prefs),
      defaultTuningPreset: _readTuningPreset(prefs),
      rememberLast: prefs.getBool(_kRememberLast) ?? true,
      lastTabIndex: prefs.getInt(_kLastTab) ?? 0,
      lastBpm: prefs.getInt(_kLastBpm) ?? AppSettings.defaultBpm,
      lastBeatsPerBar:
          prefs.getInt(_kLastBeatsPerBar) ?? AppSettings.defaultBeatsPerBar,
    );
  }

  void setA4Reference(double value) {
    final double clamped = AppSettings.clampA4(value);
    state = state.copyWith(a4Reference: clamped);
    unawaited(_prefs.setDouble(_kA4, clamped));
  }

  void setNotation(Notation value) {
    state = state.copyWith(notation: value);
    unawaited(_prefs.setString(_kNotation, value.name));
  }

  void setDefaultTuningPreset(TuningPresetId value) {
    state = state.copyWith(defaultTuningPreset: value);
    unawaited(_prefs.setString(_kDefaultTuning, value.name));
  }

  void setRememberLast(bool value) {
    state = state.copyWith(rememberLast: value);
    unawaited(_prefs.setBool(_kRememberLast, value));
  }

  void setLastTabIndex(int value) {
    state = state.copyWith(lastTabIndex: value);
    unawaited(_prefs.setInt(_kLastTab, value));
  }

  void setLastBpm(int value) {
    state = state.copyWith(lastBpm: value);
    unawaited(_prefs.setInt(_kLastBpm, value));
  }

  void setLastBeatsPerBar(int value) {
    state = state.copyWith(lastBeatsPerBar: value);
    unawaited(_prefs.setInt(_kLastBeatsPerBar, value));
  }
}

/// Configured A4 reference frequency in Hz.
final Provider<double> a4ReferenceProvider =
    Provider<double>((Ref<double> ref) {
  return ref.watch(settingsProvider).a4Reference;
});

/// Configured notation for note names.
final Provider<Notation> notationProvider =
    Provider<Notation>((Ref<Notation> ref) {
  return ref.watch(settingsProvider).notation;
});

/// Configured default tuning preset.
final Provider<TuningPresetId> defaultTuningPresetProvider =
    Provider<TuningPresetId>((Ref<TuningPresetId> ref) {
  return ref.watch(settingsProvider).defaultTuningPreset;
});

/// Tuning preset currently selected for the per-string tuner / fretboard.
///
/// Defaults to the configured [defaultTuningPresetProvider].
final Provider<TuningPreset> selectedTuningProvider =
    Provider<TuningPreset>((Ref<TuningPreset> ref) {
  final TuningPresetId id = ref.watch(defaultTuningPresetProvider);
  return TuningPreset.byId(id);
});
