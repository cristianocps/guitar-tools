import 'package:hive/hive.dart';

/// A single completed exercise attempt.
@HiveType(typeId: 102)
class ExerciseAttempt extends HiveObject {
  ExerciseAttempt({
    required this.id,
    required this.exerciseId,
    required this.score,
    required this.stars,
    required this.accuracy,
    required this.durationMs,
    required this.timestamp,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String exerciseId;

  @HiveField(2)
  final double score;

  @HiveField(3)
  final int stars;

  @HiveField(4)
  final double accuracy;

  @HiveField(5)
  final int durationMs;

  @HiveField(6)
  final DateTime timestamp;
}
