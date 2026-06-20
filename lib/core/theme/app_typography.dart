import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Text styles for the app. Built on the default [TextTheme] but normalized to
/// the app's foreground colors and weights.
abstract final class AppTypography {
  static const TextStyle _base = TextStyle(
    color: AppColors.textPrimary,
    fontFamilyFallback: <String>['Roboto', 'SF Pro Display', 'Arial'],
  );

  static TextStyle get display => _base.copyWith(
        fontSize: 72,
        fontWeight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -1.5,
      );

  static TextStyle get headline => _base.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.5,
      );

  static TextStyle get title => _base.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  static TextStyle get body => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.textSecondary,
      );

  static TextStyle get label => _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.4,
      );

  static TextStyle get caption => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: AppColors.textMuted,
      );
}
