import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/formatters.dart';
import '../../data/cursos/curso.dart';
import '../../data/local/app_database.dart';
import '../../domain/domain.dart';
import '../asistencia/asistencia_providers.dart';
import '../asistencia/widgets/sync_indicator.dart';
import '../asistencia/widgets/sync_status_icon.dart';
import '../shell/app_shell.dart';
import 'curso_acciones.dart';
import 'curso_form_page.dart';
import 'cursos_providers.dart';

/// Valor del selector de año para "Todos los años".
const _todosLosAnios = 0;

/// Período del curso para mostrar: "01/03/2026 – 30/04/2026", "Desde …",
/// "Hasta …" o "Sin fechas".
String periodoCurso(LocalCurso c) {
  final i = c.inicio;
  final f = c.fin;
  if (i != null && f != null) return '${formatDate(i)} – ${formatDate(f)}';
  if (i != null) return 'Desde ${formatDate(i)}';
  if (f != null) return 'Hasta ${formatDate(f)}';
  return 'Sin fechas';
}

String _creditosTexto(int? creditos) => switch (creditos) {
  null => 'Sin créditos',
  1 => '1 crédito',
  final n => '$n créditos',
};

/// Cursos de capacitación: créditos aprobados arriba (por año) y la lista
/// filtrable por estado, año, portal y texto. En el celular son tarjetas; en
/// la PC (≥ 1024), una tabla ordenable con el estado editable en línea.
class CursosPage extends ConsumerStatefulWidget {
  const CursosPage({super.key});

  @override
  ConsumerState<CursosPage> createState() => _CursosPageState();
}

class _CursosPageState extends ConsumerState<CursosPage> {
  // Estado local de la pantalla (filtros y orden de la tabla).
  /// Arranca en [_todosLosAnios] (sin filtrar por año).
  int? _anio = _todosLosAnios;
  CourseStatus? _estado;
  String? _portal;
  final _busqueda = TextEditingController();
  final _busquedaFocus = FocusNode();
  int _sortColumn = 1;
  bool _sortAscending = false;

  @override
  void dispose() {
    _busqueda.dispose();
    _busquedaFocus.dispose();
    super.dispose();
  }

  Future<void> _nuevo() => Navigator.of(context).push<LocalCurso>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const CursoFormPage(),
    ),
  );

  Future<void> _editar(LocalCurso c) => Navigator.of(context).push<LocalCurso>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => CursoFormPage(curso: c),
    ),
  );

  void _buscar() => _busquedaFocus.requestFocus();

  /// Saca los filtros de estado, portal y texto. Con [anio], también el del
  /// año (pasa a "Todos los años").
  void _limpiarFiltros({bool anio = false}) => setState(() {
    if (anio) _anio = _todosLosAnios;
    _estado = null;
    _portal = null;
    _busqueda.clear();
  });

  @override
  Widget build(BuildContext context) {
    final cursos = ref.watch(misCursosProvider);
    final desktop = MediaQuery.sizeOf(context).width >= Breakpoints.desktop;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): _nuevo,
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): _buscar,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Cursos'),
            actions: const [SyncIndicator(), ShellAccountButton()],
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('nuevo-curso'),
            tooltip: desktop ? 'Nuevo curso (Ctrl+N)' : null,
            onPressed: _nuevo,
            icon: const Icon(Icons.add),
            label: const Text('Nuevo curso'),
          ),
          body: SafeArea(
            child: switch (cursos) {
              AsyncData(:final value) => _contenido(value, desktop),
              AsyncError(:final error) => _Error(
                error: error,
                onRetry: () => ref.invalidate(misCursosProvider),
              ),
              _ => const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Cargando los cursos',
                ),
              ),
            },
          ),
        ),
      ),
    );
  }

  Widget _contenido(List<LocalCurso> cursos, bool desktop) {
    final hoy = ref.watch(todayProvider);
    final todos = [for (final c in cursos) c.toCourse()];
    final anios = courseYears(todos, alwaysInclude: hoy.year);
    final anio = _anio == _todosLosAnios || anios.contains(_anio)
        ? _anio!
        : hoy.year;
    final anioFiltro = anio == _todosLosAnios ? null : anio;
    final portales = usedCoursePortals(todos);
    final portal = portales.contains(_portal) ? _portal : null;
    final filtro = CourseFilter(
      status: _estado,
      year: anioFiltro,
      portal: portal,
      query: _busqueda.text,
    );
    final filtrados = filtro.apply(cursos, (c) => c.toCourse());
    // El año no cuenta: siempre hay uno elegido (el actual por defecto).
    final hayFiltros =
        _estado != null || portal != null || _busqueda.text.trim().isNotEmpty;

    final total = _TotalCreditos(
      cursos: todos,
      anio: anioFiltro,
      conAvisos: [
        for (final c in filtrados)
          if (courseWarnings(c.toCourse()).isNotEmpty) c,
      ].length,
    );
    final filtros = _Filtros(
      anios: anios,
      anio: anio,
      estado: _estado,
      portales: portales,
      portal: portal,
      busqueda: _busqueda,
      busquedaFocus: _busquedaFocus,
      desktop: desktop,
      hayFiltros: hayFiltros,
      onAnio: (a) => setState(() => _anio = a),
      onEstado: (e) => setState(() => _estado = e),
      onPortal: (p) => setState(() => _portal = p),
      onBusqueda: () => setState(() {}),
      onLimpiar: _limpiarFiltros,
    );
    final vacio = _Vacio(
      sinCursos: cursos.isEmpty,
      soloAnio: hayFiltros ? null : anioFiltro,
      onVerTodos: () => _limpiarFiltros(anio: true),
    );

    if (desktop) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
        children: [
          total,
          const SizedBox(height: 16),
          filtros,
          const SizedBox(height: 8),
          if (filtrados.isEmpty)
            vacio
          else
            _Tabla(
              cursos: filtrados,
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
              child: total,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: filtros,
            ),
            if (filtrados.isEmpty)
              vacio
            else
              for (final c in filtrados)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: _CursoCard(curso: c, onTap: () => _editar(c)),
                ),
          ],
        ),
      ),
    );
  }
}

class _TotalCreditos extends StatelessWidget {
  const _TotalCreditos({
    required this.cursos,
    required this.anio,
    required this.conAvisos,
  });

  final List<Course> cursos;

  /// `null` = todos los años.
  final int? anio;

  /// Cursos de la lista filtrada con avisos.
  final int conAvisos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = scheme.onPrimaryContainer;
    final total = approvedCredits(cursos, year: anio);
    final aprobados = [
      for (final c in cursos)
        if (c.status == CourseStatus.approved &&
            (anio == null || c.year == anio))
          c,
    ].length;
    final aprobadosSinAnio = anio == null
        ? 0
        : [
            for (final c in cursos)
              if (c.status == CourseStatus.approved && c.year == null) c,
          ].length;

    return Card(
      color: scheme.primaryContainer,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              anio == null
                  ? 'Créditos aprobados (todos los años)'
                  : 'Créditos aprobados en $anio',
              key: const Key('total-creditos-titulo'),
              style: theme.textTheme.labelLarge?.copyWith(color: fg),
            ),
            Semantics(
              label: '$total créditos aprobados',
              excludeSemantics: true,
              child: Text(
                '$total',
                key: const Key('total-creditos'),
                style: theme.textTheme.displayMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Text(
              aprobados == 1
                  ? '1 curso aprobado'
                  : '$aprobados cursos aprobados',
              key: const Key('cursos-aprobados'),
              style: theme.textTheme.bodyMedium?.copyWith(color: fg),
            ),
            if (aprobadosSinAnio > 0)
              Text(
                aprobadosSinAnio == 1
                    ? '1 curso aprobado sin fechas no suma a ningún año: '
                          'cargale la fecha de fin.'
                    : '$aprobadosSinAnio cursos aprobados sin fechas no suman '
                          'a ningún año: cargales la fecha de fin.',
                key: const Key('aprobados-sin-anio'),
                style: theme.textTheme.bodyMedium?.copyWith(color: fg),
              ),
            if (conAvisos > 0)
              Text(
                conAvisos == 1
                    ? '1 curso aprobado sin certificado o sin IF.'
                    : '$conAvisos cursos aprobados sin certificado o sin IF.',
                key: const Key('resumen-avisos'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
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
    required this.estado,
    required this.portales,
    required this.portal,
    required this.busqueda,
    required this.busquedaFocus,
    required this.desktop,
    required this.hayFiltros,
    required this.onAnio,
    required this.onEstado,
    required this.onPortal,
    required this.onBusqueda,
    required this.onLimpiar,
  });

  final List<int> anios;

  /// [_todosLosAnios] = todos.
  final int anio;
  final CourseStatus? estado;
  final List<String> portales;
  final String? portal;
  final TextEditingController busqueda;
  final FocusNode busquedaFocus;
  final bool desktop;
  final bool hayFiltros;
  final ValueChanged<int> onAnio;
  final ValueChanged<CourseStatus?> onEstado;
  final ValueChanged<String?> onPortal;
  final VoidCallback onBusqueda;
  final VoidCallback onLimpiar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buscar = TextField(
      key: const Key('buscar-curso'),
      controller: busqueda,
      focusNode: busquedaFocus,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: const Icon(Icons.search),
        labelText: desktop ? 'Buscar (Ctrl+F)' : 'Buscar',
        hintText: 'Actividad o código',
        suffixIcon: busqueda.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Borrar la búsqueda',
                onPressed: () {
                  busqueda.clear();
                  onBusqueda();
                },
                icon: const Icon(Icons.clear),
              ),
      ),
      onChanged: (_) => onBusqueda(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Cursos', style: theme.textTheme.titleMedium),
            DropdownButton<int>(
              key: const Key('filtro-anio'),
              value: anio,
              items: [
                const DropdownMenuItem(
                  value: _todosLosAnios,
                  child: Text('Todos los años'),
                ),
                for (final a in anios)
                  DropdownMenuItem(value: a, child: Text('$a')),
              ],
              onChanged: (a) {
                if (a != null) onAnio(a);
              },
            ),
            DropdownButton<CourseStatus?>(
              key: const Key('filtro-estado'),
              value: estado,
              items: [
                const DropdownMenuItem<CourseStatus?>(
                  value: null,
                  child: Text('Todos los estados'),
                ),
                for (final s in CourseStatus.values)
                  DropdownMenuItem<CourseStatus?>(
                    value: s,
                    child: Text(s.label),
                  ),
              ],
              onChanged: onEstado,
            ),
            if (portales.isNotEmpty)
              DropdownButton<String?>(
                key: const Key('filtro-portal'),
                value: portal,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Todos los portales'),
                  ),
                  for (final p in portales)
                    DropdownMenuItem<String?>(value: p, child: Text(p)),
                ],
                onChanged: onPortal,
              ),
            if (desktop) SizedBox(width: 320, child: buscar),
            if (hayFiltros)
              TextButton.icon(
                key: const Key('limpiar-filtros'),
                onPressed: onLimpiar,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Limpiar filtros'),
              ),
          ],
        ),
        if (!desktop) ...[const SizedBox(height: 8), buscar],
      ],
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({
    required this.sinCursos,
    required this.soloAnio,
    required this.onVerTodos,
  });

  final bool sinCursos;

  /// Año elegido cuando es el único filtro (`null` si hay otros filtros o
  /// son todos los años).
  final int? soloAnio;
  final VoidCallback onVerTodos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.school_outlined, size: 48),
          const SizedBox(height: 12),
          Text(
            sinCursos
                ? 'Todavía no cargaste cursos. Tocá "Nuevo curso" para agregar '
                      'el primero.'
                : soloAnio != null
                ? 'No hay cursos en $soloAnio.'
                : 'Ningún curso coincide con los filtros.',
            key: Key(sinCursos ? 'sin-cursos' : 'sin-resultados'),
            textAlign: TextAlign.center,
          ),
          if (!sinCursos) ...[
            const SizedBox(height: 8),
            TextButton(
              key: const Key('ver-todos'),
              onPressed: onVerTodos,
              child: const Text('Ver todos los cursos'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Estado del curso como etiqueta de color (con texto: no depende solo del
/// color).
class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.estado});

  final CourseStatus estado;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (estado) {
      CourseStatus.approved => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      CourseStatus.inProgress => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      CourseStatus.enrolled => (
        scheme.surfaceContainerHighest,
        scheme.onSurface,
      ),
      CourseStatus.notAccepted || CourseStatus.abandoned => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          estado.label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg),
        ),
      ),
    );
  }
}

/// Avisos no bloqueantes de un curso (aprobado sin certificado o sin IF).
class _AvisosCurso extends StatelessWidget {
  const _AvisosCurso({required this.id, required this.avisos});

  final String id;
  final List<CourseWarning> avisos;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      key: Key('avisos-$id'),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: scheme.onTertiaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                avisos.map((a) => a.label).join(' · '),
                style: TextStyle(color: scheme.onTertiaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Accion { editar, certificado, borrar }

class _CursoCard extends ConsumerWidget {
  const _CursoCard({required this.curso, required this.onTap});

  final LocalCurso curso;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = curso;
    final theme = Theme.of(context);
    final avisos = courseWarnings(c.toCourse());
    final detalle = [?c.codigo, ?c.portal].join(' · ');

    return Card(
      key: Key('curso-${c.id}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 0, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      c.actividad,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  SyncStatusIcon(status: c.syncStatus, error: c.syncError),
                  PopupMenuButton<_Accion>(
                    key: Key('acciones-${c.id}'),
                    tooltip: 'Acciones',
                    onSelected: (a) => switch (a) {
                      _Accion.editar => onTap(),
                      _Accion.certificado => mostrarCertificado(context, c),
                      _Accion.borrar => borrarCurso(context, ref, c),
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: _Accion.editar,
                        child: Text('Editar'),
                      ),
                      if (c.tieneCertificado)
                        const PopupMenuItem(
                          value: _Accion.certificado,
                          child: Text('Ver certificado'),
                        ),
                      const PopupMenuItem(
                        value: _Accion.borrar,
                        child: Text('Borrar'),
                      ),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _EstadoChip(estado: c.status),
                        Text(_creditosTexto(c.creditos)),
                        if (c.tieneCertificado)
                          Icon(
                            c.certificadoEsPdf
                                ? Icons.picture_as_pdf_outlined
                                : Icons.image_outlined,
                            size: 20,
                            semanticLabel: 'Tiene certificado',
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (detalle.isNotEmpty) Text(detalle),
                    Text(periodoCurso(c)),
                    if (c.ifGde != null) Text(c.ifGde!),
                    if (c.syncStatus == SyncStatus.error && c.syncError != null)
                      Text(
                        c.syncError!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    if (avisos.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _AvisosCurso(id: c.id, avisos: avisos),
                    ],
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

class _Tabla extends ConsumerWidget {
  const _Tabla({
    required this.cursos,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
    required this.onEditar,
  });

  final List<LocalCurso> cursos;
  final int sortColumn;
  final bool sortAscending;
  final void Function(int column, bool ascending) onSort;
  final ValueChanged<LocalCurso> onEditar;

  /// Clave de orden del período: la fecha que define el año del curso
  /// (fin, o inicio). Sin fechas va primero en orden ascendente.
  static String _periodoKey(LocalCurso c) => c.fechaFin ?? c.fechaInicio ?? '';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int cmp(LocalCurso a, LocalCurso b) => switch (sortColumn) {
      0 => foldForSearch(a.actividad).compareTo(foldForSearch(b.actividad)),
      2 => (a.creditos ?? -1).compareTo(b.creditos ?? -1),
      3 => a.status.index.compareTo(b.status.index),
      _ => _periodoKey(a).compareTo(_periodoKey(b)),
    };
    final filas = [...cursos]
      ..sort((a, b) => sortAscending ? cmp(a, b) : cmp(b, a));
    DataColumn sortable(String label, {bool numeric = false}) =>
        DataColumn(label: Text(label), numeric: numeric, onSort: onSort);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        key: const Key('tabla-cursos'),
        sortColumnIndex: sortColumn,
        sortAscending: sortAscending,
        headingRowHeight: 44,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 60,
        columnSpacing: 16,
        horizontalMargin: 16,
        columns: [
          sortable('Actividad'),
          sortable('Período'),
          sortable('Créditos', numeric: true),
          sortable('Estado'),
          const DataColumn(label: Text('Respaldo')),
          const DataColumn(label: Text('Acciones')),
        ],
        rows: [for (final c in filas) _fila(context, ref, c)],
      ),
    );
  }

  DataRow _fila(BuildContext context, WidgetRef ref, LocalCurso c) {
    final theme = Theme.of(context);
    final avisos = courseWarnings(c.toCourse());
    final detalle = [?c.codigo, ?c.portal].join(' · ');
    final i = c.inicio;
    final f = c.fin;

    return DataRow(
      key: ValueKey('fila-${c.id}'),
      cells: [
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.actividad, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (detalle.isNotEmpty)
                  Text(
                    detalle,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          onTap: () => onEditar(c),
        ),
        DataCell(
          i == null && f == null
              ? const Text('Sin fechas')
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(i == null ? '—' : formatDate(i)),
                    Text(f == null ? '—' : formatDate(f)),
                  ],
                ),
          onTap: () => onEditar(c),
        ),
        DataCell(
          Text(
            c.creditos?.toString() ?? '—',
            style: const TextStyle(
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          onTap: () => onEditar(c),
        ),
        DataCell(
          DropdownButton<CourseStatus>(
            key: Key('estado-fila-${c.id}'),
            value: c.status,
            isDense: true,
            underline: const SizedBox.shrink(),
            items: [
              for (final s in CourseStatus.values)
                DropdownMenuItem(value: s, child: Text(s.label)),
            ],
            onChanged: (s) {
              if (s != null) cambiarEstadoCurso(context, ref, c, s);
            },
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (c.ifGde != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Tooltip(
                    message: c.ifGde!,
                    child: Text(c.ifGde!, overflow: TextOverflow.ellipsis),
                  ),
                )
              else if (avisos.contains(CourseWarning.approvedWithoutIf))
                const _AvisoCelda(
                  aviso: CourseWarning.approvedWithoutIf,
                  texto: 'Sin IF',
                )
              else
                const Text('Sin IF'),
              const SizedBox(width: 4),
              if (c.tieneCertificado)
                IconButton(
                  tooltip: 'Ver certificado',
                  onPressed: () => mostrarCertificado(context, c),
                  icon: Icon(
                    c.certificadoEsPdf
                        ? Icons.picture_as_pdf_outlined
                        : Icons.image_outlined,
                  ),
                )
              else if (avisos.contains(
                CourseWarning.approvedWithoutCertificate,
              ))
                const _AvisoCelda(
                  aviso: CourseWarning.approvedWithoutCertificate,
                  texto: 'Sin cert.',
                ),
            ],
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SyncStatusIcon(
                status: c.syncStatus,
                error: c.syncError,
                dimension: 36,
              ),
              IconButton(
                tooltip: 'Editar',
                onPressed: () => onEditar(c),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Borrar',
                onPressed: () => borrarCurso(context, ref, c),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Aviso no bloqueante dentro de una celda de la tabla (con tooltip y
/// etiqueta para lectores de pantalla).
class _AvisoCelda extends StatelessWidget {
  const _AvisoCelda({required this.aviso, required this.texto});

  final CourseWarning aviso;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.tertiary;
    return Tooltip(
      message: aviso.label,
      child: Semantics(
        label: aviso.label,
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              texto,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
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
              'No se pudieron leer los cursos guardados en el dispositivo.',
              key: Key('error-cursos'),
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
