import 'package:flutter/material.dart';

import '../../../data/local/app_database.dart';

/// Ícono discreto con el estado de sincronización de una fichada.
class SyncStatusIcon extends StatelessWidget {
  const SyncStatusIcon({super.key, required this.status, this.error});

  final SyncStatus status;
  final String? error;

  static String labelFor(SyncStatus status) => switch (status) {
    SyncStatus.pending => 'Pendiente de sincronizar',
    SyncStatus.synced => 'Sincronizada',
    SyncStatus.error => 'Error al sincronizar',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, color) = switch (status) {
      SyncStatus.pending => (
        Icons.cloud_upload_outlined,
        scheme.onSurfaceVariant,
      ),
      SyncStatus.synced => (Icons.cloud_done_outlined, scheme.primary),
      SyncStatus.error => (Icons.error_outline, scheme.error),
    };
    final label = status == SyncStatus.error && error != null
        ? '${labelFor(status)}: $error'
        : labelFor(status);
    return Tooltip(
      message: label,
      triggerMode: TooltipTriggerMode.tap,
      child: Semantics(
        label: label,
        excludeSemantics: true,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
