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

  /// Renders several MIDI [keys] sounding together as a chord into a mono
  /// 16-bit WAV buffer.
  ///
  /// Note onsets are staggered by [strumMs] so the strings enter like a strum
  /// while still ringing simultaneously (a true chord), rather than as fully
  /// separate, gapped notes. Pass `strumMs: 0` for a perfectly blocked chord.
  Future<Uint8List> renderChordWav({
    required List<int> keys,
    required GuitarTone tone,
    double duration = 1.6,
    int velocity = 112,
    double strumMs = 22,
  }) async {
    final Synthesizer synth = await _synthFor(tone);
    synth.reset();

    // Summing several voices into one mono buffer easily overflows the int16
    // range and clips (harsh distortion). Render at a low master volume so the
    // mix stays within headroom, then normalize the result back up to a clean,
    // loud peak below full scale.
    final double previousVolume = synth.masterVolume;
    synth.masterVolume =
        (0.6 / (keys.isEmpty ? 1 : keys.length)).clamp(0.08, 0.5);

    final int total = (sampleRate * duration).round();
    final int onSamples = (total * 0.92).round().clamp(1, total);
    final ArrayInt16 buf = ArrayInt16.zeros(numShorts: total);

    final int strumSamples = (sampleRate * strumMs / 1000).round();
    int rendered = 0;
    for (int i = 0; i < keys.length; i++) {
      final int onsetAt = (i * strumSamples).clamp(0, onSamples - 1);
      if (onsetAt > rendered) {
        synth.renderMonoInt16(buf, offset: rendered, length: onsetAt - rendered);
        rendered = onsetAt;
      }
      synth.noteOn(channel: 0, key: keys[i], velocity: velocity);
    }
    if (onSamples > rendered) {
      synth.renderMonoInt16(buf, offset: rendered, length: onSamples - rendered);
    }
    for (final int key in keys) {
      synth.noteOff(channel: 0, key: key);
    }
    if (total - onSamples > 0) {
      synth.renderMonoInt16(buf, offset: onSamples, length: total - onSamples);
    }
    synth.masterVolume = previousVolume;

    final ByteData pcm = buf.bytes;
    final Uint8List pcmBytes =
        pcm.buffer.asUint8List(pcm.offsetInBytes, pcm.lengthInBytes);
    _normalizeInt16(pcmBytes);
    return _wrapWav(pcmBytes, sampleRate);
  }

  /// Scales 16-bit PCM samples so the loudest peak sits at ~0.9 full scale,
  /// keeping chords loud without clipping. Gain is capped so near-silent
  /// buffers aren't blown up into noise.
  static void _normalizeInt16(Uint8List pcm) {
    final ByteData view = ByteData.view(
      pcm.buffer,
      pcm.offsetInBytes,
      pcm.lengthInBytes,
    );
    final int sampleCount = pcm.lengthInBytes ~/ 2;
    int peak = 1;
    for (int i = 0; i < sampleCount; i++) {
      final int v = view.getInt16(i * 2, Endian.little).abs();
      if (v > peak) {
        peak = v;
      }
    }
    const int target = 29490; // ~0.9 * 32767
    final double gain = (target / peak).clamp(1.0, 8.0);
    if (gain <= 1.0) {
      return;
    }
    for (int i = 0; i < sampleCount; i++) {
      final int scaled =
          (view.getInt16(i * 2, Endian.little) * gain).round();
      view.setInt16(
        i * 2,
        scaled.clamp(-32768, 32767),
        Endian.little,
      );
    }
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

  /// Plays several MIDI notes together as a chord (one render, all strings
  /// ringing simultaneously) instead of as separate sequential notes.
  ///
  /// [strumMs] staggers the string onsets to emulate a strum; pass `0` for a
  /// perfectly simultaneous (unison) chord.
  Future<void> playChord(
    List<int> midis, {
    double duration = 1.6,
    double strumMs = 22,
  }) async {
    if (midis.isEmpty) {
      return;
    }
    final Duration window =
        Duration(milliseconds: (duration * 1000).round()) + _gateGuard;
    _outputUntil = DateTime.now().add(window);

    Uint8List wav;
    try {
      wav = await _synth.renderChordWav(
        keys: midis,
        tone: tone,
        duration: duration,
        strumMs: strumMs,
      );
    } on Object {
      wav = _mixTones(midis, duration);
    }
    final String path = await writeTempWav(wav);
    try {
      await _player.play(DeviceFileSource(path));
      _outputUntil = DateTime.now().add(window);
    } on Object {
      // Ignore transient playback errors.
    }
  }

  /// Fallback chord: mixes the per-note plucked-string tones into one buffer so
  /// every string is heard at once even when the SoundFont is unavailable.
  Uint8List _mixTones(List<int> midis, double duration) {
    final int sampleRate = _synth.sampleRate;
    final int frames = (sampleRate * duration).round();
    final Float64List mix = Float64List(frames);
    for (final int midi in midis) {
      final Uint8List tone = ToneGenerator.buildTone(
        frequency: _midiToFrequency(midi),
        sampleRate: sampleRate,
        duration: duration,
      );
      final ByteData view = ByteData.view(tone.buffer);
      final int toneFrames = (tone.lengthInBytes - 44) ~/ 2;
      final int count = math.min(frames, toneFrames);
      for (int i = 0; i < count; i++) {
        mix[i] += view.getInt16(44 + i * 2, Endian.little) / 32768.0;
      }
    }

    final double scale = midis.isEmpty ? 1 : 1 / midis.length;
    final int dataSize = frames * 2;
    final Uint8List out = Uint8List(44 + dataSize);
    final ByteData outView = ByteData.view(out.buffer);
    void writeString(int offset, String value) {
      for (int i = 0; i < value.length; i++) {
        out[offset + i] = value.codeUnitAt(i);
      }
    }

    writeString(0, 'RIFF');
    outView.setUint32(4, 36 + dataSize, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    outView.setUint32(16, 16, Endian.little);
    outView.setUint16(20, 1, Endian.little);
    outView.setUint16(22, 1, Endian.little);
    outView.setUint32(24, sampleRate, Endian.little);
    outView.setUint32(28, sampleRate * 2, Endian.little);
    outView.setUint16(32, 2, Endian.little);
    outView.setUint16(34, 16, Endian.little);
    writeString(36, 'data');
    outView.setUint32(40, dataSize, Endian.little);
    for (int i = 0; i < frames; i++) {
      final double s = (mix[i] * scale).clamp(-1.0, 1.0);
      outView.setInt16(44 + i * 2, (s * 32767).round(), Endian.little);
    }
    return out;
  }

  String? _preparedChordPath;
  double _preparedChordDuration = 1.6;

  /// Renders [midis] into a chord WAV once and keeps it ready for fast,
  /// timing-accurate replays via [triggerChord]. Use this for looped playback
  /// so each repeat doesn't pay the (variable) synthesis + file-IO cost, which
  /// would otherwise smear the loop's tempo.
  Future<void> prepareChord(
    List<int> midis, {
    double duration = 1.6,
    double strumMs = 0,
  }) async {
    if (midis.isEmpty) {
      return;
    }
    Uint8List wav;
    try {
      wav = await _synth.renderChordWav(
        keys: midis,
        tone: tone,
        duration: duration,
        strumMs: strumMs,
      );
    } on Object {
      wav = _mixTones(midis, duration);
    }
    _preparedChordPath = await writeTempWav(wav);
    _preparedChordDuration = duration;
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setPlayerMode(PlayerMode.lowLatency);
      await _player.setSource(DeviceFileSource(_preparedChordPath!));
    } on Object {
      // Ignore prepare errors; triggerChord will no-op without a source.
    }
  }

  /// Replays the chord prepared by [prepareChord]. Cheap enough to fire on a
  /// metronome tick. [accent] plays the downbeat louder than the other beats.
  Future<void> triggerChord({bool accent = true}) async {
    final String? path = _preparedChordPath;
    if (path == null) {
      return;
    }
    final Duration window =
        Duration(milliseconds: (_preparedChordDuration * 1000).round()) +
            _gateGuard;
    _outputUntil = DateTime.now().add(window);
    try {
      await _player.setVolume(accent ? 1.0 : 0.72);
      await _player.play(DeviceFileSource(path));
      _outputUntil = DateTime.now().add(window);
    } on Object {
      // Ignore transient playback errors so the loop keeps going.
    }
  }

  static double _midiToFrequency(int midi) =>
      440 * math.pow(2, (midi - 69) / 12).toDouble();

  Future<void> dispose() => _player.dispose();
}
