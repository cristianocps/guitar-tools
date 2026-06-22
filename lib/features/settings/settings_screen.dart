import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/app_background.dart';
import '../../core/design_system/widgets.dart';
import '../../core/music_theory/pitch.dart';
import '../../core/music_theory/tuning.dart';
import '../../core/settings/settings.dart';
import '../../core/settings/settings_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(settingsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Ajustes'),
      ),
      body: AppBackground(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.l,
            vertical: AppSpacing.m,
          ),
          child: ListView(
            children: <Widget>[
              const SizedBox(height: AppSpacing.xl),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SectionTitle('Referência de afinação'),
                    const SizedBox(height: AppSpacing.m),
                    _A4Stepper(
                      value: settings.a4Reference,
                      onChanged: (double v) => ref
                          .read(settingsProvider.notifier)
                          .setA4Reference(v),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    const SectionTitle('Notação das notas'),
                    const SizedBox(height: AppSpacing.m),
                    _NotationSelector(
                      value: settings.notation,
                      onChanged: (Notation v) => ref
                          .read(settingsProvider.notifier)
                          .setNotation(v),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    const SectionTitle('Afinação padrão'),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      'Usada pelo modo por corda do afinador.',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    _TuningPresetSelector(
                      value: settings.defaultTuningPreset,
                      onChanged: (TuningPresetId v) => ref
                          .read(settingsProvider.notifier)
                          .setDefaultTuningPreset(v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              GlassCard(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Lembrar última aba, BPM e compasso',
                    style: AppTypography.body,
                  ),
                  value: settings.rememberLast,
                  activeTrackColor: AppColors.primary,
                  onChanged: (bool v) =>
                      ref.read(settingsProvider.notifier).setRememberLast(v),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
            ],
          ),
        ),
      ),
    );
  }
}

class _A4Stepper extends StatelessWidget {
  const _A4Stepper({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final int hz = value.round();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        IconButton.filled(
          onPressed:
              hz <= AppSettings.minA4 ? null : () => onChanged(value - 1),
          icon: const Icon(Icons.remove),
        ),
        Text('$hz Hz', style: AppTypography.headline),
        IconButton.filled(
          onPressed:
              hz >= AppSettings.maxA4 ? null : () => onChanged(value + 1),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _NotationSelector extends StatelessWidget {
  const _NotationSelector({required this.value, required this.onChanged});

  final Notation value;
  final ValueChanged<Notation> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppSegmented<Notation>(
      segments: const <ButtonSegment<Notation>>[
        ButtonSegment<Notation>(
          value: Notation.letters,
          label: Text('Letras (C D E)'),
        ),
        ButtonSegment<Notation>(
          value: Notation.solfeggio,
          label: Text('Solfejo (Dó Ré Mi)'),
        ),
      ],
      selected: <Notation>{value},
      onChanged: onChanged,
    );
  }
}

class _TuningPresetSelector extends StatelessWidget {
  const _TuningPresetSelector({
    required this.value,
    required this.onChanged,
  });

  final TuningPresetId value;
  final ValueChanged<TuningPresetId> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      children: <Widget>[
        for (final TuningPreset preset in TuningPreset.all)
          AppChip(
            label: preset.tuning.name,
            selected: preset.id == value,
            onSelected: (_) => onChanged(preset.id),
          ),
      ],
    );
  }
}
