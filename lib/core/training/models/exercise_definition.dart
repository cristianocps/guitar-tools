import 'package:hive/hive.dart';

import 'exercise_type.dart';

/// Metadata for a single training exercise level.
@HiveType(typeId: 101)
class ExerciseDefinition extends HiveObject {
  ExerciseDefinition({
    required this.id,
    required this.type,
    required this.level,
    required this.title,
    required this.description,
    required this.parameters,
    this.unlockedByDefault = false,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final ExerciseType type;

  @HiveField(2)
  final int level;

  @HiveField(3)
  final String title;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final Map<String, dynamic> parameters;

  @HiveField(6)
  final bool unlockedByDefault;
}
