import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// App-styled segmented selector backed by Material 3 [SegmentedButton].
class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({
    required this.segments,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<ButtonSegment<T>> segments;

  final Set<T> selected;

  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) => states.contains(MaterialState.selected)
              ? AppColors.primary
              : AppColors.glassSurface,
        ),
        foregroundColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) => states.contains(MaterialState.selected)
              ? AppColors.background
              : AppColors.textSecondary,
        ),
        side: const MaterialStatePropertyAll<BorderSide>(
          BorderSide(color: AppColors.glassBorder),
        ),
        shape: MaterialStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      segments: segments,
      selected: selected,
      showSelectedIcon: false,
      onSelectionChanged: (Set<T> selection) => onChanged(selection.first),
    );
  }
}
