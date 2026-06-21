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

class _HarmonicFieldScreenState extends ConsumerState<HarmonicFieldScreen> {
  int _tonic = 0; // C
  ScaleType _mode = ScaleType.major;
  int? _selectedDegree;

  @override
  Widget build(BuildContext context) {
    // Real-time tonic from the detected note (with light hysteresis).
    ref.listen<AsyncValue<PitchEvent>>(pitchStreamProvider,
        (_, AsyncValue<PitchEvent> next) {
      next.maybeWhen<void>(
        data: (PitchEvent e) {
          if (!e.hasPitch || e.confidence < 0.85) {
            return;
          }
          final TuningReading? reading = noteFromFrequency(
            e.frequency,
            a4Reference: ref.read(a4ReferenceProvider),
          );
          if (reading == null) {
            return;
          }
          if (reading.nearest.pitchClass != _tonic) {
            setState(() => _tonic = reading.nearest.pitchClass);
          }
        },
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
                      child: CustomPaint(
                        painter: HarmonicCirclePainter(
                          field: field,
                          selectedIndex: _selectedDegree,
                        ),
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
    final String notes = degree.chord.pitchClasses
        .map((int pc) => PitchNames.name(pc, notation: notation))
        .join('  ');

    return GlassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            '${degree.romanNumeral}  ·  ',
            style: AppTypography.title.copyWith(color: AppColors.primary),
          ),
          Text(
            degree.chord.name(notation: notation),
            style: AppTypography.headline,
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
