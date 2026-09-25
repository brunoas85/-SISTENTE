import 'package:asistente/data/attachments/attachment.dart';
import 'package:asistente/data/cursos/curso.dart';
import 'package:asistente/data/cursos/cursos_repository.dart';
import 'package:asistente/data/local/app_database.dart';
import 'package:asistente/domain/domain.dart';
import 'package:asistente/features/cursos/cursos_page.dart';
import 'package:asistente/features/cursos/cursos_providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

// Datos ficticios. Hoy (TestDeps): jueves 24/09/2026 08:02.
void main() {
  setUpAll(() => initializeDateFormatting('es_AR'));

  Future<TestDeps> pumpCursos(
    WidgetTester tester, {
    TestDeps? deps,
    bool desktop = false,
    List<dynamic> extraOverrides = const [],
  }) async {
    if (desktop) {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    } else {
      usePhoneSize(tester);
    }
    final d = deps ?? TestDeps();
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [...d.overrides, ...extraOverrides.cast()],
        child: testMaterialApp(const CursosPage()),
      ),
    );
    await tester.pumpAndSettle();
    return d;
  }

  CursosRepository repo(TestDeps deps) =>
      CursosRepository(deps.db, deps.photos, clock: () => deps.now);

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  /// Tres cursos ficticios:
  /// - "Gestión ficticia": aprobado en 2026 (fin), 3 créditos, completo y
  ///   sincronizado;
  /// - "Primeros auxilios ficticios": aprobado en 2025, 2 créditos, sin
  ///   certificado ni IF (con avisos), pendiente;
  /// - "Prevención ficticia": en curso desde 08/2026, 5 créditos, pendiente.
  Future<({LocalCurso gestion, LocalCurso auxilios, LocalCurso prevencion})>
  cargarCursos(TestDeps deps) async {
    final r = repo(deps);
    final gestion = await r.guardarCurso(
      userId: fakeUserId,
      draft: CursoDraft(
        actividad: 'Gestión ficticia',
        codigo: 'IN-A3-00001',
        portal: 'INAP',
        fechaInicio: CalendarDate(2026, 3, 2),
        fechaFin: CalendarDate(2026, 4, 30),
        creditos: 3,
        estado: CourseStatus.approved,
        ifGde: 'IF-2026-00000001-APN-FICTICIO',
      ),
      certificado: NuevoAdjunto(
        PreparedAttachment(bytes: fakePdf(), extension: 'pdf'),
      ),
    );
    await r.markCursoSynced(gestion.id, gestion.revision);
    final auxilios = await r.guardarCurso(
      userId: fakeUserId,
      draft: CursoDraft(
        actividad: 'Primeros auxilios ficticios',
        portal: 'SRT',
        fechaFin: CalendarDate(2025, 11, 30),
        creditos: 2,
        estado: CourseStatus.approved,
      ),
    );
    final prevencion = await r.guardarCurso(
      userId: fakeUserId,
      draft: CursoDraft(
        actividad: 'Prevención ficticia',
        portal: 'SRT',
        fechaInicio: CalendarDate(2026, 8, 3),
        creditos: 5,
        estado: CourseStatus.inProgress,
      ),
    );
    return (gestion: gestion, auxilios: auxilios, prevencion: prevencion);
  }

  Future<void> elegir(WidgetTester tester, String filtro, String opcion) async {
    await tester.tap(find.byKey(Key(filtro)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(opcion).last);
    await tester.pumpAndSettle();
  }

  testWidgets('celular: el filtro de año cambia el total y la lista, con '
      'avisos y estado de sync', (tester) async {
    final deps = TestDeps();
    final c = await cargarCursos(deps);
    await pumpCursos(tester, deps: deps);

    // Arranca en "Todos los años" (decisión de Bruno, 2026-09-25): suma
    // todo lo aprobado y muestra todos los cursos.
    expect(
      textOf(tester, 'total-creditos-titulo'),
      'Créditos aprobados (todos los años)',
    );
    expect(textOf(tester, 'total-creditos'), '5');
    expect(textOf(tester, 'cursos-aprobados'), '2 cursos aprobados');
    expect(find.byKey(Key('curso-${c.gestion.id}')), findsOneWidget);
    expect(find.byKey(Key('curso-${c.prevencion.id}')), findsOneWidget);
    expect(
      textOf(tester, 'resumen-avisos'),
      '1 curso aprobado sin certificado o sin IF.',
    );
    expect(find.byKey(const Key('tabla-cursos')), findsNothing);

    // 2026: solo lo que termina (o empieza, sin fin) en 2026.
    await elegir(tester, 'filtro-anio', '2026');
    expect(
      textOf(tester, 'total-creditos-titulo'),
      'Créditos aprobados en 2026',
    );
    expect(textOf(tester, 'total-creditos'), '3');
    expect(textOf(tester, 'cursos-aprobados'), '1 curso aprobado');
    expect(find.byKey(Key('curso-${c.gestion.id}')), findsOneWidget);
    expect(find.byKey(Key('curso-${c.prevencion.id}')), findsOneWidget);
    expect(find.byKey(Key('curso-${c.auxilios.id}')), findsNothing);
    expect(find.byKey(const Key('resumen-avisos')), findsNothing);
    expect(find.byTooltip('Sincronizada'), findsOneWidget);
    expect(find.byTooltip('Pendiente de sincronizar'), findsOneWidget);

    // 2025: el curso aprobado sin certificado ni IF, con sus avisos.
    await elegir(tester, 'filtro-anio', '2025');
    expect(textOf(tester, 'total-creditos'), '2');
    expect(find.byKey(Key('curso-${c.gestion.id}')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(Key('avisos-${c.auxilios.id}')),
        matching: find.text('Aprobado sin certificado · Aprobado sin IF'),
      ),
      findsOneWidget,
    );
    expect(
      textOf(tester, 'resumen-avisos'),
      '1 curso aprobado sin certificado o sin IF.',
    );

    // De vuelta a todos los años.
    await elegir(tester, 'filtro-anio', 'Todos los años');
    expect(textOf(tester, 'total-creditos'), '5');

    // Estado y portal filtran la lista, pero no el total.
    await elegir(tester, 'filtro-estado', 'En curso');
    expect(find.byKey(Key('curso-${c.prevencion.id}')), findsOneWidget);
    expect(find.byKey(Key('curso-${c.auxilios.id}')), findsNothing);
    expect(textOf(tester, 'total-creditos'), '5');
    await elegir(tester, 'filtro-portal', 'INAP');
    expect(find.byKey(const Key('sin-resultados')), findsOneWidget);
    await tester.tap(find.byKey(const Key('limpiar-filtros')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(Key('curso-${c.auxilios.id}')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(Key('curso-${c.auxilios.id}')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('buscar-curso')),
      -200,
      scrollable: find.byType(Scrollable).first,
    );

    // Búsqueda sin acentos ni mayúsculas.
    await tester.enterText(find.byKey(const Key('buscar-curso')), 'GESTION');
    await tester.pumpAndSettle();
    expect(find.byKey(Key('curso-${c.gestion.id}')), findsOneWidget);
    expect(find.byKey(Key('curso-${c.prevencion.id}')), findsNothing);

    await disposeTestApp(tester, deps);
  });

  testWidgets('celular: tocar un curso abre la edición y el menú permite '
      'borrarlo', (tester) async {
    final deps = TestDeps();
    final c = await cargarCursos(deps);
    await pumpCursos(tester, deps: deps);

    await tester.tap(find.text('Prevención ficticia'));
    await tester.pumpAndSettle();
    expect(find.text('Editar curso'), findsOneWidget);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('acciones-${c.prevencion.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar-borrar-curso')));
    await tester.pumpAndSettle();

    expect(find.byKey(Key('curso-${c.prevencion.id}')), findsNothing);
    final row = await repo(deps).findCurso(c.prevencion.id);
    expect(row!.deletedAt, isNotNull);

    await disposeTestApp(tester, deps);
  });

  testWidgets('la lista arranca en "Todos los años"', (tester) async {
    final deps = TestDeps();
    await cargarCursos(deps);
    await pumpCursos(tester, deps: deps);

    expect(
      find.descendant(
        of: find.byKey(const Key('filtro-anio')),
        matching: find.text('Todos los años'),
      ),
      findsOneWidget,
    );
    expect(
      textOf(tester, 'total-creditos-titulo'),
      'Créditos aprobados (todos los años)',
    );
    // Cuenta también el curso aprobado de 2025.
    expect(textOf(tester, 'total-creditos'), '5');
    expect(textOf(tester, 'cursos-aprobados'), '2 cursos aprobados');

    await disposeTestApp(tester, deps);
  });

  testWidgets('sin cursos: estado vacío y total 0', (tester) async {
    final deps = await pumpCursos(tester);
    expect(find.byKey(const Key('sin-cursos')), findsOneWidget);
    expect(textOf(tester, 'total-creditos'), '0');
    expect(find.byKey(const Key('nuevo-curso')), findsOneWidget);
    await disposeTestApp(tester, deps);
  });

  testWidgets('un año sin cursos lo dice y ofrece ver todos', (tester) async {
    final deps = TestDeps();
    await repo(deps).guardarCurso(
      userId: fakeUserId,
      draft: CursoDraft(
        actividad: 'Curso viejo ficticio',
        fechaFin: CalendarDate(2024, 6, 1),
      ),
    );
    await pumpCursos(tester, deps: deps);
    expect(find.text('Curso viejo ficticio'), findsOneWidget);

    await elegir(tester, 'filtro-anio', '2026');
    expect(textOf(tester, 'sin-resultados'), 'No hay cursos en 2026.');
    await tester.tap(find.byKey(const Key('ver-todos')));
    await tester.pumpAndSettle();
    expect(find.text('Curso viejo ficticio'), findsOneWidget);

    await disposeTestApp(tester, deps);
  });

  testWidgets('un aprobado sin fechas no suma a ningún año y se avisa', (
    tester,
  ) async {
    final deps = TestDeps();
    // La app ya no deja guardar un aprobado sin fechas, pero puede llegar
    // así del servidor o de datos viejos: se inserta directo en drift, sin
    // pasar por la validación del repositorio.
    await deps.db
        .into(deps.db.cursos)
        .insert(
          CursosCompanion.insert(
            id: 'aprobado-sin-fechas',
            userId: fakeUserId,
            actividad: 'Curso sin fechas ficticio',
            creditos: const Value(4),
            estado: const Value('aprobado'),
            updatedAt: DateTime(2026, 9, 20),
            syncStatus: SyncStatus.synced,
          ),
        );
    await pumpCursos(tester, deps: deps);

    // En "Todos los años" suma y no hace falta el aviso.
    expect(textOf(tester, 'total-creditos'), '4');
    expect(find.byKey(const Key('aprobados-sin-anio')), findsNothing);

    await elegir(tester, 'filtro-anio', '2026');
    expect(textOf(tester, 'total-creditos'), '0');
    expect(
      textOf(tester, 'aprobados-sin-anio'),
      '1 curso aprobado sin fechas no suma a ningún año: cargale la fecha '
      'de fin.',
    );

    await disposeTestApp(tester, deps);
  });

  testWidgets('error al leer la base: lo explica y ofrece reintentar', (
    tester,
  ) async {
    final deps = await pumpCursos(
      tester,
      extraOverrides: [
        misCursosProvider.overrideWith(
          (ref) => Stream<List<LocalCurso>>.error('base ficticia rota'),
        ),
      ],
    );
    expect(find.byKey(const Key('error-cursos')), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    await disposeTestApp(tester, deps);
  });

  group('PC', () {
    testWidgets('tabla con avisos, estado editable en línea y total que se '
        'actualiza', (tester) async {
      final deps = TestDeps();
      final c = await cargarCursos(deps);
      await pumpCursos(tester, deps: deps, desktop: true);

      final tabla = find.byKey(const Key('tabla-cursos'));
      expect(tabla, findsOneWidget);
      expect(
        find.descendant(of: tabla, matching: find.text('Gestión ficticia')),
        findsOneWidget,
      );
      expect(find.text('IF-2026-00000001-APN-FICTICIO'), findsOneWidget);
      expect(find.byTooltip('Ver certificado'), findsOneWidget);
      // "Primeros auxilios" (2025) ya está aprobado sin IF.
      expect(find.byTooltip('Aprobado sin IF'), findsOneWidget);
      expect(textOf(tester, 'total-creditos'), '5');

      // Aprobar el curso en curso desde la tabla: suma y avisa lo que falta.
      await tester.tap(find.byKey(Key('estado-fila-${c.prevencion.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aprobado').last);
      await tester.pumpAndSettle();

      expect(textOf(tester, 'total-creditos'), '10');
      expect(find.byTooltip('Aprobado sin IF'), findsNWidgets(2));
      expect(find.byTooltip('Aprobado sin certificado'), findsNWidgets(2));
      expect(
        textOf(tester, 'resumen-avisos'),
        '2 cursos aprobados sin certificado o sin IF.',
      );
      final row = (await repo(deps).findCurso(c.prevencion.id))!;
      expect(row.status, CourseStatus.approved);
      expect(row.syncStatus, SyncStatus.pending);
      // Las acciones entran en pantalla.
      expect(
        tester.getBottomRight(find.byTooltip('Borrar').first).dx,
        lessThanOrEqualTo(1440),
      );

      await disposeTestApp(tester, deps);
    });

    testWidgets('aprobar en línea un curso sin fechas no guarda y lo '
        'explica', (tester) async {
      final deps = TestDeps();
      final c = await repo(deps).guardarCurso(
        userId: fakeUserId,
        draft: const CursoDraft(
          actividad: 'Curso sin fechas ficticio',
          creditos: 2,
          estado: CourseStatus.inProgress,
        ),
      );
      await pumpCursos(tester, deps: deps, desktop: true);

      await tester.tap(find.byKey(Key('estado-fila-${c.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aprobado').last);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Para marcarlo aprobado, cargá la fecha de fin.'),
        ),
        findsOneWidget,
      );
      final row = (await repo(deps).findCurso(c.id))!;
      expect(row.status, CourseStatus.inProgress);
      expect(row.revision, c.revision);
      expect(textOf(tester, 'total-creditos'), '0');
      // La tabla sigue mostrando el estado guardado.
      expect(
        find.descendant(
          of: find.byKey(Key('estado-fila-${c.id}')),
          matching: find.text('En curso'),
        ),
        findsOneWidget,
      );

      await disposeTestApp(tester, deps);
    });

    testWidgets('Ctrl+N abre el formulario de un curso nuevo y Ctrl+F va a '
        'la búsqueda', (tester) async {
      final deps = TestDeps();
      await cargarCursos(deps);
      await pumpCursos(tester, deps: deps, desktop: true);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      final buscar = tester.widget<TextField>(
        find.byKey(const Key('buscar-curso')),
      );
      expect(buscar.focusNode!.hasFocus, isTrue);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('curso-actividad')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Nuevo curso'),
        ),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('curso-actividad')),
        'Curso nuevo ficticio',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('guardar-curso')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('curso-actividad')), findsNothing);
      // Sin fechas: aparece en "Todos los años", donde arranca la lista.
      expect(
        find.descendant(
          of: find.byKey(const Key('tabla-cursos')),
          matching: find.text('Curso nuevo ficticio'),
        ),
        findsOneWidget,
      );

      await disposeTestApp(tester, deps);
    });
  });
}
