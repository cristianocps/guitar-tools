import 'package:hive/hive.dart';

/// Best result and unlock status for an exercise.
@HiveType(typeId: 103)
class ExerciseProgress extends HiveObject {
  ExerciseProgress({
    required this.exerciseId,
    this.bestStars = 0,
    this.unlocked = false,
  });

  @HiveField(0)
  final String exerciseId;

  @HiveField(1)
  int bestStars;

  @HiveField(2)
  bool unlocked;
}

/// Aggregate user progress across all exercises.
@HiveType(typeId: 104)
class UserProgress extends HiveObject {
  UserProgress({
    required this.exerciseProgress,
  });

  @HiveField(0)
  final List<ExerciseProgress> exerciseProgress;
}
