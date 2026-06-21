import 'package:flutter/material.dart';

/// Centralized color palette for Music Tools.
///
/// A dark, vibrant ("stunning") identity: deep near-black surfaces with
/// cyan/teal and magenta neon accents, plus semantic colors used by the
/// tuner (in-tune / flat / sharp).
abstract final class AppColors {
  // Surfaces.
  static const Color background = Color(0xFF0B0F14);
  static const Color surface = Color(0xFF121821);
  static const Color surfaceElevated = Color(0xFF1B2330);
  static const Color border = Color(0xFF27313F);

  // Brand accents.
  static const Color primary = Color(0xFF2DE2E6); // cyan/teal
  static const Color secondary = Color(0xFFFF3CAC); // magenta/pink
  static const Color tertiary = Color(0xFFFFB627); // amber/gold

  // Semantic (tuner / metronome accents).
  static const Color inTune = Color(0xFF39E991); // green
  static const Color flat = Color(0xFFFFB627); // amber
  static const Color sharp = Color(0xFFFF5C7A); // red/pink
  static const Color accent = Color(0xFFFF5C7A); // metronome downbeat

  // Text.
  static const Color textPrimary = Color(0xFFF2F5F8);
  static const Color textSecondary = Color(0xFF8A97A8);
  static const Color textMuted = Color(0xFF5A6675);

  // Glassmorphism surfaces (translucent overlays over the gradient).
  static const Color glassSurface = Color(0x1AFFFFFF); // ~10% white
  static const Color glassSurfaceStrong = Color(0x2BFFFFFF); // ~17% white
  static const Color glassBorder = Color(0x24FFFFFF); // ~14% white

  /// Background gradient used app-wide for a depth/glow feel.
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Color(0xFF0E141B),
      Color(0xFF0B0F14),
      Color(0xFF090C11),
    ],
  );
}
