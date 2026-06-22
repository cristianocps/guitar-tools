import 'package:hive/hive.dart';

import 'exercise_type.dart';

/// Hive adapter for [ExerciseType].
class ExerciseTypeAdapter extends TypeAdapter<ExerciseType> {
  @override
  int get typeId => 100;

  @override
  ExerciseType read(BinaryReader reader) {
    return ExerciseType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, ExerciseType obj) {
    writer.writeByte(obj.index);
  }
}
