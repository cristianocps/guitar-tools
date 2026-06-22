import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/app_providers.dart';
import 'audio_capture_service.dart';
import 'permission_provider.dart';
import 'pitch_challenge_validator.dart';
import 'pitch_detector.dart';
import 'rhythm_detector.dart';

/// The audio capture service (backed by `record`). Overrideable in tests.
final audioCaptureServiceProvider = Provider<AudioCaptureService>((Ref ref) {
  final AudioCaptureService service = RecordAudioCaptureService();
  ref.onDispose(service.dispose);
  return service;
});

/// Creates and owns a [PitchDetector] over the capture service.
///
/// Because a detector instance is stateful, this provider creates one on read;
/// call [PitchDetector.stop] when no longer listening.
final pitchDetectorProvider = Provider<PitchDetector>((Ref ref) {
  final AudioCaptureService capture = ref.watch(audioCaptureServiceProvider);
  return PitchDetector(capture: capture);
});

/// Raw pitch stream for consumers that need a [Stream] subscription.
final rawPitchStreamProvider = Provider.autoDispose<Stream<PitchEvent>>(
  (Ref ref) {
    final AudioCaptureService capture = ref.watch(audioCaptureServiceProvider);
    final PitchDetector detector = PitchDetector(capture: capture);
    ref.onDispose(detector.stop);
    return detector.start();
  },
);

/// Live pitch stream that automatically starts capture only when the tuner or
/// harmonic field is active, the app is in the foreground and microphone
/// permission has been granted. Rebuilds (start/stop) when any of those
/// conditions change.
///
/// The training tab is intentionally excluded: each training exercise owns its
/// own audio (ear/fretboard read [rawPitchStreamProvider] directly; rhythm
/// drives the capture service itself). Keeping `training` here would let the
/// still-mounted tuner/harmonic screens (preserved by the IndexedStack) hold
/// the single capture service, so a rhythm exercise's own `start()` would throw
/// "already running" and silently do nothing.
final pitchStreamProvider = StreamProvider.autoDispose<PitchEvent>((Ref ref) {
  final AppTab tab = ref.watch(activeTabProvider);
  final bool resumed = ref.watch(appResumedProvider);
  final PermissionStatus permission = ref.watch(micPermissionProvider);

  final bool micActive =
      (tab == AppTab.tuner || tab == AppTab.harmonicField) &&
          resumed &&
          permission == PermissionStatus.granted;

  if (!micActive) {
    return const Stream<PitchEvent>.empty();
  }

  return ref.watch(rawPitchStreamProvider);
});

/// Shared [PitchChallengeValidator] instance.
final pitchChallengeValidatorProvider = Provider<PitchChallengeValidator>(
  (Ref ref) => const PitchChallengeValidator(),
);

/// Factory provider for [RhythmDetector] instances.
final rhythmDetectorProvider = Provider.autoDispose<RhythmDetector>((Ref ref) {
  final AudioCaptureService capture = ref.watch(audioCaptureServiceProvider);
  final RhythmDetector detector =
      RhythmDetector(sampleRate: capture.sampleRate);
  ref.onDispose(detector.dispose);
  return detector;
});
