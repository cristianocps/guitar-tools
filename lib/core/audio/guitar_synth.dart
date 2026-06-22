import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:dart_melty_soundfont/dart_melty_soundfont.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'tone_cache.dart';
import 'tone_generator.dart';

/// Selectable guitar timbres, each backed by a bundled SoundFont (.sf2).
enum GuitarTone {
  acoustic('Violão (acústico)', 'assets/Guitar Acoustic (963KB).sf2'),
  electric('Guitarra (limpa)', 'assets/Electric_guitar.SF2'),
  drive('Guitarra (drive)', 'assets/Power Guitar 1.sf2');

  const GuitarTone(this.label, this.asset);

  /// Human-readable name shown in the UI.
  final String label;

  /// Bundled SoundFont asset path.
  final String asset;
}

/// Renders single notes from the bundled SoundFonts into PCM/WAV using a pure
/// Dart SoundFont synthesizer ([dart_melty_soundfont]).
///
/// Synthesizers are parsed lazily and cached per [GuitarTone]. Rendering a note
/// produces a self-contained WAV buffer, which callers play through the regular
/// audio pipeline (temp `.wav` file + `DeviceFileSource`).
class GuitarSynth {
  GuitarSynth({this.sampleRate = 44100});

  final int sampleRate;
  final Map<GuitarTone, Synthesizer> _synths = <GuitarTone, Synthesizer>{};

  Future<Synthesizer> _synthFor(GuitarTone tone) async {
    final Synthesizer? cached = _synths[tone];
    if (cached != null) {
      return cached;
    }
    final ByteData bytes = await rootBundle.load(tone.asset);
    final Synthesizer synth = Synthesizer.loadByteData(
      bytes,
      SynthesizerSettings(
        sampleRate: sampleRate,
        blockSize: 64,
        maximumPolyphony: 64,
        enableReverbAndChorus: true,
      ),
    );
    // First preset of a guitar SoundFont is the guitar patch.
    synth.selectPreset(channel: 0, preset: 0);
    _synths[tone] = synth;
    return synth;
  }

  /// Renders the MIDI [key] played on [tone] into a mono 16-bit WAV buffer.
  ///
  /// The note is held for most of [duration] (so the string keeps ringing) and
  /// only released near the end, letting the SoundFont's own decay/release tail
  /// sustain naturally instead of being cut short.
  Future<Uint8List> renderNoteWav({
    required int key,
    required GuitarTone tone,
    double duration = 1.6,
    int velocity = 112,
  }) async {
    final Synthesizer synth = await _synthFor(tone);
    synth.reset();

    final int total = (sampleRate * duration).round();
    final int onSamples = (total * 0.92).round().clamp(1, total);
    final ArrayInt16 buf = ArrayInt16.zeros(numShorts: total);

    synth.noteOn(channel: 0, key: key, velocity: velocity);
    synth.renderMonoInt16(buf, offset: 0, length: onSamples);
    synth.noteOff(channel: 0, key: key);
    if (total - onSamples > 0) {
      synth.renderMonoInt16(buf, offset: onSamples, length: total - onSamples);
    }

    final ByteData pcm = buf.bytes;
    final Uint8List pcmBytes =
        pcm.buffer.asUint8List(pcm.offsetInBytes, pcm.lengthInBytes);
    return _wrapWav(pcmBytes, sampleRate);
  }

  static Uint8List _wrapWav(Uint8List pcm, int sampleRate) {
    final int dataSize = pcm.length;
    final Uint8List out = Uint8List(44 + dataSize);
    final ByteData view = ByteData.view(out.buffer);

    void writeString(int offset, String value) {
      for (int i = 0; i < value.length; i++) {
        out[offset + i] = value.codeUnitAt(i);
      }
    }

    writeString(0, 'RIFF');
    view.setUint32(4, 36 + dataSize, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    view.setUint32(16, 16, Endian.little);
    view.setUint16(20, 1, Endian.little); // PCM
    view.setUint16(22, 1, Endian.little); // mono
    view.setUint32(24, sampleRate, Endian.little);
    view.setUint32(28, sampleRate * 2, Endian.little);
    view.setUint16(32, 2, Endian.little);
    view.setUint16(34, 16, Endian.little);
    writeString(36, 'data');
    view.setUint32(40, dataSize, Endian.little);
    out.setRange(44, 44 + dataSize, pcm);
    return out;
  }
}

/// Plays notes for a training exercise using the selected [GuitarTone].
///
/// Falls back to the built-in plucked-string synth ([ToneGenerator]) if the
/// SoundFont cannot be loaded or rendered, so a note always sounds.
class InstrumentPlayer {
  InstrumentPlayer({
    required GuitarSynth synth,
    required this.tone,
    AudioPlayer? player,
  })  : _synth = synth,
        _player = player ?? AudioPlayer();

  /// Extra time kept after a note's nominal length before the mic is trusted
  /// again. It must outlast the pitch pipeline's own latency (YIN window +
  /// median + hold ≈ 460 ms) plus the speaker/room decay tail; otherwise the
  /// note the device just played keeps arriving as late [PitchEvent]s and — for
  /// ear/fretboard drills, where the played note IS the answer — scores as a
  /// false hit.
  static const Duration _gateGuard = Duration(milliseconds: 650);

  final GuitarSynth _synth;
  final AudioPlayer _player;
  final GuitarTone tone;

  DateTime _outputUntil = DateTime.fromMillisecondsSinceEpoch(0);

  /// True while a tone is (about to be) coming out of the speaker.
  ///
  /// Callers should ignore microphone input while this is true, so the device's
  /// own playback is never counted as a note the user played.
  bool get isOutputActive => DateTime.now().isBefore(_outputUntil);

  Future<void> playMidi(int midi, {double duration = 1.6}) async {
    final Duration window =
        Duration(milliseconds: (duration * 1000).round()) + _gateGuard;
    // Reserve the gate immediately so events during render/IO are suppressed.
    _outputUntil = DateTime.now().add(window);

    Uint8List wav;
    try {
      wav = await _synth.renderNoteWav(key: midi, tone: tone, duration: duration);
    } on Object {
      wav = ToneGenerator.buildTone(
        frequency: _midiToFrequency(midi),
        sampleRate: _synth.sampleRate,
        duration: duration,
      );
    }
    final String path = await writeTempWav(wav);
    try {
      await _player.play(DeviceFileSource(path));
      // Reserve the gate from the moment playback actually starts. `play()`
      // only resolves once the (possibly slow, e.g. iOS AVPlayer) source has
      // begun, so anchoring here keeps the whole note + tail inside the window
      // instead of letting it expire mid-note because of startup latency.
      _outputUntil = DateTime.now().add(window);
    } on Object {
      // Ignore transient playback errors.
    }
  }

  static double _midiToFrequency(int midi) =>
      440 * math.pow(2, (midi - 69) / 12).toDouble();

  Future<void> dispose() => _player.dispose();
}
