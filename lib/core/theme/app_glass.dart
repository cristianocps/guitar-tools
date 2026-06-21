/// Glassmorphism metrics (blur sigma, radius) kept modest for FPS on
/// low-end Android. Use `BackdropFilter` only on static panels.
abstract final class AppGlass {
  static const double blurSigma = 14;
  static const double blurSigmaStrong = 24;
  static const double radius = 20;
}
