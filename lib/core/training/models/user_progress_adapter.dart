import 'package:hive/hive.dart';

import 'user_progress.dart';

/// Manual Hive adapter for [ExerciseProgress].
class ExerciseProgressAdapter extends TypeAdapter<ExerciseProgress> {
  @override
  int get typeId => 103;

  @override
  ExerciseProgress read(BinaryReader reader) {
    return ExerciseProgress(
      exerciseId: reader.readString(),
      bestStars: reader.readInt(),
      unlocked: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseProgress obj) {
    writer
      ..writeString(obj.exerciseId)
      ..writeInt(obj.bestStars)
      ..writeBool(obj.unlocked);
  }
}

/// Manual Hive adapter for [UserProgress].
class UserProgressAdapter extends TypeAdapter<UserProgress> {
  @override
  int get typeId => 104;

  @override
  UserProgress read(BinaryReader reader) {
    final int length = reader.readInt();
    final List<ExerciseProgress> progress = List<ExerciseProgress>.generate(
      length,
      (_) => ExerciseProgressAdapter().read(reader),
    );
    return UserProgress(exerciseProgress: progress);
  }

  @override
  void write(BinaryWriter writer, UserProgress obj) {
    final ExerciseProgressAdapter adapter = ExerciseProgressAdapter();
    writer.writeInt(obj.exerciseProgress.length);
    for (final ExerciseProgress item in obj.exerciseProgress) {
      adapter.write(writer, item);
    }
  }
}
