/// A single fingering position for a chord.
class ChordPosition {
  const ChordPosition({
    required this.frets,
    required this.fingers,
    required this.baseFret,
    required this.barres,
    required this.midi,
    this.capo = false,
  });

  /// Fret numbers per string (6 values, low E to high E).
  /// -1 means mute, 0 means open.
  final List<int> frets;

  /// Finger numbers per string (6 values, 0 = no finger).
  final List<int> fingers;

  /// The lowest fret shown in the diagram (1 for open position).
  final int baseFret;

  /// List of fret numbers where a barre is applied.
  final List<int> barres;

  /// Whether the barre should be drawn as a capo.
  final bool capo;

  /// MIDI note numbers produced by this position.
  final List<int> midi;

  /// Pitch classes (0..11) that make up this chord position.
  Set<int> get pitchClasses {
    return midi.map((int note) => note % 12).toSet();
  }

  /// Whether the given string is muted.
  bool isMuted(int stringIndex) => frets[stringIndex] == -1;

  /// Whether the given string is open.
  bool isOpen(int stringIndex) => frets[stringIndex] == 0;
}

/// A chord definition with one or more positions.
class Chord {
  const Chord({
    required this.key,
    required this.suffix,
    required this.positions,
  });

  final String key;
  final String suffix;
  final List<ChordPosition> positions;

  String get displayName => suffix == 'major' ? key : '$key$suffix';

  /// Pitch classes expected for this chord across all positions.
  Set<int> get pitchClasses {
    return positions.isEmpty ? <int>{} : positions.first.pitchClasses;
  }
}
