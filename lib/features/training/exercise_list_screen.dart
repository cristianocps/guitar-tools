import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/training/models/exercise_definition.dart';
import '../../core/training/providers/training_providers.dart';

/// Reusable screen that lists exercise levels with unlock/progress state.
class ExerciseListScreen extends ConsumerWidget {
  const ExerciseListScreen({
    required this.title,
    required this.definitions,
    required this.exerciseBuilder,
    super.key,
  });

  final String title;
  final List<ExerciseDefinition> definitions;
  final Widget Function(ExerciseDefinition) exerciseBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(trainingProgressRepositoryProvider);
    final List<ExerciseDefinition> sorted = List<ExerciseDefinition>.of(definitions)
      ..sort((a, b) => a.level.compareTo(b.level));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        itemCount: sorted.length,
        itemBuilder: (BuildContext context, int index) {
          final ExerciseDefinition definition = sorted[index];
          final bool unlocked = repository.isUnlocked(definition);
          final int stars = repository.bestStarsFor(definition.id);

          return ListTile(
            leading: CircleAvatar(child: Text('${definition.level}')),
            title: Text(definition.title),
            subtitle: Text(definition.description),
            trailing: unlocked
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ...List<Widget>.generate(
                        stars,
                        (_) => const Icon(Icons.star, color: Colors.amber, size: 20),
                      ),
                      ...List<Widget>.generate(
                        3 - stars,
                        (_) => const Icon(Icons.star_border, size: 20),
                      ),
                    ],
                  )
                : const Icon(Icons.lock),
            onTap: unlocked
                ? () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => exerciseBuilder(definition),
                      ),
                    )
                : null,
          );
        },
      ),
    );
  }
}
