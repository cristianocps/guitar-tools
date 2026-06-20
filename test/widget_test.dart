import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_tools/main.dart';

void main() {
  testWidgets('App boots with the bottom navigation shell', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MusicToolsApp()),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Metrônomo'), findsWidgets);
    expect(find.text('Afinador'), findsOneWidget);
    expect(find.text('Campo'), findsOneWidget);
  });
}
