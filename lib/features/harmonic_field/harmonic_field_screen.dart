import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/pitch_detector.dart';
import '../../core/audio/providers.dart';
import '../../core/design_system/app_background.dart';
import '../../core/design_system/widgets.dart';
import '../../core/music_theory/harmonic_field.dart';
import '../../core/music_theory/note.dart';
import '../../core/music_theory/pitch.dart';
import '../../core/settings/settings_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'circle_painter.dart';

class HarmonicFieldScreen extends ConsumerStatefulWidget {
  const HarmonicFieldScreen({super.key});

  @override
  ConsumerState<HarmonicFieldScreen> createState() =>
      _HarmonicFieldScreenState();
}

class _HarmonicFieldScreenState extends ConsumerState<HarmonicFieldScreen>
    with SingleTickerProviderStateMixin {
  int _tonic = 0; // C
  ScaleType _mode = ScaleType.major;
  int? _selectedDegree;
  bool _listening = false;

  // Hysteresis for the auto-tonic: only commit after the same pitch class is
  // detected on several consecutive frames, so the circle doesn't flicker.
  int? _candidateTonic;
  int _candidateCount = 0;
  static const int _stabilityFrames = 4;

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _onPitch(PitchEvent e) {
    final bool active = e.hasPitch && e.confidence >= 0.85;
    if (active != _listening) {
      setState(() => _listening = active);
    }
    if (!active) {
      _candidateTonic = null;
      _candidateCount = 0;
      return;
    }
    final TuningReading? reading = noteFromFrequency(
      e.frequency,
      a4Reference: ref.read(a4ReferenceProvider),
    );
    if (reading == null) {
      return;
    }
    final int pc = reading.nearest.pitchClass;
    if (pc == _candidateTonic) {
      _candidateCount++;
    } else {
      _candidateTonic = pc;
      _candidateCount = 1;
    }
    if (_candidateCount >= _stabilityFrames && pc != _tonic) {
      setState(() => _tonic = pc);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<PitchEvent>>(pitchStreamProvider,
        (_, AsyncValue<PitchEvent> next) {
      next.maybeWhen<void>(
        data: _onPitch,
        orElse: () {},
      );
    });

    final HarmonicField field = HarmonicField.of(_tonic, _mode);
    final Notation notation = ref.watch(notationProvider);

    return AppBackground(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.m,
        ),
        child: Column(
          children: <Widget>[
            const SizedBox(height: AppSpacing.s),
            const ToolHeader(title: 'Campo Harmônico'),
            const SizedBox(height: AppSpacing.s),
            _ListeningPill(listening: _listening),
            const SizedBox(height: AppSpacing.s),
            AppSegmented<ScaleType>(
              segments: const <ButtonSegment<ScaleType>>[
                ButtonSegment<ScaleType>(
                  value: ScaleType.major,
                  label: Text('Maior'),
                ),
                ButtonSegment<ScaleType>(
                  value: ScaleType.naturalMinor,
                  label: Text('Menor'),
                ),
              ],
              selected: <ScaleType>{_mode},
              onChanged: (ScaleType s) => setState(() => _mode = s),
            ),
            const SizedBox(height: AppSpacing.m),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final Size size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight - 80,
                  );
                  final Offset center =
                      Offset(size.width / 2, size.height / 2);
                  final double radius =
                      min(size.width, size.height) / 2 - 48;

                  return GestureDetector(
                    onTapUp: (TapUpDetails details) =>
                        _handleTap(details.localPosition, center, radius),
                    child: SizedBox(
                      width: size.width,
                      height: size.height,
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (BuildContext context, _) {
                          return CustomPaint(
                            painter: HarmonicCirclePainter(
                              field: field,
                              selectedIndex: _selectedDegree,
                              pulse: _pulse.value,
                              notation: notation,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            _DegreeDetails(
              field: field,
              selectedIndex: _selectedDegree,
              notation: notation,
            ),
            const SizedBox(height: AppSpacing.s),
            _NoteSelector(
              selected: _tonic,
              notation: notation,
              onSelect: (int pc) => setState(() => _tonic = pc),
            ),
            const SizedBox(height: AppSpacing.m),
          ],
        ),
      ),
    );
  }

  void _handleTap(Offset local, Offset center, double radius) {
    final List<Offset> nodes = degreeOffsets(center, radius);
    int? nearest;
    double best = 40;
    for (int i = 0; i < nodes.length; i++) {
      final double d = (nodes[i] - local).distance;
      if (d < best) {
        best = d;
        nearest = i;
      }
    }
    if (nearest != null) {
      setState(
        () => _selectedDegree =
            _selectedDegree == nearest ? null : nearest,
      );
    }
  }
}

class _ListeningPill extends StatelessWidget {
  const _ListeningPill({required this.listening});

  final bool listening;

  @override
  Widget build(BuildContext context) {
    final Color color = listening ? AppColors.inTune : AppColors.textMuted;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GlowingDot(color: color, size: 9, active: listening),
          const SizedBox(width: AppSpacing.s),
          Text(
            listening ? 'Ouvindo o instrumento' : 'Toque uma nota para girar',
            style: AppTypography.label.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _DegreeDetails extends StatelessWidget {
  const _DegreeDetails({
    required this.field,
    required this.selectedIndex,
    required this.notation,
  });

  final HarmonicField field;
  final int? selectedIndex;
  final Notation notation;

  @override
  Widget build(BuildContext context) {
    if (selectedIndex == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
        child: Text(
          'Toque em um grau para ver o acorde • ouça uma nota para girar o círculo',
          textAlign: TextAlign.center,
          style: AppTypography.caption,
        ),
      );
    }
    final HarmonicDegree degree = field.degrees[selectedIndex!];
    final Color color = colorForQuality(degree.chord.quality);
    final String notes = degree.chord.pitchClasses
        .map((int pc) => PitchNames.name(pc, notation: notation))
        .join('  ');

    return GlassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          GlowingDot(color: color, size: 10),
          const SizedBox(width: AppSpacing.s),
          Text(
            '${degree.romanNumeral}  ·  ',
            style: AppTypography.title.copyWith(color: color),
          ),
          Text(
            degree.chord.name(notation: notation),
            style: AppTypography.headline.copyWith(color: color),
          ),
          const SizedBox(width: AppSpacing.m),
          Text(notes, style: AppTypography.body),
        ],
      ),
    );
  }
}

class _NoteSelector extends StatelessWidget {
  const _NoteSelector({
    required this.selected,
    required this.notation,
    required this.onSelect,
  });

  final int selected;
  final Notation notation;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (int pc = 0; pc < 12; pc++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AppChip(
                label: PitchNames.name(pc, notation: notation),
                selected: pc == selected,
                onSelected: (_) => onSelect(pc),
              ),
            ),
        ],
      ),
    );
  }
}
