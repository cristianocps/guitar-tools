import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_tools/core/settings/settings_providers.dart';
import 'package:music_tools/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('App boots with the bottom navigation shell', (tester) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MusicToolsApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Metrônomo'), findsWidgets);
    expect(find.text('Afinador'), findsOneWidget);
    expect(find.text('Campo'), findsOneWidget);
  });

  testWidgets('Settings entry is reachable from the app bar', (tester) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MusicToolsApp(),
      ),
    );
    await tester.pump();

    expect(find.byTooltip('Ajustes'), findsOneWidget);
  });
}
