import 'note.dart';

/// A string of a guitar in a given tuning.
class GuitarString {
  const GuitarString({
    required this.number,
    required this.note,
    required this.commonName,
  });

  /// 1 = high E ... 6 = low E (standard numbering).
  final int number;

  final Note note;

  /// Short label, e.g. "6E" (low E), "1E" (high E).
  final String commonName;

  double get frequency => note.frequency;

  @override
  String toString() => '$commonName (${note.fullName()})';
}

/// Standard tuning, ordered low → high (string 6 down to string 1).
const List<GuitarString> standardTuning = <GuitarString>[
  GuitarString(number: 6, note: Note(4, 2), commonName: '6E'),
  GuitarString(number: 5, note: Note(9, 2), commonName: '5A'),
  GuitarString(number: 4, note: Note(2, 3), commonName: '4D'),
  GuitarString(number: 3, note: Note(7, 3), commonName: '3G'),
  GuitarString(number: 2, note: Note(11, 3), commonName: '2B'),
  GuitarString(number: 1, note: Note(4, 4), commonName: '1E'),
];
