import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/sync/sync_controller.dart';
import '../asistencia_providers.dart';

/// Contador global de fichadas sin sincronizar. Al tocarlo sincroniza.
class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendientesCountProvider).value ?? 0;
    final sync = ref.watch(syncControllerProvider);

    final String tooltip;
    final IconData icon;
    if (sync.running) {
      tooltip = 'Sincronizando…';
      icon = Icons.sync;
    } else if (pending == 0) {
      tooltip = 'Todo sincronizado';
      icon = Icons.cloud_done_outlined;
    } else if (sync.offline) {
      tooltip = 'Sin conexión: $pending sin sincronizar';
      icon = Icons.cloud_off_outlined;
    } else {
      tooltip = '$pending sin sincronizar. Tocá para reintentar.';
      icon = Icons.cloud_upload_outlined;
    }

    return IconButton(
      key: const Key('sync-indicator'),
      tooltip: tooltip,
      onPressed: sync.running
          ? null
          : () => ref.read(syncControllerProvider.notifier).syncNow(),
      icon: Badge(
        isLabelVisible: pending > 0,
        label: Text('$pending'),
        child: Icon(icon),
      ),
    );
  }
}
