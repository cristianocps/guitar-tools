import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/harmonic_field/harmonic_field_screen.dart';
import '../features/metronome/metronome_screen.dart';
import '../features/tuner/tuner_screen.dart';
import 'app_providers.dart';

/// Root shell with bottom navigation between the three utilities.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Mic-using features watch this to pause/resume capture (lifecycle).
    ref.read(appResumedProvider.notifier).state =
        state == AppLifecycleState.resumed;
  }

  @override
  Widget build(BuildContext context) {
    final AppTab tab = ref.watch(activeTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: tab.index,
        children: const <Widget>[
          MetronomeScreen(),
          HarmonicFieldScreen(),
          TunerScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (int index) {
          ref.read(activeTabProvider.notifier).state = AppTab.values[index];
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Metrônomo',
          ),
          NavigationDestination(
            icon: Icon(Icons.radio_button_unchecked),
            selectedIcon: Icon(Icons.radio_button_checked),
            label: 'Campo',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Afinador',
          ),
        ],
      ),
    );
  }
}
