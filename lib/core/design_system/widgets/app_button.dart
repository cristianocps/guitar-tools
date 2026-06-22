import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../glow.dart';

/// A prominent action button with a neon glow and a scale-down micro-interaction
/// on press. Uses [backgroundColor] for the fill (defaults to the brand cyan).
class AppButton extends StatefulWidget {
  const AppButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    super.key,
  });

  final String label;

  final IconData icon;

  final VoidCallback? onPressed;

  final Color? backgroundColor;

  final Color? foregroundColor;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color bg = widget.backgroundColor ?? AppColors.primary;
    final Color fg = widget.foregroundColor ?? AppColors.background;
    final bool enabled = widget.onPressed != null;

    return GestureDetector(
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        child: NeonGlow(
          color: bg.withValues(alpha: enabled ? 0.5 : 0.15),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.m,
            ),
            decoration: BoxDecoration(
              color: enabled ? bg : bg.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppSpacing.xxl),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(widget.icon, size: 28, color: fg),
                const SizedBox(width: AppSpacing.s),
                Text(
                  widget.label,
                  style: AppTypography.title.copyWith(color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
