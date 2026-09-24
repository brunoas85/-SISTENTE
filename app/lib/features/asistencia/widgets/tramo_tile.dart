import 'package:flutter/material.dart';

import '../../../core/format/formatters.dart';
import '../../../data/fichadas/fichadas_repository.dart';
import '../../../data/local/app_database.dart';
import '../../../domain/domain.dart';
import 'sync_status_icon.dart';

/// Un tramo del día: ingreso, egreso (o *abierto*), trabajado y estado de
/// sincronización.
class TramoTile extends StatelessWidget {
  const TramoTile({super.key, required this.fichada});

  final LocalFichada fichada;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final egreso = fichada.egresoMin;
    final worked = workedMinutesOf(fichada.toDailyRecord());
    final horario = egreso == null
        ? '${formatClock(fichada.ingresoMin)} – abierto'
        : '${formatClock(fichada.ingresoMin)} – ${formatClock(egreso)}';

    final detalles = <String>[
      if (worked != null) 'Trabajado ${formatMinutes(worked)}',
      if (egreso == null) 'Falta el egreso',
      if (fichada.ingresoOriginalMin != null)
        'Ingreso corregido (el dispositivo marcó ${formatClock(fichada.ingresoOriginalMin!)})',
      if (fichada.egresoOriginalMin != null)
        'Egreso corregido (el dispositivo marcó ${formatClock(fichada.egresoOriginalMin!)})',
      if (fichada.syncStatus == SyncStatus.error && fichada.syncError != null)
        fichada.syncError!,
    ];

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      leading: Icon(
        egreso == null ? Icons.timelapse : Icons.check_circle_outline,
        color: egreso == null ? theme.colorScheme.tertiary : null,
      ),
      title: Text(
        horario,
        style: theme.textTheme.titleMedium?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      subtitle: detalles.isEmpty ? null : Text(detalles.join('\n')),
      trailing: SyncStatusIcon(
        status: fichada.syncStatus,
        error: fichada.syncError,
      ),
    );
  }
}
