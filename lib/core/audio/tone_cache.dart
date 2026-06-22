import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

int _counter = 0;

/// Writes [wav] bytes to a uniquely-named temporary `.wav` file and returns its
/// path.
///
/// audioplayers' in-memory `BytesSource` is materialized by the iOS backend
/// into a cache file *without an extension*, which `AVPlayerItem` then fails to
/// load ("Failed to set source"). Playing from a real `.wav` file via
/// `DeviceFileSource` lets the platform infer the format reliably (the same
/// approach the metronome's click player already uses).
///
/// Names rotate over a small ring so a freshly-written file never overwrites
/// one that is still being read by a previous, overlapping playback.
Future<String> writeTempWav(Uint8List wav) async {
  final Directory dir = await getTemporaryDirectory();
  final String path = '${dir.path}/tone_${_counter++ % 8}.wav';
  await File(path).writeAsBytes(wav, flush: true);
  return path;
}
