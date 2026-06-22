import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/exercise_attempt.dart';
import '../models/exercise_definition.dart';
import '../models/user_progress.dart';
import '../star_rating.dart';

/// Repository for training progress persistence.
class TrainingProgressRepository {
  TrainingProgressRepository({
    required Box<UserProgress> progressBox,
    required Box<ExerciseAttempt> attemptsBox,
    Uuid uuid = const Uuid(),
  })  : _progressBox = progressBox,
        _attemptsBox = attemptsBox,
        _uuid = uuid;

  static const String _progressKey = 'user_progress';

  final Box<UserProgress> _progressBox;
  final Box<ExerciseAttempt> _attemptsBox;
  final Uuid _uuid;

  UserProgress _loadOrCreate() {
    return _progressBox.get(_progressKey) ??
        UserProgress(exerciseProgress: <ExerciseProgress>[]);
  }

  Future<void> _save(UserProgress progress) async {
    await _progressBox.put(_progressKey, progress);
  }

  /// Returns the stored progress, creating an empty one if needed.
  UserProgress loadProgress() => _loadOrCreate();

  /// Marks an exercise as unlocked.
  Future<void> unlockExercise(String exerciseId) async {
    final UserProgress progress = _loadOrCreate();
    final ExerciseProgress? existing = progress.exerciseProgress
        .cast<ExerciseProgress?>()
        .firstWhere(
          (ExerciseProgress? p) => p?.exerciseId == exerciseId,
          orElse: () => null,
        );
    if (existing != null) {
      existing.unlocked = true;
    } else {
      progress.exerciseProgress.add(
        ExerciseProgress(exerciseId: exerciseId, unlocked: true),
      );
    }
    await _save(progress);
  }

  /// Records an attempt and updates best stars/unlock status.
  Future<void> saveAttempt({
    required String exerciseId,
    required double accuracy,
    required int durationMs,
  }) async {
    final int stars = StarRating.fromAccuracy(accuracy);
    final ExerciseAttempt attempt = ExerciseAttempt(
      id: _uuid.v4(),
      exerciseId: exerciseId,
      score: accuracy,
      stars: stars,
      accuracy: accuracy,
      durationMs: durationMs,
      timestamp: DateTime.now(),
    );
    await _attemptsBox.put(attempt.id, attempt);

    final UserProgress progress = _loadOrCreate();
    final ExerciseProgress? existing = progress.exerciseProgress
        .cast<ExerciseProgress?>()
        .firstWhere(
          (ExerciseProgress? p) => p?.exerciseId == exerciseId,
          orElse: () => null,
        );
    if (existing != null) {
      if (stars > existing.bestStars) {
        existing.bestStars = stars;
      }
      existing.unlocked = true;
    } else {
      progress.exerciseProgress.add(
        ExerciseProgress(
          exerciseId: exerciseId,
          bestStars: stars,
          unlocked: true,
        ),
      );
    }
    await _save(progress);
  }

  /// Whether an exercise is unlocked, either by default or by progress.
  bool isUnlocked(ExerciseDefinition definition) {
    if (definition.unlockedByDefault) {
      return true;
    }
    final UserProgress progress = _loadOrCreate();
    final ExerciseProgress? existing = progress.exerciseProgress
        .cast<ExerciseProgress?>()
        .firstWhere(
          (ExerciseProgress? p) => p?.exerciseId == definition.id,
          orElse: () => null,
        );
    return existing?.unlocked ?? false;
  }

  /// Best stars obtained for an exercise, or 0.
  int bestStarsFor(String exerciseId) {
    final UserProgress progress = _loadOrCreate();
    final ExerciseProgress? existing = progress.exerciseProgress
        .cast<ExerciseProgress?>()
        .firstWhere(
          (ExerciseProgress? p) => p?.exerciseId == exerciseId,
          orElse: () => null,
        );
    return existing?.bestStars ?? 0;
  }

  /// Unlocks the next level of the same exercise type if it exists.
  Future<void> unlockNextLevel(
    ExerciseDefinition current,
    List<ExerciseDefinition> allDefinitions,
  ) async {
    final ExerciseDefinition? next = allDefinitions
        .where(
          (ExerciseDefinition d) =>
              d.type == current.type && d.level == current.level + 1,
        )
        .firstOrNull;
    if (next != null) {
      await unlockExercise(next.id);
    }
  }
}
