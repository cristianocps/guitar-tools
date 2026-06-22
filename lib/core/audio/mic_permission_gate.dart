import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'permission_provider.dart';

/// Shows [child] only once microphone permission has been granted; otherwise
/// renders a prompt that requests it (or opens settings when permanently
/// denied). Use this to wrap any screen that needs the microphone so capture
/// is never started before the user has allowed it.
class MicPermissionGate extends ConsumerWidget {
  const MicPermissionGate({
    required this.child,
    this.message,
    super.key,
  });

  final Widget child;

  /// Optional explanation shown under the title.
  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PermissionStatus status = ref.watch(micPermissionProvider);
    if (status == PermissionStatus.granted) {
      return child;
    }

    final bool permanent = ref.watch(isMicPermanentlyDeniedProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.mic_off_outlined, size: 56, color: AppColors.sharp),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Este exercício precisa do microfone',
              textAlign: TextAlign.center,
              style: AppTypography.title,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              message ??
                  'Usamos o áudio apenas para ouvir o que você toca, em tempo real.',
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.l),
            FilledButton.icon(
              onPressed: permanent
                  ? openAppSettings
                  : () => ref.read(micPermissionProvider.notifier).request(),
              icon: Icon(permanent ? Icons.settings : Icons.mic),
              label: Text(
                permanent ? 'Abrir configurações' : 'Permitir microfone',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
