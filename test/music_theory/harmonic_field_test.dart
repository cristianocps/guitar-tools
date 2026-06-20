import 'package:flutter_test/flutter_test.dart';
import 'package:music_tools/core/music_theory/harmonic_field.dart';

void main() {
  group('C major harmonic field', () {
    final HarmonicField field = HarmonicField.of(0, ScaleType.major);

    test('produces 7 degrees', () {
      expect(field.degrees, hasLength(7));
    });

    test('matches the expected chords and roman numerals', () {
      final List<String> names =
          field.degrees.map((HarmonicDegree d) => d.chord.name()).toList();
      expect(names, <String>['C', 'Dm', 'Em', 'F', 'G', 'Am', 'B°']);

      final List<String> numerals =
          field.degrees.map((HarmonicDegree d) => d.romanNumeral).toList();
      expect(numerals, <String>['I', 'ii', 'iii', 'IV', 'V', 'vi', 'vii°']);
    });
  });

  group('A minor harmonic field', () {
    final HarmonicField field = HarmonicField.of(9, ScaleType.naturalMinor);

    test('matches the expected chords and roman numerals', () {
      final List<String> names =
          field.degrees.map((HarmonicDegree d) => d.chord.name()).toList();
      expect(names, <String>['Am', 'B°', 'C', 'Dm', 'Em', 'F', 'G']);

      final List<String> numerals =
          field.degrees.map((HarmonicDegree d) => d.romanNumeral).toList();
      expect(numerals, <String>['i', 'ii°', 'III', 'iv', 'v', 'VI', 'VII']);
    });
  });

  group('scales', () {
    test('C major scale pitch classes', () {
      expect(
        scalePitchClasses(0, ScaleType.major),
        <int>[0, 2, 4, 5, 7, 9, 11],
      );
    });

    test('A natural minor scale pitch classes', () {
      expect(
        scalePitchClasses(9, ScaleType.naturalMinor),
        <int>[9, 11, 0, 2, 4, 5, 7],
      );
    });
  });

  group('classifyTriadQuality', () {
    test('major/minor/dim/aug', () {
      expect(
        classifyTriadQuality(third: 4, fifth: 7),
        TriadQuality.major,
      );
      expect(
        classifyTriadQuality(third: 3, fifth: 7),
        TriadQuality.minor,
      );
      expect(
        classifyTriadQuality(third: 3, fifth: 6),
        TriadQuality.diminished,
      );
      expect(
        classifyTriadQuality(third: 4, fifth: 8),
        TriadQuality.augmented,
      );
    });
  });
}
