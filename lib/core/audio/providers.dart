import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/app_providers.dart';
import 'audio_capture_service.dart';
import 'permission_provider.dart';
import 'pitch_detector.dart';

/// The audio capture service (backed by `record`). Overrideable in tests.
final audioCaptureServiceProvider = Provider<AudioCaptureService>((ref) {
  final service = RecordAudioCaptureService();
  ref.onDispose(service.dispose);
  return service;
});

/// Creates and owns a [PitchDetector] over the capture service.
///
/// Because a detector instance is stateful, this provider creates one on read;
/// call [PitchDetector.stop] when no longer listening.
final pitchDetectorProvider = Provider<PitchDetector>((ref) {
  final AudioCaptureService capture = ref.watch(audioCaptureServiceProvider);
  return PitchDetector(capture: capture);
});

/// Live pitch stream that automatically starts capture only when a mic-using
/// feature (tuner / harmonic field) is active, the app is in the foreground
/// and microphone permission has been granted. Rebuilds (start/stop) when any
/// of those conditions change — this is the single owner of the microphone,
/// satisfying the lifecycle requirement.
final pitchStreamProvider =
    StreamProvider.autoDispose<PitchEvent>((ref) {
  final AppTab tab = ref.watch(activeTabProvider);
  final bool resumed = ref.watch(appResumedProvider);
  final PermissionStatus permission = ref.watch(micPermissionProvider);

  final bool micActive = (tab == AppTab.tuner || tab == AppTab.harmonicField) &&
      resumed &&
      permission == PermissionStatus.granted;

  if (!micActive) {
    return const Stream<PitchEvent>.empty();
  }

  final AudioCaptureService capture = ref.watch(audioCaptureServiceProvider);
  final PitchDetector detector = PitchDetector(capture: capture);
  ref.onDispose(detector.stop);
  return detector.start();
});
