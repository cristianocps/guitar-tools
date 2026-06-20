import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The three app destinations.
enum AppTab { metronome, harmonicField, tuner }

final activeTabProvider = StateProvider<AppTab>((ref) => AppTab.metronome);

/// Whether the app is in the foreground (resumed). Mic-using features pause
/// capture when this becomes false.
final appResumedProvider = StateProvider<bool>((ref) => true);
