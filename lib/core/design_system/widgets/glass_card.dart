import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_spacing.dart';

/// A frosted-glass panel: blurred backdrop + translucent surface + subtle
/// border. Use on static panels (headers, detail cards), never inside animated
/// `CustomPaint` regions (perf).
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.m),
    this.radius,
    this.strong = false,
    super.key,
  });

  final Widget child;

  final EdgeInsetsGeometry padding;

  /// Corner radius; defaults to [AppGlass.radius].
  final double? radius;

  /// Uses a stronger blur and surface for emphasis.
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final double r = radius ?? AppGlass.radius;
    final double sigma = strong ? AppGlass.blurSigmaStrong : AppGlass.blurSigma;

    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: strong ? AppColors.glassSurfaceStrong : AppColors.glassSurface,
            borderRadius: BorderRadius.circular(r),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
