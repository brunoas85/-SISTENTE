import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/formatters.dart';
import '../../data/banco/movimiento.dart';
import '../../data/local/app_database.dart';
import '../asistencia/asistencia_providers.dart';
import '../asistencia/widgets/sync_indicator.dart';
import '../asistencia/widgets/sync_status_icon.dart';
import '../shell/app_shell.dart';
import 'banco_providers.dart';
import 'movimiento_acciones.dart';
import 'movimiento_form_page.dart';
import 'resumen_banco.dart';
import 'tipos_documento_page.dart';

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}

String _capitalizar(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Minutos de un movimiento con el signo de su efecto en el banco.
String _minutosConSigno(LocalMovimiento m) =>
    formatSigned(m.kind.esUsufructo ? -m.minutos : m.minutos);

/// Banco de horas: saldo actual, desglose y movimientos manuales filtrables
/// por año y mes. En el celular es una lista; en la PC (≥ 1024), una tabla.
class BancoPage extends ConsumerStatefulWidget {
  const BancoPage({super.key});

  @override
  ConsumerState<BancoPage> createState() => _BancoPageState();
}

class _BancoPageState extends ConsumerState<BancoPage> {
  // Estado local de la pantalla (filtros y orden de la tabla).
  int? _anio;
  int? _mes;
  int _sortColumn = 0;
  bool _sortAscending = false;

  Future<void> _nuevo() => Navigator.of(context).push<LocalMovimiento>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => MovimientoFormPage(fechaInicial: ref.read(todayProvider)),
    ),
  );

  Future<void> _editar(LocalMovimiento m) =>
      Navigator.of(context).push<LocalMovimiento>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => MovimientoFormPage(movimiento: m),
        ),
      );

  Future<void> _tipos() => Navigator.of(
    context,
  ).push<void>(MaterialPageRoute(builder: (_) => const TiposDocumentoPage()));

  @override
  Widget build(BuildContext context) {
    final resumen = ref.watch(resumenBancoProvider);
    final desktop = MediaQuery.sizeOf(context).width >= Breakpoints.desktop;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): _nuevo,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Banco de horas'),
            actions: [
              IconButton(
                key: const Key('abrir-tipos'),
                tooltip: 'Tipos de documento GDE',
                onPressed: _tipos,
                icon: const Icon(Icons.description_outlined),
              ),
              const SyncIndicator(),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('nuevo-movimiento'),
            tooltip: desktop ? 'Nuevo movimiento (Ctrl+N)' : null,
            onPressed: _nuevo,
            icon: const Icon(Icons.add),
            label: const Text('Nuevo movimiento'),
          ),
          body: SafeArea(
            child: switch (resumen) {
              AsyncData(:final value) => _contenido(value, desktop),
              AsyncError(:final error) => _Error(
                error: error,
                onRetry: () => ref.invalidate(misMovimientosProvider),
              ),
              _ => const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Cargando el banco de horas',
                ),
              ),
            },
          ),
        ),
      ),
    );
  }

  Widget _contenido(ResumenBanco r, bool desktop) {
    final anios = r.anios;
    final anio = anios.contains(_anio) ? _anio! : r.hoy.year;
    final filtrados = r.filtrar(anio, _mes);
    final filtros = _Filtros(
      anios: anios,
      anio: anio,
      mes: _mes,
      variacion: _mes == null ? null : r.variacionMes(anio, _mes!),
      onAnio: (a) => setState(() => _anio = a),
      onMes: (m) => setState(() => _mes = m),
    );
    final vacio = _Vacio(
      sinMovimientos: r.movimientos.isEmpty,
      anio: anio,
      mes: _mes,
    );

    if (desktop) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _SaldoCard(resumen: r)),
              const SizedBox(width: 16),
              Expanded(flex: 3, child: _Desglose(resumen: r)),
            ],
          ),
          const SizedBox(height: 16),
          filtros,
          const SizedBox(height: 8),
          if (filtrados.isEmpty)
            vacio
          else
            _Tabla(
              resumen: r,
              movimientos: filtrados,
              sortColumn: _sortColumn,
              sortAscending: _sortAscending,
              onSort: (c, asc) => setState(() {
                _sortColumn = c;
                _sortAscending = asc;
              }),
              onEditar: _editar,
            ),
        ],
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _SaldoCard(resumen: r),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _Desglose(resumen: r),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: filtros,
            ),
            if (filtrados.isEmpty)
              vacio
            else
              for (final m in filtrados)
                _MovimientoTile(
                  movimiento: m,
                  codigo: r.codigoTipo(m.tipoDocumentoId),
                  fueraDelControl: r.fueraDelControl(m),
                  onTap: () => _editar(m),
                ),
          ],
        ),
      ),
    );
  }
}

class _SaldoCard extends StatelessWidget {
  const _SaldoCard({required this.resumen});

  final ResumenBanco resumen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final estado = resumen.estado;
    final saldo = estado.balanceMinutes;
    final negativo = saldo < 0;
    final bg = negativo ? scheme.errorContainer : scheme.primaryContainer;
    final fg = negativo ? scheme.onErrorContainer : scheme.onPrimaryContainer;
    final faltantes = estado.current.missingDays.length;
    final fuera = resumen.movimientosFueraDelControl.length;

    return Card(
      color: bg,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saldo actual al ${formatDate(resumen.hoy)}',
              style: theme.textTheme.labelLarge?.copyWith(color: fg),
            ),
            Semantics(
              label:
                  'Saldo actual ${negativo ? 'negativo ' : ''}'
                  '${formatMinutes(saldo.abs())} horas',
              excludeSemantics: true,
              child: Text(
                formatSigned(saldo),
                key: const Key('saldo-banco'),
                style: theme.textTheme.displayMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            if (estado.futureUsufructMinutes > 0)
              Text(
                'Usufructos cargados a futuro: '
                '${formatMinutes(-estado.futureUsufructMinutes)} · '
                'disponible ${formatSigned(estado.availableMinutes)}',
                key: const Key('saldo-disponible'),
                style: theme.textTheme.bodyMedium?.copyWith(color: fg),
              ),
            Text(
              switch (resumen.inicioControl) {
                null =>
                  'Todavía no fichaste: el saldo arranca en 0 con tu primera '
                      'fichada.',
                final inicio => 'Control desde el ${formatDate(inicio)}.',
              },
              key: const Key('inicio-control'),
              style: theme.textTheme.bodyMedium?.copyWith(color: fg),
            ),
            if (fuera > 0)
              Text(
                fuera == 1
                    ? '1 movimiento anterior al inicio del control no computa. '
                          'Revisalo.'
                    : '$fuera movimientos anteriores al inicio del control no '
                          'computan. Revisalos.',
                key: const Key('fuera-del-control'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (faltantes > 0)
              Text(
                faltantes == 1
                    ? 'Incluye 1 día hábil sin fichada ni usufructo.'
                    : 'Incluye $faltantes días hábiles sin fichada ni '
                          'usufructo.',
                key: const Key('saldo-faltantes'),
                style: theme.textTheme.bodyMedium?.copyWith(color: fg),
              ),
          ],
        ),
      ),
    );
  }
}

class _Desglose extends StatelessWidget {
  const _Desglose({required this.resumen});

  final ResumenBanco resumen;

  @override
  Widget build(BuildContext context) {
    final b = resumen.estado.current;
    final perdidos = b.lostUsufructMinutes + b.lostAccumulationMinutes;
    final items = [
      ('afavor', 'A favor (fichadas)', formatSigned(b.creditMinutes)),
      ('acumulaciones', 'Acumulaciones', formatSigned(b.accumulationMinutes)),
      ('deuda', 'Deuda no cubierta', formatSigned(-b.uncoveredDebtMinutes)),
      (
        'usufructos',
        'Usufructos vigentes',
        formatSigned(-b.activeUsufructMinutes),
      ),
      (
        'perdidos',
        'Perdidos (no computan)',
        perdidos == 0
            ? '0:00'
            : 'usufructos ${formatMinutes(b.lostUsufructMinutes)} · '
                  'acumulaciones ${formatMinutes(b.lostAccumulationMinutes)}',
      ),
    ];
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text('Desglose', style: theme.textTheme.titleSmall),
            ),
            for (final (key, label, value) in items)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(label)),
                    Flexible(
                      child: Text(
                        value,
                        key: Key('desglose-$key'),
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({
    required this.anios,
    required this.anio,
    required this.mes,
    required this.variacion,
    required this.onAnio,
    required this.onMes,
  });

  final List<int> anios;
  final int anio;
  final int? mes;
  final int? variacion;
  final ValueChanged<int> onAnio;
  final ValueChanged<int?> onMes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = variacion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Movimientos', style: theme.textTheme.titleMedium),
            DropdownButton<int>(
              key: const Key('filtro-anio'),
              value: anio,
              items: [
                for (final a in anios)
                  DropdownMenuItem(value: a, child: Text('$a')),
              ],
              onChanged: (a) {
                if (a != null) onAnio(a);
              },
            ),
            DropdownButton<int?>(
              key: const Key('filtro-mes'),
              value: mes,
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Todos los meses'),
                ),
                for (var m = 1; m <= 12; m++)
                  DropdownMenuItem<int?>(
                    value: m,
                    child: Text(_capitalizar(nombreMes(m))),
                  ),
              ],
              onChanged: onMes,
            ),
          ],
        ),
        if (v != null && mes != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Variación del banco en ${nombreMes(mes!)} $anio: '
              '${formatSigned(v)}',
              key: const Key('variacion-mes'),
            ),
          ),
      ],
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.sinMovimientos, required this.anio, this.mes});

  final bool sinMovimientos;
  final int anio;
  final int? mes;

  @override
  Widget build(BuildContext context) {
    final periodo = mes == null ? '$anio' : '${nombreMes(mes!)} $anio';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 48),
          const SizedBox(height: 12),
          Text(
            sinMovimientos
                ? 'Todavía no cargaste acumulaciones ni usufructos. El a favor '
                      'y la deuda de cada día salen solos de las fichadas.'
                : 'No hay movimientos en $periodo.',
            key: const Key('sin-movimientos'),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MovimientoTile extends StatelessWidget {
  const _MovimientoTile({
    required this.movimiento,
    required this.codigo,
    required this.fueraDelControl,
    required this.onTap,
  });

  final LocalMovimiento movimiento;
  final String? codigo;

  /// No computa por el inicio del control: queda para revisar.
  final bool fueraDelControl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = movimiento;
    final theme = Theme.of(context);
    final documento = [?codigo, ?m.numeroGde].join(' · ');
    final detalles = [
      '${_capitalizar(nombreDiaSemana(m.date))} ${formatDate(m.date)}',
      if (fueraDelControl)
        'No computa: es anterior al inicio del control. Revisalo.',
      if (m.perdido) 'Perdido: no computa',
      if (documento.isNotEmpty) documento,
      if (m.tieneAdjunto) m.adjuntoEsPdf ? 'Adjunto PDF' : 'Adjunto imagen',
      if (m.observacion != null) m.observacion!,
      if (m.syncStatus == SyncStatus.error && m.syncError != null) m.syncError!,
    ];
    return ListTile(
      key: Key('movimiento-${m.id}'),
      onTap: onTap,
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      leading: Icon(
        m.kind.esUsufructo
            ? Icons.remove_circle_outline
            : Icons.add_circle_outline,
        color: m.perdido || fueraDelControl ? theme.disabledColor : null,
      ),
      title: Text(
        '${m.kind.label} ${_minutosConSigno(m)}',
        style: theme.textTheme.titleMedium?.copyWith(
          decoration: m.perdido || fueraDelControl
              ? TextDecoration.lineThrough
              : null,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      subtitle: Text(detalles.join('\n')),
      isThreeLine: detalles.length > 1,
      trailing: SyncStatusIcon(status: m.syncStatus, error: m.syncError),
    );
  }
}

class _Tabla extends ConsumerWidget {
  const _Tabla({
    required this.resumen,
    required this.movimientos,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
    required this.onEditar,
  });

  final ResumenBanco resumen;
  final List<LocalMovimiento> movimientos;
  final int sortColumn;
  final bool sortAscending;
  final void Function(int column, bool ascending) onSort;
  final ValueChanged<LocalMovimiento> onEditar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int cmp(LocalMovimiento a, LocalMovimiento b) => switch (sortColumn) {
      1 => a.kind.index.compareTo(b.kind.index),
      2 => (a.kind.esUsufructo ? -a.minutos : a.minutos).compareTo(
        b.kind.esUsufructo ? -b.minutos : b.minutos,
      ),
      _ => a.fecha.compareTo(b.fecha),
    };
    final filas = [...movimientos]
      ..sort((a, b) => sortAscending ? cmp(a, b) : cmp(b, a));
    DataColumn sortable(String label, {bool numeric = false}) =>
        DataColumn(label: Text(label), numeric: numeric, onSort: onSort);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        key: const Key('tabla-movimientos'),
        sortColumnIndex: sortColumn,
        sortAscending: sortAscending,
        headingRowHeight: 44,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 56,
        columnSpacing: 16,
        horizontalMargin: 16,
        columns: [
          sortable('Fecha'),
          sortable('Tipo'),
          sortable('Horas', numeric: true),
          const DataColumn(label: Text('Estado')),
          const DataColumn(label: Text('Respaldo GDE')),
          const DataColumn(label: Text('Adjunto')),
          const DataColumn(label: Text('Observación')),
          const DataColumn(label: Text('Sync')),
          const DataColumn(label: Text('Acciones')),
        ],
        rows: [
          for (final m in filas)
            DataRow(
              key: ValueKey('fila-${m.id}'),
              cells: [
                DataCell(
                  Text(
                    '${nombreDiaSemana(m.date).substring(0, 3)} '
                    '${formatDate(m.date)}',
                  ),
                  onTap: () => onEditar(m),
                ),
                DataCell(Text(m.kind.label), onTap: () => onEditar(m)),
                DataCell(
                  Text(
                    _minutosConSigno(m),
                    style: TextStyle(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      decoration: m.perdido ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  onTap: () => onEditar(m),
                ),
                DataCell(
                  Tooltip(
                    message: estadoLabel(m),
                    child: Text(
                      resumen.fueraDelControl(m)
                          ? 'No computa'
                          : m.perdido
                          ? 'Perdido'
                          : 'Vigente',
                    ),
                  ),
                ),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      [
                        ?resumen.codigoTipo(m.tipoDocumentoId),
                        ?m.numeroGde,
                      ].join(' · ').ifEmpty('—'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  m.tieneAdjunto
                      ? Icon(
                          m.adjuntoEsPdf
                              ? Icons.picture_as_pdf_outlined
                              : Icons.image_outlined,
                          semanticLabel: m.adjuntoEsPdf
                              ? 'Adjunto PDF'
                              : 'Adjunto imagen',
                        )
                      : const Text('—'),
                ),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      m.observacion ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SyncStatusIcon(status: m.syncStatus, error: m.syncError),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Editar',
                        onPressed: () => onEditar(m),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: m.perdido
                            ? 'Volver a vigente'
                            : 'Marcar como perdido',
                        onPressed: () => cambiarPerdido(
                          context,
                          ref,
                          m,
                          perdido: !m.perdido,
                        ),
                        icon: Icon(
                          m.perdido ? Icons.restore : Icons.block_outlined,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Borrar',
                        onPressed: () => borrarMovimiento(context, ref, m),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
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
              'No se pudo leer el banco de horas guardado en el dispositivo.',
              key: Key('error-banco'),
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
