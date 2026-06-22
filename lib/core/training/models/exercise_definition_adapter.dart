import 'package:hive/hive.dart';

import 'exercise_definition.dart';
import 'exercise_type.dart';

/// Manual Hive adapter for [ExerciseDefinition].
class ExerciseDefinitionAdapter extends TypeAdapter<ExerciseDefinition> {
  @override
  int get typeId => 101;

  @override
  ExerciseDefinition read(BinaryReader reader) {
    return ExerciseDefinition(
      id: reader.readString(),
      type: ExerciseType.values[reader.readByte()],
      level: reader.readInt(),
      title: reader.readString(),
      description: reader.readString(),
      parameters: reader.readMap().cast<String, dynamic>(),
      unlockedByDefault: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseDefinition obj) {
    writer
      ..writeString(obj.id)
      ..writeByte(obj.type.index)
      ..writeInt(obj.level)
      ..writeString(obj.title)
      ..writeString(obj.description)
      ..writeMap(obj.parameters)
      ..writeBool(obj.unlockedByDefault);
  }
}

/// Manual Hive adapter for lists of [ExerciseDefinition].
class ExerciseDefinitionListAdapter extends TypeAdapter<List<ExerciseDefinition>> {
  @override
  int get typeId => 106;

  @override
  List<ExerciseDefinition> read(BinaryReader reader) {
    final int length = reader.readInt();
    return List<ExerciseDefinition>.generate(
      length,
      (_) => ExerciseDefinitionAdapter().read(reader),
    );
  }

  @override
  void write(BinaryWriter writer, List<ExerciseDefinition> obj) {
    final ExerciseDefinitionAdapter adapter = ExerciseDefinitionAdapter();
    writer.writeInt(obj.length);
    for (final ExerciseDefinition item in obj) {
      adapter.write(writer, item);
    }
  }
}
