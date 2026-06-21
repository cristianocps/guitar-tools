import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// App-styled selectable chip backed by Material 3 [ChoiceChip].
class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;

  final bool selected;

  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      labelStyle: AppTypography.label.copyWith(
        color: selected ? AppColors.background : AppColors.textPrimary,
      ),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.glassSurface,
      side: const BorderSide(color: AppColors.glassBorder),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      onSelected: onSelected,
    );
  }
}
