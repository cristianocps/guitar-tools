import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_shell.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MusicToolsApp()));
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
