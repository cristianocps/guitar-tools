import 'dart:async';
import 'dart:math' show ln2, log, pi;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/audio/permission_provider.dart';
import '../../core/audio/pitch_detector.dart';
import '../../core/audio/providers.dart';
import '../../core/design_system/app_background.dart';
import '../../core/design_system/widgets.dart';
import '../../core/music_theory/note.dart';
import '../../core/music_theory/pitch.dart';
import '../../core/music_theory/tuning.dart';
import '../../core/settings/settings_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'string_visualizer_painter.dart';
import 'tuner_gauge_painter.dart';

enum TunerMode { chromatic, string }

class TunerView {
  const TunerView({
    this.noteName = '—',
    this.octave = '',
    this.cents = 0,
    this.state = TuningState.inTune,
    this.activeStringIndex,
    this.intensity = 0,
    this.hasPitch = false,
  });

  final String noteName;
  final String octave;
  final double cents;
  final TuningState state;
  final int? activeStringIndex;
  final double intensity;
  final bool hasPitch;

  static const TunerView empty = TunerView();
}

class TunerScreen extends ConsumerStatefulWidget {
  const TunerScreen({super.key});

  @override
  ConsumerState<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends ConsumerState<TunerScreen>
    with TickerProviderStateMixin {
  TunerMode _mode = TunerMode.chromatic;
  int _selectedString = 0;
  PitchEvent? _lastEvent;
  final ValueNotifier<TunerView> _view =
      ValueNotifier<TunerView>(TunerView.empty);
  late final AnimationController _pulse;

  // Continuous clock that drives the string vibration. Its period is the
  // visual oscillation of the fundamental; higher strings get a shorter period
  // so they shimmer faster, mirroring real pitch.
  late final AnimationController _stringClock;
  Duration _clockPeriod = const Duration(milliseconds: 150);

  // Keep the last detected note on screen for a moment after the sound fades,
  // so the player has time to read the note and how far off it is.
  Timer? _holdTimer;
  static const Duration _holdDuration = Duration(milliseconds: 1800);

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _stringClock = AnimationController(vsync: this, duration: _clockPeriod)
      ..repeat();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _pulse.dispose();
    _stringClock.dispose();
    _view.dispose();
    super.dispose();
  }

  /// Sets the string-vibration speed from the active string's position: higher
  /// strings vibrate faster. Only re-arms the clock when the speed changes, so
  /// a sustained note keeps a smooth, continuous oscillation.
  void _syncStringClock(int? index) {
    if (index == null) {
      return;
    }
    final int n = ref.read(selectedTuningProvider).tuning.strings.length;
    final double rel = n > 1 ? index / (n - 1) : 0.5;
    final Duration period =
        Duration(milliseconds: (170 - 80 * rel).round());
    if (period != _clockPeriod) {
      _clockPeriod = period;
      _stringClock.repeat(period: period);
    }
  }

  void _publish(TunerView view) {
    _view.value = view;
    _syncStringClock(view.activeStringIndex);
  }

  TunerView _compute(PitchEvent? event) {
    if (event == null || !event.hasPitch) {
      return TunerView.empty;
    }
    final double a4 = ref.read(a4ReferenceProvider);
    final Notation notation = ref.read(notationProvider);
    final List<GuitarString> strings =
        ref.read(selectedTuningProvider).tuning.strings;
    final double freq = event.frequency;
    final TuningReading? reading =
        noteFromFrequency(freq, a4Reference: a4);
    if (reading == null) {
      return TunerView.empty;
    }
    final double intensity = event.confidence.clamp(0.0, 1.0);

    if (_mode == TunerMode.chromatic) {
      return TunerView(
        noteName: reading.nearest.name(notation: notation),
        octave: '${reading.nearest.octave}',
        cents: reading.cents,
        state: reading.state,
        activeStringIndex: _matchString(strings, reading.nearest.midi),
        intensity: intensity,
        hasPitch: true,
      );
    }

    // String mode: compare to the selected target string.
    final GuitarString target = strings[_selectedString];
    final double centsToTarget =
        1200 * log(freq / target.frequencyOf(a4)) / ln2;
    final bool inTune = centsToTarget.abs() <= 5;
    return TunerView(
      noteName: target.note.name(notation: notation),
      octave: '${target.note.octave}',
      cents: centsToTarget,
      state: inTune
          ? TuningState.inTune
          : (centsToTarget < 0 ? TuningState.flat : TuningState.sharp),
      activeStringIndex: _selectedString,
      intensity: intensity,
      hasPitch: true,
    );
  }

  /// Highlights the string nearest to the detected note by absolute pitch
  /// (MIDI), so the high and low E are told apart instead of both matching by
  /// pitch class. Returns null when the note is far from every string.
  int? _matchString(List<GuitarString> strings, int detectedMidi) {
    int? best;
    int bestDistance = 1 << 30;
    for (int i = 0; i < strings.length; i++) {
      final int distance = (strings[i].note.midi - detectedMidi).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = i;
      }
    }
    // Only light a string when the note is within ~2 semitones of it.
    return bestDistance <= 2 ? best : null;
  }

  void _onEvent(AsyncValue<PitchEvent> next) {
    next.maybeWhen<void>(
      data: (PitchEvent e) {
        // Ignore "no pitch" frames: the hold timer keeps the last reading
        // visible so it doesn't flash away the instant the string is muted.
        if (!e.hasPitch) {
          return;
        }
        _lastEvent = e;
        _publish(_compute(e));
        _holdTimer?.cancel();
        _holdTimer = Timer(_holdDuration, _clearReading);
      },
      orElse: () {},
    );
  }

  void _clearReading() {
    _lastEvent = null;
    _view.value = TunerView.empty;
  }

  void _selectMode(TunerMode mode) {
    setState(() => _mode = mode);
    _publish(_compute(_lastEvent));
  }

  void _selectString(int index) {
    setState(() => _selectedString = index);
    _publish(_compute(_lastEvent));
  }

  @override
  Widget build(BuildContext context) {
    final PermissionStatus permission = ref.watch(micPermissionProvider);
    final bool granted = permission == PermissionStatus.granted;

    ref.listen<AsyncValue<PitchEvent>>(
      pitchStreamProvider,
      (_, AsyncValue<PitchEvent> next) => _onEvent(next),
    );

    return AppBackground(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
        child: Column(
          children: <Widget>[
            const SizedBox(height: AppSpacing.s),
            AppSegmented<TunerMode>(
              segments: const <ButtonSegment<TunerMode>>[
                ButtonSegment<TunerMode>(
                  value: TunerMode.chromatic,
                  label: Text('Cromático'),
                ),
                ButtonSegment<TunerMode>(
                  value: TunerMode.string,
                  label: Text('Por corda'),
                ),
              ],
              selected: <TunerMode>{_mode},
              onChanged: _selectMode,
            ),
            const SizedBox(height: AppSpacing.l),
            Expanded(
              child: granted
                  ? _buildTuner()
                  : _buildPermissionGate(
                      ref.watch(isMicPermanentlyDeniedProvider),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTuner() {
    final AsyncValue<PitchEvent> pitchAsync = ref.watch(pitchStreamProvider);

    // Surface capture errors instead of failing silently.
    return pitchAsync.when(
      loading: () => _buildTunerBody(listening: false, hint: 'Iniciando microfone…'),
      error: (Object err, _) => _buildTunerBody(
        listening: false,
        hint: 'Erro no microfone: $err',
        isError: true,
      ),
      data: (_) => _buildTunerBody(listening: true, hint: 'Toque uma nota…'),
    );
  }

  Widget _buildTunerBody({
    required bool listening,
    required String hint,
    bool isError = false,
  }) {
    return ValueListenableBuilder<TunerView>(
      valueListenable: _view,
      builder: (BuildContext context, TunerView v, _) {
        return Column(
          children: <Widget>[
            _StringPicker(
              mode: _mode,
              strings: ref.watch(selectedTuningProvider).tuning.strings,
              selectedIndex: _selectedString,
              onSelect: _selectString,
            ),
            const SizedBox(height: AppSpacing.m),
            _TunerGauge(view: v, pulse: _pulse),
            const SizedBox(height: AppSpacing.s),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  listening ? Icons.graphic_eq : Icons.mic_none_rounded,
                  size: 16,
                  color: isError
                      ? AppColors.sharp
                      : (listening ? AppColors.primary : AppColors.textMuted),
                ),
                const SizedBox(width: AppSpacing.s),
                Text(
                  hint,
                  style: AppTypography.caption.copyWith(
                    color: isError ? AppColors.sharp : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            Expanded(
              child: AnimatedBuilder(
                animation: _stringClock,
                builder: (BuildContext context, _) {
                  return CustomPaint(
                    painter: StringVisualizerPainter(
                      activeIndex: v.activeStringIndex,
                      intensity: v.intensity,
                      phase: _stringClock.value * 2 * pi,
                      stringCount: ref
                          .read(selectedTuningProvider)
                          .tuning
                          .strings
                          .length,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPermissionGate(bool permanent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.mic_off_outlined, size: 56, color: AppColors.sharp),
            const SizedBox(height: AppSpacing.m),
            Text(
              'O afinador precisa do microfone',
              style: AppTypography.title,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Usamos o áudio apenas para captar a nota do seu instrumento, em tempo real.',
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.l),
            FilledButton.icon(
              onPressed: permanent
                  ? openAppSettings
                  : () => ref
                      .read(micPermissionProvider.notifier)
                      .request(),
              icon: Icon(permanent ? Icons.settings : Icons.mic),
              label: Text(permanent ? 'Abrir configurações' : 'Permitir microfone'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StringPicker extends StatelessWidget {
  const _StringPicker({
    required this.mode,
    required this.strings,
    required this.selectedIndex,
    required this.onSelect,
  });

  final TunerMode mode;
  final List<GuitarString> strings;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    if (mode != TunerMode.string) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      children: <Widget>[
        for (int i = 0; i < strings.length; i++)
          AppChip(
            label: strings[i].commonName,
            selected: i == selectedIndex,
            onSelected: (_) => onSelect(i),
          ),
      ],
    );
  }
}

/// The headline tuner gauge: an animated arc + needle with the detected note
/// read-out floating in the center.
class _TunerGauge extends StatelessWidget {
  const _TunerGauge({required this.view, required this.pulse});

  final TunerView view;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final bool inTune = view.hasPitch && view.state == TuningState.inTune;
    final Color color = !view.hasPitch
        ? AppColors.textSecondary
        : switch (view.state) {
            TuningState.inTune => AppColors.inTune,
            TuningState.flat => AppColors.flat,
            TuningState.sharp => AppColors.sharp,
          };

    final String centsLabel = view.hasPitch
        ? '${view.cents > 0 ? '+' : ''}${view.cents.round()} cents'
        : 'Toque uma nota';

    return Semantics(
      container: true,
      liveRegion: true,
      label: view.hasPitch
          ? 'Nota ${view.noteName} ${view.octave}, $centsLabel'
          : 'Nenhuma nota detectada',
      child: SizedBox(
        height: 244,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Positioned.fill(
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: pulse,
                  builder: (BuildContext context, _) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: view.cents,
                        end: view.cents,
                      ),
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOut,
                      builder: (BuildContext context, double cents, _) {
                        return CustomPaint(
                          painter: TunerGaugePainter(
                            cents: cents,
                            active: view.hasPitch,
                            inTune: inTune,
                            glow: inTune ? pulse.value : 0,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, -0.34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        view.noteName,
                        style: AppTypography.display.copyWith(
                          color: color,
                          shadows: <Shadow>[
                            Shadow(color: color.withValues(alpha: 0.6), blurRadius: 24),
                          ],
                        ),
                      ),
                      if (view.octave.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 14, left: 2),
                          child: Text(
                            view.octave,
                            style: AppTypography.title.copyWith(color: color),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    centsLabel,
                    style: AppTypography.label.copyWith(
                      color: view.hasPitch ? color : AppColors.textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
