import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/format/formatters.dart';
import '../../data/fichadas/fichadas_repository.dart';
import '../../data/local/app_database.dart';
import '../../data/photos/photo_capture.dart';
import '../../data/providers.dart';
import '../../domain/domain.dart';
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
  bool _capturando = false;

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

  Future<void> _fichar(ResumenFichar resumen) async {
    if (_capturando) return;
    final now = ref.read(clockProvider)();
    final fecha = CalendarDate.fromDateTime(now);
    final proposed = minutesOfDay(now);
    final tipo = resumen.proximaFichada;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _capturando = true);
    Uint8List? raw;
    try {
      raw = await ref.read(photoCaptureProvider).capture();
    } on PhotoCaptureException catch (e) {
      _avisar(messenger, e.message);
    } catch (e) {
      _avisar(messenger, 'No se pudo sacar la foto: $e');
    } finally {
      if (mounted) setState(() => _capturando = false);
    }
    if (raw == null || !mounted) return;

    final saved = await Navigator.of(context).push<LocalFichada>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ConfirmarFichadaPage(
          draft: FicharDraft(
            tipo: tipo,
            fecha: fecha,
            proposedMin: proposed,
            rawPhoto: raw!,
            tramoAbierto: tipo == TipoFichada.egreso ? resumen.abierto : null,
          ),
        ),
      ),
    );
    if (saved == null || !mounted) return;
    final hora = tipo == TipoFichada.ingreso
        ? saved.ingresoMin
        : saved.egresoMin!;
    _avisar(
      messenger,
      '${tipo == TipoFichada.ingreso ? 'Ingreso' : 'Egreso'} fichado a las '
      '${formatClock(hora)}. Se sincroniza cuando haya conexión.',
    );
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
              : 'Tenés $pendientes fichadas sin sincronizar. Quedan guardadas '
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
                capturando: _capturando,
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
  const _Contenido({
    required this.resumen,
    required this.capturando,
    required this.onFichar,
  });

  final ResumenFichar resumen;
  final bool capturando;
  final VoidCallback onFichar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final abierto = resumen.abierto;
    final esIngreso = resumen.proximaFichada == TipoFichada.ingreso;

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
              if (resumen.dia.status == DayStatus.conflict ||
                  resumen.dia.status == DayStatus.invalid)
                _Aviso(
                  texto:
                      'Hay tramos superpuestos o con horas inválidas. '
                      'Revisalos desde la PC.',
                ),
              if (resumen.abiertasAnteriores.isNotEmpty)
                _Aviso(
                  texto:
                      'Quedaron tramos sin egreso: '
                      '${resumen.abiertasAnteriores.map((f) => formatDate(f.date)).toSet().join(', ')}. '
                      'No computan hasta que se completen.',
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
            onPressed: capturando ? null : onFichar,
            icon: capturando
                ? const SizedBox.square(
                    dimension: 28,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Icon(esIngreso ? Icons.login : Icons.logout, size: 32),
            label: Text(esIngreso ? 'Fichar ingreso' : 'Fichar egreso'),
          ),
        ),
      ],
    );
  }

  static String _estadoDelDia(ResumenFichar r, LocalFichada? abierto) {
    if (abierto != null) {
      return 'Tramo abierto desde las ${formatClock(abierto.ingresoMin)}';
    }
    if (r.tramos.isEmpty) return 'Sin fichadas';
    final worked = r.dia.workedMinutes;
    return worked == null
        ? 'Sin tramo abierto'
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
      child: Tooltip(
        message:
            'Calculado solo con las fichadas. Todavía no incluye '
            'acumulaciones ni usufructos cargados a mano.',
        triggerMode: TooltipTriggerMode.tap,
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
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto});

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
