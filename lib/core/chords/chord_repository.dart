import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chord_models.dart';
import 'chords_db_parser.dart';

/// Provides the parsed chord database once loaded.
final chordDatabaseProvider = FutureProvider<List<Chord>>((Ref ref) async {
  final ChordsDbParser parser = ChordsDbParser();
  return parser.load();
});

/// Repository for querying chords.
class ChordRepository {
  const ChordRepository(this._chords);

  final List<Chord> _chords;

  /// Returns the chord matching [key] and [suffix], or null if not found.
  Chord? find(String key, String suffix) {
    for (final Chord chord in _chords) {
      if (chord.key == key && chord.suffix == suffix) {
        return chord;
      }
    }
    return null;
  }

  /// Returns all chords whose suffix is in [suffixes].
  List<Chord> findBySuffixes(List<String> suffixes) {
    return _chords
        .where((Chord chord) => suffixes.contains(chord.suffix))
        .toList(growable: false);
  }

  /// Returns chords for a specific level of difficulty.
  List<Chord> forLevel(int level) {
    final List<String> suffixes = _suffixesForLevel(level);
    return findBySuffixes(suffixes);
  }

  static List<String> _suffixesForLevel(int level) {
    switch (level) {
      case 1:
        return <String>['major', 'minor'];
      case 2:
        return <String>['major', 'minor', '7', 'm7'];
      case 3:
        return <String>['major', 'minor', '7', 'm7', 'maj7', 'sus2', 'sus4'];
      case 4:
        return <String>[
          'major',
          'minor',
          '7',
          'm7',
          'maj7',
          'sus2',
          'sus4',
          'dim',
          'aug',
        ];
      default:
        return <String>[
          'major',
          'minor',
          '7',
          'm7',
          'maj7',
          'sus2',
          'sus4',
          'dim',
          'aug',
          'add9',
          'm7b5',
          '9',
        ];
    }
  }
}

/// Repository provider that depends on the loaded chord database.
final chordRepositoryProvider = Provider<AsyncValue<ChordRepository>>((Ref ref) {
  final AsyncValue<List<Chord>> asyncChords = ref.watch(chordDatabaseProvider);
  return asyncChords.whenData((List<Chord> chords) => ChordRepository(chords));
});
