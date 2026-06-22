import 'package:hive/hive.dart';

import 'exercise_attempt.dart';

/// Manual Hive adapter for [ExerciseAttempt].
class ExerciseAttemptAdapter extends TypeAdapter<ExerciseAttempt> {
  @override
  int get typeId => 102;

  @override
  ExerciseAttempt read(BinaryReader reader) {
    return ExerciseAttempt(
      id: reader.readString(),
      exerciseId: reader.readString(),
      score: reader.readDouble(),
      stars: reader.readInt(),
      accuracy: reader.readDouble(),
      durationMs: reader.readInt(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseAttempt obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.exerciseId)
      ..writeDouble(obj.score)
      ..writeInt(obj.stars)
      ..writeDouble(obj.accuracy)
      ..writeInt(obj.durationMs)
      ..writeInt(obj.timestamp.millisecondsSinceEpoch);
  }
}

/// Manual Hive adapter for maps of exercise id -> [ExerciseAttempt].
class ExerciseAttemptMapAdapter
    extends TypeAdapter<Map<String, ExerciseAttempt>> {
  @override
  int get typeId => 107;

  @override
  Map<String, ExerciseAttempt> read(BinaryReader reader) {
    final int length = reader.readInt();
    final Map<String, ExerciseAttempt> map = <String, ExerciseAttempt>{};
    final ExerciseAttemptAdapter adapter = ExerciseAttemptAdapter();
    for (int i = 0; i < length; i++) {
      final String key = reader.readString();
      map[key] = adapter.read(reader);
    }
    return map;
  }

  @override
  void write(BinaryWriter writer, Map<String, ExerciseAttempt> obj) {
    final ExerciseAttemptAdapter adapter = ExerciseAttemptAdapter();
    writer.writeInt(obj.length);
    obj.forEach((String key, ExerciseAttempt value) {
      writer.writeString(key);
      adapter.write(writer, value);
    });
  }
}
