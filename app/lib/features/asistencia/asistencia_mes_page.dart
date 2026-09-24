import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/format/formatters.dart';
import '../../data/fichadas/fichada_validation.dart';
import '../../data/fichadas/fichadas_repository.dart';
import '../../data/local/app_database.dart';
import '../../data/providers.dart';
import '../../data/sync/sync_controller.dart';
import '../../domain/domain.dart';
import '../banco_horas/resumen_banco.dart' show formatSigned;
import '../shell/app_shell.dart';
import 'asistencia_mes_providers.dart';
import 'asistencia_providers.dart';
import 'widgets/foto_tramo_dialog.dart';
import 'widgets/sync_indicator.dart';
import 'widgets/sync_status_icon.dart';
import 'widgets/tramo_editor.dart';

String _capitalizar(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

String _periodo(int anio, int mes) => '${nombreMes(mes)} $anio';

/// `lun 21/09`.
String _fechaCorta(CalendarDate d) =>
    '${nombreDiaSemana(d).substring(0, 3)} '
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

/// Texto del estado del día (un solo estado por día).
String etiquetaEstado(DiaAsistencia d) => switch (d.estado) {
  DayStatus.worked => 'Trabajado',
  DayStatus.open => 'Abierto',
  DayStatus.invalid => 'Horas inválidas',
  DayStatus.conflict => 'Conflicto',
  DayStatus.usufruct => 'Usufructo',
  DayStatus.missing => 'Faltante',
  DayStatus.nonWorkingDay => _etiquetaNoLaborable(d.noLaborable),
  DayStatus.nonWorkingDayRecords =>
    '${_etiquetaNoLaborable(d.noLaborable)} con fichadas',
  DayStatus.future => 'Futuro',
  DayStatus.today => 'Hoy',
  DayStatus.beforeControl => 'Antes del control',
};

String _etiquetaNoLaborable(NonWorkingDay? n) {
  final h = n?.holiday;
  if (h == null) return 'Fin de semana';
  final tipo = h.kind == HolidayKind.nonWorking ? 'No laborable' : 'Feriado';
  return h.name.isEmpty ? tipo : '$tipo: ${h.name}';
}

/// Por qué el día queda para revisar (vacío si no hay que revisarlo).
List<String> motivosRevision(DiaAsistencia d) => [
  if (d.estado == DayStatus.conflict) 'Hay tramos superpuestos: no computan.',
  if (d.estado == DayStatus.invalid)
    'Hay un tramo con el egreso anterior al ingreso.',
  if (d.estado == DayStatus.nonWorkingDayRecords)
    'Fichadas en un día no laborable: no computan. Las horas de ese día se '
        'cargan como acumulación.',
  if (d.estado == DayStatus.open && d.fecha.isBefore(d.hoy))
    'Tramo sin egreso: no computa y bloquea las fichadas siguientes.',
  if (d.dia.fullUsufructMismatch)
    'El usufructo total no es igual a la jornada del día.',
  if (d.dia.outsideControlMovements.isNotEmpty)
    'Movimiento del banco anterior al inicio del control: no computa.',
  if (d.estado == DayStatus.missing && d.dia.coveredDebtMinutes > 0)
    'Día sin fichada cubierto solo en parte por un usufructo.',
];

/// Qué pasa si se borra la primera fichada (para la confirmación).
String textoCambioInicio(CambioInicioControl c) {
  final movs = c.movimientosQueDejanDeComputar;
  final nuevo = c.nuevo;
  final inicio = nuevo == null
      ? 'No quedan fichadas: el control vuelve a cero y empieza con la '
            'próxima. Ningún movimiento del banco computa hasta entonces.'
      : 'Es la primera fichada: el inicio del control pasa del '
            '${formatDate(c.anterior)} al ${formatDate(nuevo)}. Los días sin '
            'fichada de ese período dejan de ser faltantes.';
  final detalle = switch (movs) {
    0 => '',
    1 when nuevo == null => ' 1 movimiento del banco deja de computar.',
    1 => ' 1 movimiento del banco de ese período deja de computar.',
    _ when nuevo == null => ' $movs movimientos del banco dejan de computar.',
    _ => ' $movs movimientos del banco de ese período dejan de computar.',
  };
  return '$inicio$detalle Quedan registrados para revisar.';
}

String _minOGuion(int? m) => m == null || m == 0 ? '—' : formatMinutes(m);

/// Qué se está editando en línea: un tramo ([tramoId]) o uno nuevo en
/// [fecha] ([tramoId] `null`).
typedef _Edicion = ({CalendarDate fecha, String? tramoId});

/// Asistencia: todos los días de un mes (año + mes) con sus tramos, el
/// resumen de `buildMonthlySummary`, filtros y edición en línea. En la PC
/// (≥ 1024) es una tabla densa; en el celular y la tablet, una lista de
/// días.
class AsistenciaMesPage extends ConsumerStatefulWidget {
  const AsistenciaMesPage({super.key});

  @override
  ConsumerState<AsistenciaMesPage> createState() => _AsistenciaMesPageState();
}

class _AsistenciaMesPageState extends ConsumerState<AsistenciaMesPage> {
  // Estado local de la pantalla: qué se edita en línea.
  _Edicion? _edicion;
  final _editorKey = GlobalKey();

  MesAsistencia get _mes => ref.read(mesAsistenciaProvider.notifier);

  void _cambiarMes(void Function() cambio) {
    setState(() => _edicion = null);
    cambio();
  }

  /// Los atajos de mes no hacen nada mientras se edita un tramo (no se
  /// pierde lo escrito).
  void _atajoMes(void Function() cambio) {
    if (_edicion == null) _cambiarMes(cambio);
  }

  void _editar(_Edicion? e) {
    setState(() => _edicion = e);
    if (e == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _editorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.3,
          duration: const Duration(milliseconds: 200),
        );
      }
    });
  }

  void _avisar(String texto) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating),
  );

  /// Guarda lo del editor. Devuelve el motivo si no se pudo.
  Future<String?> _guardar(
    CalendarDate fecha,
    LocalFichada? tramo,
    int ingreso,
    int? egreso,
  ) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return 'No hay sesión.';
    final repo = ref.read(fichadasRepositoryProvider);
    try {
      final LocalFichada saved;
      if (tramo == null) {
        saved = await repo.agregarTramo(
          userId: userId,
          date: fecha,
          ingresoMin: ingreso,
          egresoMin: egreso!,
        );
      } else {
        saved = await repo.editarTramo(
          userId: userId,
          id: tramo.id,
          ingresoMin: ingreso,
          egresoMin: egreso,
        );
      }
      unawaited(ref.read(syncControllerProvider.notifier).syncNow());
      if (!mounted) return null;
      setState(() => _edicion = null);
      final que = tramo == null
          ? 'Tramo agregado'
          : tramo.egresoMin == null && saved.egresoMin != null
          ? 'Tramo cerrado'
          : 'Tramo corregido';
      _avisar(
        '$que: ${formatDate(fecha)} '
        '${describirTramo(saved.ingresoMin, saved.egresoMin)}.',
      );
      return null;
    } on FichadaInvalidaException catch (e) {
      return e.message;
    } catch (e) {
      return 'No se pudo guardar: $e';
    }
  }

  Future<void> _borrar(LocalFichada t) async {
    final fecha = parseIsoDate(t.fecha);
    final tramo = describirTramo(t.ingresoMin, t.egresoMin);
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final repo = ref.read(fichadasRepositoryProvider);
    final CambioInicioControl? cambio;
    try {
      cambio = await repo.impactoBorrado(userId: userId, id: t.id);
    } on FichadaInvalidaException catch (e) {
      if (mounted) _avisar(e.message);
      return;
    }
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          cambio == null ? 'Borrar tramo' : 'Borrar la primera fichada',
        ),
        content: Text(
          '¿Querés borrar el tramo $tramo del ${formatDate(fecha)}? '
          'Deja de computar en el día y en el banco.'
          '${cambio == null ? '' : '\n\n${textoCambioInicio(cambio)}'}',
          key: const Key('texto-borrar-tramo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirmar-borrar-tramo'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await repo.borrarTramo(
        userId: userId,
        id: t.id,
        confirmarCambioInicio: cambio != null,
      );
      unawaited(ref.read(syncControllerProvider.notifier).syncNow());
      if (!mounted) return;
      if (_edicion?.tramoId == t.id) setState(() => _edicion = null);
      _avisar('Tramo $tramo del ${formatDate(fecha)} borrado.');
    } on FichadaInvalidaException catch (e) {
      if (mounted) _avisar(e.message);
    } catch (e) {
      if (mounted) _avisar('No se pudo borrar: $e');
    }
  }

  /// Ctrl+N: elegir un día pasado y laborable del mes y agregarle un tramo.
  Future<void> _nuevoTramo() async {
    final m = ref.read(asistenciaMesProvider).value;
    if (m == null) return;
    final fechas = m.fechasAdmitenAlta;
    if (fechas.isEmpty) {
      _avisar(
        'En ${_periodo(m.anio, m.mes)} no hay días pasados laborables para '
        'agregar tramos.',
      );
      return;
    }
    DateTime dt(CalendarDate d) => DateTime(d.year, d.month, d.day);
    final permitidas = fechas.toSet();
    final elegida = await showDatePicker(
      context: context,
      helpText: 'Día del tramo',
      cancelText: 'Cancelar',
      confirmText: 'Elegir',
      initialDate: dt(fechas.last),
      firstDate: dt(fechas.first),
      lastDate: dt(fechas.last),
      selectableDayPredicate: (d) =>
          permitidas.contains(CalendarDate.fromDateTime(d)),
    );
    if (elegida == null || !mounted) return;
    _editar((fecha: CalendarDate.fromDateTime(elegida), tramoId: null));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(asistenciaMesProvider);
    final sel = ref.watch(mesAsistenciaProvider);
    final desktop = MediaQuery.sizeOf(context).width >= Breakpoints.desktop;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): () =>
            _atajoMes(_mes.anterior),
        const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): () =>
            _atajoMes(_mes.siguiente),
        const SingleActivator(LogicalKeyboardKey.home, alt: true): () =>
            _atajoMes(_mes.actual),
        const SingleActivator(LogicalKeyboardKey.keyN, control: true):
            _nuevoTramo,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Asistencia'),
            actions: const [SyncIndicator()],
          ),
          body: SafeArea(
            child: switch (async) {
              AsyncData(:final value) => _contenido(value, desktop),
              AsyncError(:final error) => _Error(
                error: error,
                onRetry: () => ref.invalidate(misFichadasProvider),
              ),
              _ => Center(
                child: CircularProgressIndicator(
                  semanticsLabel:
                      'Cargando la asistencia de ${_periodo(sel.anio, sel.mes)}',
                ),
              ),
            },
          ),
        ),
      ),
    );
  }

  Widget _contenido(AsistenciaMes m, bool desktop) {
    final filtro = ref.watch(filtroAsistenciaSelProvider);
    final edicion = _edicion;
    // El día que se está editando se ve aunque el filtro lo oculte.
    final dias = [
      for (final d in m.dias)
        if (d.cumple(filtro) || d.fecha == edicion?.fecha) d,
    ];

    Widget tramos(DiaAsistencia d) => _TramosDelDia(
      dia: d,
      feriados: m.feriados,
      edicion: edicion?.fecha == d.fecha ? edicion : null,
      editorKey: _editorKey,
      dense: desktop,
      onEditar: (t) => _editar((fecha: d.fecha, tramoId: t?.id)),
      onCancelar: () => _editar(null),
      onGuardar: (t, i, e) => _guardar(d.fecha, t, i, e),
      onBorrar: _borrar,
      reloj: ref.read(clockProvider),
    );

    final encabezado = _SelectorMes(
      anio: m.anio,
      mes: m.mes,
      esMesActual: m.esMesActual,
      onAnterior: () => _cambiarMes(_mes.anterior),
      onSiguiente: () => _cambiarMes(_mes.siguiente),
      onActual: () => _cambiarMes(_mes.actual),
      onAgregar: _nuevoTramo,
      desktop: desktop,
    );
    final filtros = _Filtros(
      mes: m,
      filtro: filtro,
      onFiltro: ref.read(filtroAsistenciaSelProvider.notifier).set,
    );
    final vacio = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.event_available_outlined, size: 48),
          const SizedBox(height: 12),
          Text(
            switch (filtro) {
              FiltroAsistencia.todos => 'No hay días para mostrar.',
              FiltroAsistencia.revisar =>
                'No hay días para revisar en ${_periodo(m.anio, m.mes)}.',
              FiltroAsistencia.faltantes =>
                'No hay días faltantes en ${_periodo(m.anio, m.mes)}.',
              FiltroAsistencia.editados =>
                'No hay tramos editados en ${_periodo(m.anio, m.mes)}.',
              FiltroAsistencia.manuales =>
                'No hay tramos cargados a mano en ${_periodo(m.anio, m.mes)}.',
            },
            key: const Key('sin-dias'),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
    final avisos = [
      if (m.inicioControl == null)
        const _Aviso(
          key: Key('aviso-sin-control'),
          icono: Icons.info_outline,
          texto:
              'Todavía no hay fichadas. El control empieza con la primera: '
              'los días anteriores no son faltantes.',
        )
      else if (m.inicioControl!.year == m.anio &&
          m.inicioControl!.month == m.mes)
        _Aviso(
          key: const Key('aviso-inicio-control'),
          icono: Icons.flag_outlined,
          texto:
              'El control empezó el ${formatDate(m.inicioControl!)}. Los '
              'días anteriores no son faltantes y no se les agregan '
              'tramos.',
        ),
    ];

    if (desktop) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          encabezado,
          const SizedBox(height: 8),
          _ResumenMes(mes: m),
          ...avisos,
          const SizedBox(height: 12),
          filtros,
          const SizedBox(height: 8),
          if (dias.isEmpty)
            vacio
          else
            _TablaMes(dias: dias, tramos: tramos, editando: edicion?.fecha),
        ],
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
          children: [
            encabezado,
            _ResumenMes(mes: m),
            ...avisos,
            const SizedBox(height: 8),
            filtros,
            const SizedBox(height: 4),
            if (dias.isEmpty)
              vacio
            else
              for (final d in dias) _DiaCard(dia: d, tramos: tramos(d)),
          ],
        ),
      ),
    );
  }
}

class _SelectorMes extends StatelessWidget {
  const _SelectorMes({
    required this.anio,
    required this.mes,
    required this.esMesActual,
    required this.onAnterior,
    required this.onSiguiente,
    required this.onActual,
    required this.onAgregar,
    required this.desktop,
  });

  final int anio;
  final int mes;
  final bool esMesActual;
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;
  final VoidCallback onActual;
  final VoidCallback onAgregar;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titulo = Text(
      _capitalizar(_periodo(anio, mes)),
      key: const Key('mes-titulo'),
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleLarge,
    );
    final navegacion = [
      IconButton(
        key: const Key('mes-anterior'),
        tooltip: 'Mes anterior (Alt+←)',
        onPressed: onAnterior,
        icon: const Icon(Icons.chevron_left),
      ),
      if (desktop)
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 180),
          child: titulo,
        )
      else
        Expanded(child: titulo),
      IconButton(
        key: const Key('mes-siguiente'),
        tooltip: 'Mes siguiente (Alt+→)',
        onPressed: onSiguiente,
        icon: const Icon(Icons.chevron_right),
      ),
      if (!esMesActual)
        TextButton(
          key: const Key('mes-actual'),
          onPressed: onActual,
          child: Text(desktop ? 'Mes actual (Alt+Inicio)' : 'Hoy'),
        ),
    ];
    final agregar = OutlinedButton.icon(
      key: const Key('agregar-tramo'),
      onPressed: onAgregar,
      icon: const Icon(Icons.add),
      label: Text(desktop ? 'Agregar tramo (Ctrl+N)' : 'Agregar tramo'),
    );
    if (desktop) {
      return Row(children: [...navegacion, const Spacer(), agregar]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: navegacion),
        Align(alignment: Alignment.centerRight, child: agregar),
      ],
    );
  }
}

class _ResumenMes extends StatelessWidget {
  const _ResumenMes({required this.mes});

  final AsistenciaMes mes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = mes.resumen;
    final revisar = mes.paraRevisarCount;
    final items = <(String, String, String, bool)>[
      ('habiles', 'Días hábiles', '${s.businessDayCount}', false),
      ('trabajado', 'Trabajado', formatMinutes(s.workedMinutes), false),
      ('deuda', 'Deuda total', formatMinutes(s.debtMinutes), false),
      (
        'deuda-no-cubierta',
        'Deuda no cubierta',
        formatMinutes(s.uncoveredDebtMinutes),
        s.uncoveredDebtMinutes > 0,
      ),
      ('afavor', 'A favor', formatMinutes(s.creditMinutes), false),
      (
        'usufructos',
        'Usufructos',
        formatMinutes(s.activeUsufructMinutes),
        false,
      ),
      (
        'acumulaciones',
        'Acumulaciones',
        formatMinutes(s.accumulationMinutes),
        false,
      ),
      (
        'variacion',
        'Variación del saldo',
        formatSigned(s.bankDeltaMinutes),
        s.bankDeltaMinutes < 0,
      ),
      (
        'faltantes',
        'Faltantes',
        '${s.missingDays.length}',
        s.missingDays.isNotEmpty,
      ),
      ('abiertos', 'Días abiertos', '${s.openDays.length}', false),
      (
        'conflictos',
        'Conflictos',
        '${s.conflictDays.length}',
        s.conflictDays.isNotEmpty,
      ),
      ('revisar', 'Para revisar', '$revisar', revisar > 0),
    ];
    final ultimo = CalendarDate(
      mes.anio,
      mes.mes,
      CalendarDate.daysInMonth(mes.anio, mes.mes),
    );
    final primero = CalendarDate(mes.anio, mes.mes, 1);
    final nota = primero.isAfter(mes.hoy)
        ? 'Este mes todavía no empezó: no mueve el banco.'
        : !ultimo.isBefore(mes.hoy)
        ? 'Banco hasta hoy (${formatDate(mes.hoy)}): la deuda de hoy no resta '
              'hasta que termine el día y lo cargado a futuro todavía no '
              'computa.'
        : null;

    return Card(
      key: const Key('resumen-mes'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen del mes', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, c) {
                // Al menos 3 por fila (en el celular entran en 4 filas).
                final cols = ((c.maxWidth + 8) ~/ 148).clamp(3, 12);
                final ancho = (c.maxWidth - 8 * (cols - 1)) / cols;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (key, label, value, alerta) in items)
                      _Metrica(
                        clave: key,
                        label: label,
                        value: value,
                        alerta: alerta,
                        ancho: ancho,
                      ),
                  ],
                );
              },
            ),
            if (nota != null) ...[
              const SizedBox(height: 8),
              Text(
                nota,
                key: const Key('resumen-nota'),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metrica extends StatelessWidget {
  const _Metrica({
    required this.clave,
    required this.label,
    required this.value,
    required this.alerta,
    required this.ancho,
  });

  final String clave;
  final String label;
  final String value;
  final bool alerta;
  final double ancho;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: ancho,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: alerta ? scheme.errorContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Semantics(
        label: '$label: $value',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: alerta
                    ? scheme.onErrorContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              key: Key('resumen-$clave'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: alerta ? scheme.onErrorContainer : scheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
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
    required this.mes,
    required this.filtro,
    required this.onFiltro,
  });

  final AsistenciaMes mes;
  final FiltroAsistencia filtro;
  final ValueChanged<FiltroAsistencia> onFiltro;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final f in FiltroAsistencia.values)
          ChoiceChip(
            key: Key('filtro-${f.name}'),
            label: Text(
              f == FiltroAsistencia.todos
                  ? f.label
                  : '${f.label} (${mes.filtrar(f).length})',
            ),
            selected: filtro == f,
            onSelected: (_) => onFiltro(f),
          ),
      ],
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({super.key, required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icono, color: scheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                texto,
                style: TextStyle(color: scheme.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Colores de una fila/tarjeta según el día.
({Color? fondo, Color? texto, Border? borde}) _estiloDia(
  BuildContext context,
  DiaAsistencia d,
) {
  final scheme = Theme.of(context).colorScheme;
  final borde = d.esHoy ? Border.all(color: scheme.primary, width: 2) : null;
  if (d.paraRevisar) {
    return (
      fondo: scheme.errorContainer,
      texto: scheme.onErrorContainer,
      borde: borde,
    );
  }
  if (d.noLaborable != null) {
    return (fondo: scheme.surfaceContainerHighest, texto: null, borde: borde);
  }
  if (d.esFuturo || d.estado == DayStatus.beforeControl) {
    return (fondo: null, texto: scheme.onSurfaceVariant, borde: borde);
  }
  return (fondo: null, texto: null, borde: borde);
}

class _EstadoDia extends StatelessWidget {
  const _EstadoDia({required this.dia, this.color});

  final DiaAsistencia dia;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final motivos = motivosRevision(dia);
    final (IconData icono, Color? iconColor) = switch (dia.estado) {
      _ when dia.paraRevisar => (Icons.warning_amber, color),
      DayStatus.worked => (Icons.check_circle_outline, scheme.primary),
      DayStatus.open => (Icons.timelapse, color ?? scheme.tertiary),
      DayStatus.missing => (Icons.event_busy, scheme.error),
      DayStatus.usufruct => (Icons.beach_access_outlined, color),
      DayStatus.nonWorkingDay => (Icons.weekend_outlined, color),
      DayStatus.today => (Icons.today, scheme.primary),
      _ => (Icons.remove, color),
    };
    final texto = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 18, color: iconColor),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            etiquetaEstado(dia),
            key: Key('estado-${dia.fecha}'),
            style: TextStyle(
              color: dia.estado == DayStatus.missing && !dia.paraRevisar
                  ? scheme.error
                  : color,
              fontWeight: dia.paraRevisar || dia.faltante
                  ? FontWeight.w600
                  : null,
            ),
          ),
        ),
        if (dia.esHoy && dia.estado != DayStatus.today) ...[
          const SizedBox(width: 6),
          Text(
            '· hoy',
            key: Key('hoy-${dia.fecha}'),
            style: TextStyle(color: color ?? scheme.primary),
          ),
        ],
      ],
    );
    if (motivos.isEmpty) return texto;
    return Tooltip(message: motivos.join('\n'), child: texto);
  }
}

class _TablaMes extends StatelessWidget {
  const _TablaMes({
    required this.dias,
    required this.tramos,
    required this.editando,
  });

  final List<DiaAsistencia> dias;
  final Widget Function(DiaAsistencia) tramos;
  final CalendarDate? editando;

  static const _anchoMinimo = 1040.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final encabezado = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    Widget cab(String t, double w, {bool num = false}) => SizedBox(
      width: w,
      child: Text(t, style: encabezado, textAlign: num ? TextAlign.end : null),
    );

    return LayoutBuilder(
      builder: (context, c) {
        final ancho = c.maxWidth < _anchoMinimo ? _anchoMinimo : c.maxWidth;
        final tabla = SizedBox(
          width: ancho,
          child: Column(
            key: const Key('tabla-asistencia'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    cab('Fecha', _Col.fecha),
                    cab('Día', _Col.dia),
                    Expanded(child: Text('Tramos', style: encabezado)),
                    cab('Trabajado', _Col.horas, num: true),
                    cab('Jornada', _Col.horas, num: true),
                    cab('Deuda', _Col.deuda, num: true),
                    cab('A favor', _Col.horas, num: true),
                    const SizedBox(width: 16),
                    cab('Estado', _Col.estado),
                  ],
                ),
              ),
              const Divider(height: 1),
              for (final d in dias)
                _FilaDia(
                  key: ValueKey('fila-${d.fecha}'),
                  dia: d,
                  tramos: tramos(d),
                ),
            ],
          ),
        );
        if (ancho == c.maxWidth) return tabla;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: tabla,
        );
      },
    );
  }
}

abstract final class _Col {
  static const fecha = 96.0;
  static const dia = 88.0;
  static const horas = 80.0;
  static const deuda = 120.0;
  static const estado = 220.0;
}

/// Deuda del día: la que resta, la cubierta por usufructo y la provisoria
/// de hoy (que no resta).
class _Deuda extends StatelessWidget {
  const _Deuda({required this.dia, this.color});

  final DiaAsistencia dia;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final d = dia.dia;
    final style = TextStyle(
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    if (d.provisionalDebtMinutes > 0) {
      return Tooltip(
        message:
            'Provisoria: la deuda de hoy no resta hasta que termine el día.',
        child: Text(
          '(${formatMinutes(d.provisionalDebtMinutes)})',
          key: Key('deuda-${d.date}'),
          textAlign: TextAlign.end,
          style: style.copyWith(fontStyle: FontStyle.italic),
        ),
      );
    }
    final texto = Text(
      d.coveredDebtMinutes > 0
          ? '${formatMinutes(d.debtMinutes)} (cubre ${formatMinutes(d.coveredDebtMinutes)})'
          : _minOGuion(d.debtMinutes),
      key: Key('deuda-${d.date}'),
      textAlign: TextAlign.end,
      style: style,
    );
    if (d.coveredDebtMinutes == 0) return texto;
    return Tooltip(
      message:
          'Deuda ${formatMinutes(d.debtMinutes)}, cubierta por usufructo '
          '${formatMinutes(d.coveredDebtMinutes)}: resta '
          '${formatMinutes(d.uncoveredDebtMinutes)}.',
      child: texto,
    );
  }
}

class _FilaDia extends StatelessWidget {
  const _FilaDia({super.key, required this.dia, required this.tramos});

  final DiaAsistencia dia;
  final Widget tramos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estilo = _estiloDia(context, dia);
    final d = dia.dia;
    final num = TextStyle(
      color: estilo.texto,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    Widget celda(double w, String t, {Key? key}) => SizedBox(
      width: w,
      child: Text(t, key: key, textAlign: TextAlign.end, style: num),
    );

    return Semantics(
      container: true,
      label: dia.paraRevisar ? 'Día para revisar' : null,
      child: Container(
        decoration: BoxDecoration(
          color: estilo.fondo,
          border:
              estilo.borde ??
              Border(bottom: BorderSide(color: theme.dividerColor)),
        ),
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: estilo.texto),
          child: Row(
            children: [
              SizedBox(
                width: _Col.fecha,
                child: Text(
                  formatDate(dia.fecha),
                  style: num.copyWith(
                    fontWeight: dia.esHoy ? FontWeight.w700 : null,
                  ),
                ),
              ),
              SizedBox(
                width: _Col.dia,
                child: Text(_capitalizar(nombreDiaSemana(dia.fecha))),
              ),
              Expanded(child: tramos),
              celda(
                _Col.horas,
                _minOGuion(d.workedMinutes),
                key: Key('trabajado-${dia.fecha}'),
              ),
              celda(
                _Col.horas,
                d.isBusinessDay ? formatMinutes(d.workdayMinutes) : '—',
              ),
              SizedBox(
                width: _Col.deuda,
                child: _Deuda(dia: dia, color: estilo.texto),
              ),
              celda(
                _Col.horas,
                _minOGuion(d.creditMinutes),
                key: Key('afavor-${dia.fecha}'),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: _Col.estado,
                child: _EstadoDia(dia: dia, color: estilo.texto),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiaCard extends StatelessWidget {
  const _DiaCard({required this.dia, required this.tramos});

  final DiaAsistencia dia;
  final Widget tramos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estilo = _estiloDia(context, dia);
    final d = dia.dia;
    final motivos = motivosRevision(dia);
    final numeros = [
      if (d.workedMinutes != null)
        'Trabajado ${formatMinutes(d.workedMinutes!)}',
      if (d.isBusinessDay) 'Jornada ${formatMinutes(d.workdayMinutes)}',
      if (d.debtMinutes > 0) 'Deuda ${formatMinutes(d.debtMinutes)}',
      if (d.coveredDebtMinutes > 0)
        'cubre ${formatMinutes(d.coveredDebtMinutes)}',
      if (d.provisionalDebtMinutes > 0)
        'faltan ${formatMinutes(d.provisionalDebtMinutes)} (provisorio)',
      if (d.creditMinutes > 0) 'A favor ${formatMinutes(d.creditMinutes)}',
    ];
    return Card(
      key: ValueKey('fila-${dia.fecha}'),
      color: estilo.fondo,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: estilo.borde == null
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: estilo.texto),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _capitalizar(_fechaCorta(dia.fecha)),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: estilo.texto,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _EstadoDia(dia: dia, color: estilo.texto),
                      ),
                    ),
                  ),
                ],
              ),
              if (numeros.isNotEmpty)
                Text(
                  numeros.join(' · '),
                  style: TextStyle(
                    color: estilo.texto,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              for (final m in motivos)
                Text(
                  m,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: estilo.texto,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              tramos,
            ],
          ),
        ),
      ),
    );
  }
}

/// Tramos de un día (cada uno con sus marcas y acciones) y, si se puede,
/// el botón para agregar uno. El que se edita se reemplaza por el editor.
class _TramosDelDia extends StatelessWidget {
  const _TramosDelDia({
    required this.dia,
    required this.feriados,
    required this.edicion,
    required this.editorKey,
    required this.dense,
    required this.onEditar,
    required this.onCancelar,
    required this.onGuardar,
    required this.onBorrar,
    required this.reloj,
  });

  final DiaAsistencia dia;
  final List<Holiday> feriados;
  final DateTime Function() reloj;

  /// Edición en curso en este día, o `null`.
  final _Edicion? edicion;
  final GlobalKey editorKey;
  final bool dense;
  final ValueChanged<LocalFichada?> onEditar;
  final VoidCallback onCancelar;
  final Future<String?> Function(LocalFichada?, int, int?) onGuardar;
  final ValueChanged<LocalFichada> onBorrar;

  @override
  Widget build(BuildContext context) {
    final e = edicion;
    Widget editor(LocalFichada? t) => KeyedSubtree(
      key: editorKey,
      child: TramoEditor(
        key: ValueKey('editor-${dia.fecha}-${t?.id}'),
        fecha: dia.fecha,
        hoy: dia.hoy,
        tramo: t,
        otrosDelDia: dia.tramos,
        feriados: feriados,
        dense: dense,
        inicioControl: dia.inicioControl,
        reloj: reloj,
        onGuardar: (i, eg) => onGuardar(t, i, eg),
        onCancelar: onCancelar,
      ),
    );
    final agregando = e != null && e.tramoId == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final t in dia.tramos)
          if (e?.tramoId == t.id)
            editor(t)
          else
            _TramoLinea(
              tramo: t,
              editable: !dia.esFuturo,
              dense: dense,
              onEditar: () => onEditar(t),
              onBorrar: () => onBorrar(t),
            ),
        if (agregando)
          editor(null)
        else if (dia.admiteAlta)
          TextButton.icon(
            key: Key('agregar-${dia.fecha}'),
            style: dense
                ? TextButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    visualDensity: VisualDensity.compact,
                  )
                : null,
            onPressed: () => onEditar(null),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Tramo'),
          ),
      ],
    );
  }
}

class _TramoLinea extends StatelessWidget {
  const _TramoLinea({
    required this.tramo,
    required this.editable,
    required this.dense,
    required this.onEditar,
    required this.onBorrar,
  });

  final LocalFichada tramo;
  final bool editable;
  final bool dense;
  final VoidCallback onEditar;
  final VoidCallback onBorrar;

  @override
  Widget build(BuildContext context) {
    final t = tramo;
    final theme = Theme.of(context);
    final color = DefaultTextStyle.of(context).style.color;
    final abierto = t.egresoMin == null;
    final iconSize = dense ? 18.0 : 22.0;
    final compact = dense
        ? const BoxConstraints.tightFor(width: 36, height: 36)
        : null;
    final correcciones = [
      if (t.ingresoOriginalMin != null)
        'Ingreso corregido: antes ${formatClock(t.ingresoOriginalMin!)}',
      if (t.egresoOriginalMin != null)
        'Egreso corregido: antes ${formatClock(t.egresoOriginalMin!)}',
    ];

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton(
          key: Key('tramo-${t.id}'),
          style: TextButton.styleFrom(
            foregroundColor: color,
            minimumSize: dense ? const Size(0, 36) : const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            textStyle: theme.textTheme.bodyLarge?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: editable ? onEditar : null,
          child: Text(
            describirTramo(t.ingresoMin, t.egresoMin),
            semanticsLabel:
                'Tramo ${describirTramo(t.ingresoMin, t.egresoMin)}. '
                '${editable ? 'Tocá para editar.' : ''}',
          ),
        ),
        if (t.editado)
          Tooltip(
            message: correcciones.join('\n'),
            child: Semantics(
              label: 'Editado. ${correcciones.join('. ')}',
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.edit_note,
                  key: Key('editado-${t.id}'),
                  size: iconSize,
                  color: color ?? theme.colorScheme.secondary,
                ),
              ),
            ),
          ),
        if (t.origenTipo != OrigenFichada.dispositivo)
          Tooltip(
            message: t.esManual
                ? 'Cargado a mano (sin hora del dispositivo)'
                : 'Importado de la planilla',
            child: Container(
              key: Key('origen-${t.id}'),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                border: Border.all(color: color ?? theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                t.esManual ? 'manual' : 'importado',
                style: theme.textTheme.labelSmall?.copyWith(color: color),
              ),
            ),
          ),
        if (t.tieneFoto)
          IconButton(
            key: Key('foto-${t.id}'),
            tooltip: 'Ver foto del biométrico',
            constraints: compact,
            iconSize: iconSize,
            padding: EdgeInsets.zero,
            onPressed: () => mostrarFotosTramo(context, t),
            icon: Icon(Icons.photo_camera_outlined, color: color),
          ),
        SyncStatusIcon(
          status: t.syncStatus,
          error: t.syncError,
          dimension: dense ? 32 : 48,
        ),
        if (abierto && editable)
          IconButton(
            key: Key('cerrar-${t.id}'),
            tooltip: 'Cerrar tramo (cargar egreso)',
            constraints: compact,
            iconSize: iconSize,
            padding: EdgeInsets.zero,
            onPressed: onEditar,
            icon: Icon(Icons.logout, color: color),
          ),
        IconButton(
          key: Key('borrar-${t.id}'),
          tooltip: 'Borrar tramo',
          constraints: compact,
          iconSize: iconSize,
          padding: EdgeInsets.zero,
          onPressed: onBorrar,
          icon: Icon(Icons.delete_outline, color: color),
        ),
      ],
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
              'No se pudo leer la asistencia guardada en el dispositivo.',
              key: Key('error-asistencia'),
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
