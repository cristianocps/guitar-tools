import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_shell.dart';
import 'core/settings/settings_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/training/models/exercise_attempt.dart';
import 'core/training/models/exercise_attempt_adapter.dart';
import 'core/training/models/exercise_definition_adapter.dart';
import 'core/training/models/exercise_type_adapter.dart';
import 'core/training/models/user_progress.dart';
import 'core/training/models/user_progress_adapter.dart';
import 'core/training/providers/training_providers.dart';
import 'core/training/repositories/training_progress_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive
    ..registerAdapter(ExerciseDefinitionAdapter())
    ..registerAdapter(ExerciseAttemptAdapter())
    ..registerAdapter(UserProgressAdapter())
    ..registerAdapter(ExerciseTypeAdapter());

  final Box<UserProgress> progressBox =
      await Hive.openBox<UserProgress>('training_progress');
  final Box<ExerciseAttempt> attemptsBox =
      await Hive.openBox<ExerciseAttempt>('exercise_attempts');
  final TrainingProgressRepository trainingRepository =
      TrainingProgressRepository(
    progressBox: progressBox,
    attemptsBox: attemptsBox,
  );

  // Boot persistent settings before the first frame so providers can read
  // preferences synchronously after runApp.
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        trainingProgressRepositoryProvider
            .overrideWithValue(trainingRepository),
      ],
      child: const MusicToolsApp(),
    ),
  );
}

class MusicToolsApp extends StatelessWidget {
  const MusicToolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Tools',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const AppShell(),
    );
  }
}
