import 'dart:convert';

import 'package:flutter/services.dart';

import 'chord_models.dart';

/// Parses the chords-db guitar JSON asset into domain models.
class ChordsDbParser {
  Future<List<Chord>> load() async {
    final String raw = await rootBundle.loadString('assets/chords/guitar.json');
    final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
    final Map<String, dynamic> chordsMap = json['chords'] as Map<String, dynamic>;

    return chordsMap.entries.expand(
      (MapEntry<String, dynamic> entry) {
        final List<dynamic> chordList = entry.value as List<dynamic>;
        return chordList.map(_parseChord);
      },
    ).toList(growable: false);
  }

  Chord _parseChord(dynamic raw) {
    final Map<String, dynamic> map = raw as Map<String, dynamic>;
    final String key = map['key'] as String;
    final String suffix = map['suffix'] as String;
    final List<dynamic> positions = map['positions'] as List<dynamic>;

    return Chord(
      key: key,
      suffix: suffix,
      positions: positions
          .map((dynamic p) => _parsePosition(p as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  ChordPosition _parsePosition(Map<String, dynamic> map) {
    return ChordPosition(
      frets: (map['frets'] as List<dynamic>).cast<int>(),
      fingers: (map['fingers'] as List<dynamic>).cast<int>(),
      baseFret: map['baseFret'] as int,
      barres: (map['barres'] as List<dynamic>?)?.cast<int>() ?? <int>[],
      capo: map['capo'] as bool? ?? false,
      midi: (map['midi'] as List<dynamic>).cast<int>(),
    );
  }
}
