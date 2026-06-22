import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/training_progress_repository.dart';

final trainingProgressRepositoryProvider =
    Provider<TrainingProgressRepository>((Ref ref) {
  throw UnimplementedError(
    'Override this provider after opening Hive boxes in main.dart',
  );
});
