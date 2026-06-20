import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import 'click_synth.dart';

/// Plays metronome clicks via [audioplayers] in low-latency mode.
///
/// Two synthesized WAV blips are prebuilt: a brighter accent for the downbeat
/// and a softer tick for the remaining beats.
class ClickPlayer {
  ClickPlayer({int sampleRate = 44100}) {
    _accentBytes = ClickSynth.buildClick(
      sampleRate: sampleRate,
      frequency: 1500,
      amplitude: 1.0,
    );
    _tickBytes = ClickSynth.buildClick(
      sampleRate: sampleRate,
      frequency: 1000,
      amplitude: 0.8,
    );
    unawaited(_accentPlayer.setPlayerMode(PlayerMode.lowLatency));
    unawaited(_tickPlayer.setPlayerMode(PlayerMode.lowLatency));
  }

  late final Uint8List _accentBytes;
  late final Uint8List _tickBytes;

  final AudioPlayer _accentPlayer = AudioPlayer(playerId: 'metro_accent');
  final AudioPlayer _tickPlayer = AudioPlayer(playerId: 'metro_tick');

  Future<void> play({required bool accent}) async {
    final AudioPlayer player = accent ? _accentPlayer : _tickPlayer;
    final Uint8List bytes = accent ? _accentBytes : _tickBytes;
    await player.play(BytesSource(bytes));
  }

  Future<void> dispose() async {
    await _accentPlayer.dispose();
    await _tickPlayer.dispose();
  }
}
