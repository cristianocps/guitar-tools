import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_providers.dart';
import '../../core/design_system/app_background.dart';
import '../../core/metronome_engine/click_player.dart';
import '../../core/metronome_engine/metronome_engine.dart';
import '../../core/metronome_engine/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'metronome_painter.dart';

class MetronomeScreen extends ConsumerStatefulWidget {
  const MetronomeScreen({super.key});

  @override
  ConsumerState<MetronomeScreen> createState() => _MetronomeScreenState();
}

class _MetronomeScreenState extends ConsumerState<MetronomeScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  MetronomeEngine? _engine;

  final ValueNotifier<double> _phase = ValueNotifier<double>(0);
  final ValueNotifier<int> _beat = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _phase.dispose();
    _beat.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    _engine?.processFrame(elapsed);
    if (_engine != null) {
      _phase.value = _engine!.phase;
      if (_engine!.currentBeat != _beat.value) {
        _beat.value = _engine!.currentBeat;
      }
    }
  }

  void _startEngine(int bpm, int beatsPerBar) {
    final ClickPlayer click = ref.read(clickPlayerProvider);
    _engine = MetronomeEngine(
      onBeat: (int beatNumber, bool accent) {
        unawaited(click.play(accent: accent));
        _beat.value = beatNumber;
      },
      bpm: bpm,
      beatsPerBar: beatsPerBar,
    );
    _beat.value = 0;
    _phase.value = 0;
    _engine!.start(now: Duration.zero);
    _ticker.start();
  }

  void _stopEngine() {
    _ticker.stop();
    _engine?.stop();
    _engine = null;
    _phase.value = 0;
    _beat.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final MetronomeSettings settings = ref.watch(metronomeSettingsProvider);

    ref.listen<MetronomeSettings>(metronomeSettingsProvider,
        (MetronomeSettings? prev, MetronomeSettings next) {
      if (prev == null) {
        return;
      }
      final bool resumed = ref.read(appResumedProvider);
      if (!resumed) {
        return;
      }
      if (prev.isPlaying != next.isPlaying) {
        if (next.isPlaying) {
          _startEngine(next.bpm, next.beatsPerBar);
        } else {
          _stopEngine();
        }
      } else if (next.isPlaying &&
          (prev.bpm != next.bpm || prev.beatsPerBar != next.beatsPerBar)) {
        _startEngine(next.bpm, next.beatsPerBar);
      }
    });

    // Pause/resume with the app lifecycle.
    ref.listen<bool>(appResumedProvider, (bool? prev, bool resumed) {
      final MetronomeSettings s = ref.read(metronomeSettingsProvider);
      if (resumed) {
        if (s.isPlaying && _engine == null) {
          _startEngine(s.bpm, s.beatsPerBar);
        }
      } else {
        _stopEngine();
      }
    });

    return AppBackground(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
        child: Column(
          children: <Widget>[
            Text('Metrônomo', style: AppTypography.headline),
            const SizedBox(height: AppSpacing.l),
            Expanded(
              child: CustomPaint(
                painter: PendulumPainter(
                  phaseNotifier: _phase,
                  beatNotifier: _beat,
                  beatsPerBar: settings.beatsPerBar,
                ),
                repaint: Listenable.merge(<Listenable>[_phase, _beat]),
                child: const SizedBox.expand(),
              ),
            ),
              _BpmControl(
                bpm: settings.bpm,
                onChanged: (int v) => ref
                    .read(metronomeSettingsProvider.notifier)
                    .setBpm(v),
              ),
              const SizedBox(height: AppSpacing.m),
              _TimeSignatureSelector(
                beatsPerBar: settings.beatsPerBar,
                onChanged: (int v) => ref
                    .read(metronomeSettingsProvider.notifier)
                    .setBeatsPerBar(v),
              ),
              const SizedBox(height: AppSpacing.l),
              _PlayButton(
                isPlaying: settings.isPlaying,
                onTap: () => ref
                    .read(metronomeSettingsProvider.notifier)
                    .togglePlay(),
              ),
              const SizedBox(height: AppSpacing.m),
            ],
          ),
        ),
    );
  }
}

class _BpmControl extends StatelessWidget {
  const _BpmControl({required this.bpm, required this.onChanged});

  final int bpm;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            IconButton.filled(
              onPressed: () => onChanged(bpm - 1),
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: AppSpacing.l),
            Text('$bpm', style: AppTypography.display),
            const SizedBox(width: AppSpacing.s),
            Text('BPM', style: AppTypography.body),
            const SizedBox(width: AppSpacing.l),
            IconButton.filled(
              onPressed: () => onChanged(bpm + 1),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        Slider(
          value: bpm.toDouble(),
          min: 20,
          max: 280,
          divisions: 260,
          activeColor: AppColors.primary,
          onChanged: (double v) => onChanged(v.round()),
        ),
      ],
    );
  }
}

class _TimeSignatureSelector extends StatelessWidget {
  const _TimeSignatureSelector({
    required this.beatsPerBar,
    required this.onChanged,
  });

  final int beatsPerBar;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s,
      children: availableBeatsPerBar.map((int bpb) {
        final bool selected = bpb == beatsPerBar;
        return ChoiceChip(
          label: Text('$bpb/4'),
          selected: selected,
          selectedColor: AppColors.primary,
          onSelected: (_) => onChanged(bpb),
        );
      }).toList(),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.isPlaying, required this.onTap});

  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.m,
        ),
        decoration: BoxDecoration(
          color: isPlaying ? AppColors.sharp : AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
              size: 32,
              color: AppColors.background,
            ),
            const SizedBox(width: AppSpacing.s),
            Text(
              isPlaying ? 'Parar' : 'Iniciar',
              style: AppTypography.title.copyWith(color: AppColors.background),
            ),
          ],
        ),
      ),
    );
  }
}
