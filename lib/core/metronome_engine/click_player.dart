import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import 'click_synth.dart';

/// Plays metronome clicks via [audioplayers] in low-latency (SoundPool) mode.
///
/// SoundPool on Android does not accept in-memory [BytesSource], so the two
/// click blips are synthesized to temp files once at startup and played via
/// [DeviceFileSource].
class ClickPlayer {
  ClickPlayer({int sampleRate = 44100}) {
    final Uint8List accentBytes = ClickSynth.buildClick(
      sampleRate: sampleRate,
      frequency: 1500,
      amplitude: 1.0,
    );
    final Uint8List tickBytes = ClickSynth.buildClick(
      sampleRate: sampleRate,
      frequency: 1000,
      amplitude: 0.8,
    );
    _ready = _init(accentBytes, tickBytes);
    unawaited(_accentPlayer.setPlayerMode(PlayerMode.lowLatency));
    unawaited(_tickPlayer.setPlayerMode(PlayerMode.lowLatency));
  }

  late final Future<void> _ready;
  late final String _accentPath;
  late final String _tickPath;

  final AudioPlayer _accentPlayer = AudioPlayer(playerId: 'metro_accent');
  final AudioPlayer _tickPlayer = AudioPlayer(playerId: 'metro_tick');

  Future<void> _init(Uint8List accentBytes, Uint8List tickBytes) async {
    final Directory dir = await getTemporaryDirectory();
    final File accent = File('${dir.path}/metro_accent.wav');
    final File tick = File('${dir.path}/metro_tick.wav');
    await accent.writeAsBytes(accentBytes, flush: true);
    await tick.writeAsBytes(tickBytes, flush: true);
    _accentPath = accent.path;
    _tickPath = tick.path;
  }

  Future<void> play({required bool accent}) async {
    await _ready;
    final AudioPlayer player = accent ? _accentPlayer : _tickPlayer;
    final String path = accent ? _accentPath : _tickPath;
    try {
      await player.play(DeviceFileSource(path));
    } on Object {
      // Ignore transient playback errors so the metronome keeps ticking.
    }
  }

  Future<void> dispose() async {
    await _accentPlayer.dispose();
    await _tickPlayer.dispose();
  }
}
