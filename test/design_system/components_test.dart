import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_tools/core/design_system/widgets.dart';

void main() {
  group('GlassCard', () {
    testWidgets('renders a BackdropFilter with blur', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(
              child: Text('glass content'),
            ),
          ),
        ),
      );

      expect(find.text('glass content'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
      final BackdropFilter filter = tester.widget(find.byType(BackdropFilter));
      expect(filter.filter, isA<ImageFilter>());
    });

    testWidgets('strong variant uses stronger surface color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(
              strong: true,
              child: SizedBox.shrink(),
            ),
          ),
        ),
      );

      expect(find.byType(GlassCard), findsOneWidget);
    });
  });

  group('AppSegmented', () {
    testWidgets('invokes onChanged when a segment is selected', (tester) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSegmented<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(value: 'a', label: Text('A')),
                ButtonSegment<String>(value: 'b', label: Text('B')),
              ],
              selected: const <String>{'a'},
              onChanged: (String value) => selected = value,
            ),
          ),
        ),
      );

      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();

      expect(selected, 'b');
    });
  });

  group('AppChip', () {
    testWidgets('reflects selected state and toggles on tap', (tester) async {
      bool selected = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MaterialApp(
              home: Scaffold(
                body: AppChip(
                  label: 'chip',
                  selected: selected,
                  onSelected: (bool value) => setState(() => selected = value),
                ),
              ),
            );
          },
        ),
      );

      final ChoiceChip chip = tester.widget(find.byType(ChoiceChip));
      expect(chip.selected, false);

      await tester.tap(find.text('chip'));
      await tester.pumpAndSettle();

      expect(selected, true);
    });
  });

  group('AnimatedTabSwitcher', () {
    testWidgets('keeps an IndexedStack and reacts to index changes',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Scaffold(
                body: AnimatedTabSwitcher(
                  index: 0,
                  children: <Widget>[
                    const Text('first'),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('second'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.byType(IndexedStack), findsOneWidget);
      expect(find.text('first'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: AnimatedTabSwitcher(
            index: 1,
            children: <Widget>[
              Text('first'),
              Text('second'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('second'), findsOneWidget);
    });
  });
}
