import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Builds the app-wide [ThemeData] (dark, vibrant identity).
class AppTheme {
  const AppTheme._();

  static ThemeData dark() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: scheme,
      canvasColor: AppColors.background,
      splashFactory: InkSparkle.splashFactory,
      textTheme: _textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: MaterialStatePropertyAll<TextStyle>(
          AppTypography.label.copyWith(color: AppColors.textSecondary),
        ),
        iconTheme: const MaterialStatePropertyAll<IconThemeData>(
          IconThemeData(color: AppColors.textSecondary),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static TextTheme get _textTheme => TextTheme(
    displayLarge: AppTypography.display,
    headlineMedium: AppTypography.headline,
    titleLarge: AppTypography.title,
    bodyMedium: AppTypography.body,
    labelLarge: AppTypography.label,
    bodySmall: AppTypography.caption,
  );
}
