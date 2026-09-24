import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/format/formatters.dart';
import '../../data/fichadas/fichada_validation.dart';
import '../../data/fichadas/fichadas_repository.dart';
import '../../data/local/app_database.dart';
import '../../data/providers.dart';
import '../../domain/domain.dart';
import '../perfil/perfil_providers.dart';
import 'asistencia_providers.dart';
import 'confirmar_fichada_page.dart';
import 'widgets/sync_indicator.dart';
import 'widgets/tramo_tile.dart';

/// Pantalla principal en el celular: estado de hoy y un botón grande para
/// fichar ingreso o egreso con la foto del biométrico.
class FicharPage extends ConsumerStatefulWidget {
  const FicharPage({super.key});

  @override
  ConsumerState<FicharPage> createState() => _FicharPageState();
}

class _FicharPageState extends ConsumerState<FicharPage> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Si la app quedó abierta de un día para otro, "hoy" se actualiza.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(todayProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// Abre la confirmación: la hora es la del toque y la foto es opcional.
  /// Si quedó abierto un tramo de un día anterior, primero se cierra ese.
  Future<void> _fichar(ResumenFichar resumen) async {
    if (resumen.fichadaBloqueada) return;
    final now = ref.read(clockProvider)();
    final accion = resumen.proximaAccion;
    final messenger = ScaffoldMessenger.of(context);

    final FicharDraft draft;
    switch (accion) {
      case AccionFichar.cerrarAnterior:
        final tramo = resumen.pendienteDeCierre!;
        draft = FicharDraft(
          tipo: TipoFichada.egreso,
          fecha: tramo.date,
          proposedMin: null, // hora a mano
          tramoAbierto: tramo,
          otrosTramos: resumen.tramosDe(tramo.date),
        );
      case AccionFichar.ingreso:
      case AccionFichar.egreso:
        final fecha = CalendarDate.fromDateTime(now);
        draft = FicharDraft(
          tipo: accion.tipo,
          fecha: fecha,
          proposedMin: minutesOfDay(now),
          tramoAbierto: accion == AccionFichar.egreso ? resumen.abierto : null,
          otrosTramos: resumen.tramosDe(fecha),
        );
    }

    final saved = await Navigator.of(context).push<LocalFichada>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ConfirmarFichadaPage(draft: draft),
      ),
    );
    if (saved == null || !mounted) return;
    final texto = switch (accion) {
      AccionFichar.ingreso =>
        'Ingreso fichado a las ${formatClock(saved.ingresoMin)}.',
      AccionFichar.egreso =>
        'Egreso fichado a las ${formatClock(saved.egresoMin!)}.',
      AccionFichar.cerrarAnterior =>
        'Tramo del ${formatDate(saved.date)} cerrado a las '
            '${formatClock(saved.egresoMin!)}.',
    };
    _avisar(messenger, '$texto Se sincroniza cuando haya conexión.');
  }

  /// Aviso flotante por encima del botón principal (no lo tapa).
  static void _avisar(ScaffoldMessengerState messenger, String texto) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(texto),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 128),
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    final pendientes = ref.read(pendientesCountProvider).value ?? 0;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: Text(
          pendientes == 0
              ? '¿Querés cerrar la sesión?'
              : 'Tenés $pendientes cambios sin sincronizar. Quedan guardados '
                    'en este dispositivo y se suben cuando vuelvas a entrar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authRepositoryProvider).signOut();
      ref.read(currentUserIdProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final resumen = ref.watch(resumenFicharProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('@sistente'),
        actions: [
          const SyncIndicator(),
          PopupMenuButton<String>(
            tooltip: 'Más opciones',
            onSelected: (v) {
              if (v == 'logout') _cerrarSesion();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'logout', child: Text('Cerrar sesión')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: switch (resumen) {
              AsyncData(:final value) => _Contenido(
                resumen: value,
                onFichar: () => _fichar(value),
              ),
              AsyncError(:final error) => _Error(
                error: error,
                onRetry: () => ref.invalidate(misFichadasProvider),
              ),
              _ => const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Cargando fichadas',
                ),
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.resumen, required this.onFichar});

  final ResumenFichar resumen;
  final VoidCallback onFichar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final abierto = resumen.abierto;
    final accion = resumen.proximaAccion;
    final esIngreso = accion == AccionFichar.ingreso;
    final pendiente = resumen.pendienteDeCierre;
    final (IconData icono, String etiqueta) = switch (accion) {
      AccionFichar.ingreso => (Icons.login, 'Fichar ingreso'),
      AccionFichar.egreso => (Icons.logout, 'Fichar egreso'),
      AccionFichar.cerrarAnterior => (
        Icons.history,
        'Cerrar tramo del ${formatDate(pendiente!.date)}',
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Hoy, ${formatDateLong(resumen.hoy)}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  _estadoDelDia(resumen, abierto),
                  key: const Key('estado-hoy'),
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              _SaldoLinea(resumen: resumen),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(
                  _jornadaTexto(resumen),
                  key: const Key('jornada-hoy'),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              if (resumen.dia.status == DayStatus.conflict ||
                  resumen.dia.status == DayStatus.invalid ||
                  resumen.dia.status == DayStatus.nonWorkingDayRecords)
                _Aviso(
                  texto: resumen.dia.status == DayStatus.nonWorkingDayRecords
                      ? 'Hay fichadas en un día no laborable: no computan. '
                            'Revisalas desde la PC.'
                      : 'Hay tramos superpuestos o con horas inválidas. '
                            'Revisalos desde la PC.',
                ),
              if (pendiente != null)
                _Aviso(
                  key: const Key('aviso-tramo-anterior'),
                  texto:
                      'Quedó abierto el tramo del ${formatDate(pendiente.date)} '
                      'desde las ${formatClock(pendiente.ingresoMin)}. '
                      'Cerralo con la hora de egreso de ese día antes de '
                      'volver a fichar.',
                ),
              const Divider(height: 24),
              if (resumen.tramos.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Todavía no fichaste hoy.',
                    key: Key('sin-tramos'),
                    textAlign: TextAlign.center,
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Tramos de hoy',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                for (final t in resumen.tramos) TramoTile(fichada: t),
              ],
            ],
          ),
        ),
        if (resumen.fichadaBloqueada)
          _NoLaborable(dia: resumen.diaNoLaborable!),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            key: const Key('boton-fichar'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(96),
              backgroundColor: esIngreso ? null : theme.colorScheme.tertiary,
              foregroundColor: esIngreso ? null : theme.colorScheme.onTertiary,
              textStyle: theme.textTheme.headlineSmall,
            ),
            // Hoy no es laborable: no se ficha (sí se puede cerrar un tramo
            // abierto de un día hábil anterior).
            onPressed: resumen.fichadaBloqueada ? null : onFichar,
            icon: Icon(icono, size: 32),
            label: Text(etiqueta, textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }

  static String _jornadaTexto(ResumenFichar r) {
    final a = r.agrupamiento;
    final jornada = 'Jornada: ${formatMinutes(r.jornadaMinutes)}';
    return a == null ? jornada : '$jornada · ${agrupamientoLabel(a)}';
  }

  static String _estadoDelDia(ResumenFichar r, LocalFichada? abierto) {
    if (abierto != null) {
      return 'Tramo abierto desde las ${formatClock(abierto.ingresoMin)}';
    }
    if (r.tramos.isEmpty) return 'Sin fichadas';
    final worked = r.dia.workedMinutes;
    if (worked == null) return 'Sin tramo abierto';
    // La deuda de hoy es provisoria: no resta hasta que termine el día.
    final faltan = r.dia.provisionalDebtMinutes;
    return faltan > 0
        ? 'Trabajado hoy: ${formatMinutes(worked)} · faltan ${formatMinutes(faltan)}'
        : 'Trabajado hoy: ${formatMinutes(worked)}';
  }
}

class _SaldoLinea extends StatelessWidget {
  const _SaldoLinea({required this.resumen});

  final ResumenFichar resumen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color colorFor(int m) =>
        m < 0 ? theme.colorScheme.error : theme.colorScheme.onSurface;
    final base = theme.textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text.rich(
        key: const Key('saldo'),
        TextSpan(
          style: base,
          children: [
            const TextSpan(text: 'Banco · mes '),
            TextSpan(
              text: formatMinutes(resumen.saldoMesMinutes),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorFor(resumen.saldoMesMinutes),
              ),
            ),
            const TextSpan(text: ' · total '),
            TextSpan(
              text: formatMinutes(resumen.saldoTotalMinutes),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorFor(resumen.saldoTotalMinutes),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Motivo por el que hoy no se puede fichar, arriba del botón.
class _NoLaborable extends StatelessWidget {
  const _NoLaborable({required this.dia});

  final NonWorkingDay dia;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        color: scheme.secondaryContainer,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.event_busy, color: scheme.onSecondaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      motivoDiaNoLaborable(dia, esHoy: true),
                      key: const Key('aviso-no-laborable'),
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: scheme.onSecondaryContainer),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No se puede fichar hoy. Las horas trabajadas en un '
                      'día no laborable se cargan como acumulación en el '
                      'banco de horas.',
                      style: TextStyle(color: scheme.onSecondaryContainer),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        color: scheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: scheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  texto,
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          const Text(
            'No se pudieron leer las fichadas guardadas en el dispositivo.',
            key: Key('error-fichadas'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text('$error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
