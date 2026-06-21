import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design_system/widgets.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_glass.dart';
import '../features/harmonic_field/harmonic_field_screen.dart';
import '../features/metronome/metronome_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/tuner/tuner_screen.dart';
import 'app_providers.dart';

/// Root shell with bottom navigation between the three utilities.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            tooltip: 'Ajustes',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const SettingsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedTabSwitcher(
        index: tab.index,
        children: const <Widget>[
          MetronomeScreen(),
          HarmonicFieldScreen(),
          TunerScreen(),
        ],
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppGlass.blurSigma,
            sigmaY: AppGlass.blurSigma,
          ),
          child: NavigationBar(
            backgroundColor: AppColors.glassSurface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            selectedIndex: tab.index,
            onDestinationSelected: (int index) =>
                ref.read(activeTabProvider.notifier).selectIndex(index),
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
        ),
      ),
    );
  }
}
