import 'dart:math' show ln2, log;

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
import 'tuning_meter_painter.dart';

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

class _TunerScreenState extends ConsumerState<TunerScreen> {
  TunerMode _mode = TunerMode.chromatic;
  int _selectedString = 0;
  PitchEvent? _lastEvent;
  final ValueNotifier<TunerView> _view =
      ValueNotifier<TunerView>(TunerView.empty);

  @override
  void dispose() {
    _view.dispose();
    super.dispose();
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
        activeStringIndex: _matchString(strings, reading.nearest.pitchClass),
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

  int? _matchString(List<GuitarString> strings, int pitchClass) {
    for (int i = 0; i < strings.length; i++) {
      if (strings[i].note.pitchClass == pitchClass) {
        return i;
      }
    }
    return null;
  }

  void _onEvent(AsyncValue<PitchEvent> next) {
    _lastEvent = next.maybeWhen<PitchEvent?>(
      data: (PitchEvent e) => e,
      orElse: () => _lastEvent,
    );
    _view.value = _compute(_lastEvent);
  }

  void _selectMode(TunerMode mode) {
    setState(() => _mode = mode);
    _view.value = _compute(_lastEvent);
  }

  void _selectString(int index) {
    setState(() => _selectedString = index);
    _view.value = _compute(_lastEvent);
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
            const SizedBox(height: AppSpacing.l),
            _NoteDisplay(view: v),
            const SizedBox(height: AppSpacing.l),
            SizedBox(
              height: 64,
              child: CustomPaint(
                painter: TuningMeterPainter(
                  cents: v.cents,
                  active: v.hasPitch,
                  inTune: v.state == TuningState.inTune,
                ),
                child: const SizedBox.expand(),
              ),
            ),
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
            const SizedBox(height: AppSpacing.l),
            Expanded(
              child: CustomPaint(
                painter: StringVisualizerPainter(
                  activeIndex: v.activeStringIndex,
                  intensity: v.intensity,
                ),
                child: const SizedBox.expand(),
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

class _NoteDisplay extends StatelessWidget {
  const _NoteDisplay({required this.view});

  final TunerView view;

  @override
  Widget build(BuildContext context) {
    final Color color = !view.hasPitch
        ? AppColors.textSecondary
        : switch (view.state) {
            TuningState.inTune => AppColors.inTune,
            TuningState.flat => AppColors.flat,
            TuningState.sharp => AppColors.sharp,
          };

    final String centsLabel =
        view.hasPitch ? '${view.cents > 0 ? '+' : ''}${view.cents.round()}' : '';

    return Semantics(
      container: true,
      liveRegion: true,
      label: view.hasPitch
          ? 'Nota ${view.noteName} ${view.octave}, $centsLabel cents'
          : 'Nenhuma nota detectada',
      child: GlassCard(
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                Text(
                  view.noteName,
                  style: AppTypography.display.copyWith(color: color),
                ),
                if (view.octave.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      view.octave,
                      style: AppTypography.headline.copyWith(color: color),
                    ),
                  ),
              ],
            ),
            Text(centsLabel, style: AppTypography.title.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
