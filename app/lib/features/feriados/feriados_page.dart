import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/formatters.dart';
import '../../data/sync/sync_controller.dart';
import '../../domain/domain.dart';
import '../asistencia/asistencia_providers.dart';
import '../asistencia/widgets/sync_indicator.dart';

/// Texto del tipo de feriado.
String tipoFeriadoLabel(HolidayKind kind) => switch (kind) {
  HolidayKind.fixed => 'Inamovible',
  HolidayKind.movable => 'Trasladable',
  HolidayKind.nonWorking => 'No laborable turístico',
};

String _capitalizar(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Feriados nacionales guardados en el dispositivo (funciona sin red),
/// agrupados por mes y con el próximo destacado.
class FeriadosPage extends ConsumerStatefulWidget {
  const FeriadosPage({super.key});

  @override
  ConsumerState<FeriadosPage> createState() => _FeriadosPageState();
}

class _FeriadosPageState extends ConsumerState<FeriadosPage> {
  /// Año elegido (estado local de la pantalla). `null` = el de hoy.
  int? _anio;

  @override
  Widget build(BuildContext context) {
    final feriados = ref.watch(feriadosLocalesProvider);
    final hoy = ref.watch(todayProvider);
    final anio = _anio ?? hoy.year;
    final anios = {
      hoy.year,
      for (final f in feriados.value ?? const <Holiday>[]) f.date.year,
    }.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text('Feriados $anio'),
        actions: [
          if (anios.length > 1)
            PopupMenuButton<int>(
              key: const Key('elegir-anio'),
              tooltip: 'Elegir año',
              icon: const Icon(Icons.calendar_month),
              initialValue: anio,
              onSelected: (a) => setState(() => _anio = a),
              itemBuilder: (_) => [
                for (final a in anios)
                  PopupMenuItem(value: a, child: Text('$a')),
              ],
            ),
          const SyncIndicator(),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: switch (feriados) {
              AsyncData(:final value) when value.isEmpty =>
                const _SinFeriados(),
              AsyncData(:final value) => _Lista(
                feriados: [
                  for (final f in value)
                    if (f.date.year == anio) f,
                ]..sort((a, b) => a.date.compareTo(b.date)),
                anio: anio,
                hoy: hoy,
              ),
              AsyncError(:final error) => _Error(
                error: error,
                onRetry: () => ref.invalidate(feriadosLocalesProvider),
              ),
              _ => const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Cargando feriados',
                ),
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.feriados, required this.anio, required this.hoy});

  final List<Holiday> feriados;
  final int anio;
  final CalendarDate hoy;

  @override
  Widget build(BuildContext context) {
    if (feriados.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No hay feriados guardados para $anio.',
            key: const Key('sin-feriados-anio'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final proximo = nextHoliday(feriados, hoy);
    final porMes = <int, List<Holiday>>{};
    for (final f in feriados) {
      (porMes[f.date.month] ??= []).add(f);
    }
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (proximo != null) _Proximo(feriado: proximo, hoy: hoy),
        for (final entry in porMes.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
            child: Semantics(
              header: true,
              child: Text(
                _capitalizar(nombreMes(entry.key)),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          for (final f in entry.value)
            _FeriadoTile(feriado: f, destacado: f == proximo),
        ],
      ],
    );
  }
}

class _Proximo extends StatelessWidget {
  const _Proximo({required this.feriado, required this.hoy});

  final Holiday feriado;
  final CalendarDate hoy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final dias = DateTime.utc(
      feriado.date.year,
      feriado.date.month,
      feriado.date.day,
    ).difference(DateTime.utc(hoy.year, hoy.month, hoy.day)).inDays;
    final cuando = switch (dias) {
      0 => 'Es hoy',
      1 => 'Es mañana',
      _ => 'Faltan $dias días',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        key: const Key('proximo-feriado'),
        color: scheme.primaryContainer,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Próximo feriado · $cuando',
                style: text.labelLarge?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                feriado.name,
                style: text.titleLarge?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_capitalizar(nombreDiaSemana(feriado.date))} '
                '${formatDate(feriado.date)} · '
                '${tipoFeriadoLabel(feriado.kind)}',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeriadoTile extends StatelessWidget {
  const _FeriadoTile({required this.feriado, required this.destacado});

  final Holiday feriado;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      key: Key('feriado-${toIsoDate(feriado.date)}'),
      selected: destacado,
      selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.35),
      leading: SizedBox(
        width: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              feriado.date.day.toString().padLeft(2, '0'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(nombreDiaSemana(feriado.date).substring(0, 3)),
          ],
        ),
      ),
      title: Text(feriado.name),
      subtitle: Text(
        '${_capitalizar(nombreDiaSemana(feriado.date))} '
        '${formatDate(feriado.date)} · ${tipoFeriadoLabel(feriado.kind)}',
      ),
      trailing: destacado
          ? Icon(Icons.star, color: scheme.primary, semanticLabel: 'Próximo')
          : null,
    );
  }
}

/// Todavía no hay feriados en el dispositivo: se ofrece sincronizar.
class _SinFeriados extends ConsumerWidget {
  const _SinFeriados();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncControllerProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_note_outlined, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Todavía no hay feriados guardados en este dispositivo.',
              key: Key('sin-feriados'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Se bajan al sincronizar y después se pueden ver sin conexión.',
              textAlign: TextAlign.center,
            ),
            if (!sync.running && sync.offline) ...[
              const SizedBox(height: 8),
              const Text(
                'Sin conexión. Probá de nuevo cuando tengas señal.',
                key: Key('feriados-sin-conexion'),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('sincronizar-feriados'),
              onPressed: sync.running
                  ? null
                  : () => ref.read(syncControllerProvider.notifier).syncNow(),
              icon: sync.running
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(sync.running ? 'Sincronizando…' : 'Sincronizar'),
            ),
          ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            const Text(
              'No se pudieron leer los feriados guardados en el dispositivo.',
              key: Key('error-feriados'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
