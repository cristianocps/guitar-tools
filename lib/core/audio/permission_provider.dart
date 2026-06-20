import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// Tracks microphone permission status and allows requesting it.
class MicPermissionNotifier extends StateNotifier<PermissionStatus> {
  MicPermissionNotifier() : super(PermissionStatus.denied) {
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    try {
      state = await Permission.microphone.status;
    } on Object {
      // Platform channel unavailable (e.g. in tests) → default to denied.
      state = PermissionStatus.denied;
    }
  }

  Future<void> request() async {
    try {
      state = await Permission.microphone.request();
    } on Object {
      state = PermissionStatus.denied;
    }
  }

  Future<void> refresh() async => _refresh();
}

final micPermissionProvider =
    StateNotifierProvider<MicPermissionNotifier, PermissionStatus>(
  (ref) => MicPermissionNotifier(),
);

/// Whether the user permanently denied the permission (must open settings).
final isMicPermanentlyDeniedProvider = Provider<bool>((ref) {
  final status = ref.watch(micPermissionProvider);
  return status == PermissionStatus.permanentlyDenied ||
      status == PermissionStatus.restricted ||
      status == PermissionStatus.limited;
});
