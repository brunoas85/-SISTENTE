import 'package:asistente/data/local/app_database.dart';
import 'package:asistente/features/asistencia/asistencia_mes_page.dart';
import 'package:asistente/features/asistencia/asistencia_providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

// Datos ficticios. Hoy (TestDeps): jueves 24/09/2026 08:02. El martes
// 15/09 es un feriado ficticio y el control empieza el martes 01/09.
//
// Septiembre armado:
// - días hábiles del 01 al 23 con jornada exacta 08:00–16:00, salvo:
// - 10/09 sin fichada → faltante;
// - 11/09 dos tramos superpuestos → conflicto (el segundo, cargado a mano);
// - 21/09 ingreso corregido (el dispositivo marcó 07:50);
// - 22/09 tramo abierto desde las 08:00;
// - 23/09 con foto de ingreso guardada en el dispositivo.
void main() {
  setUpAll(() => initializeDateFormatting('es_AR'));

  const habiles = [
    '2026-09-01', '2026-09-02', '2026-09-03', '2026-09-04', //
    '2026-09-07', '2026-09-08', '2026-09-09', '2026-09-14',
    '2026-09-16', '2026-09-17', '2026-09-18',
  ];

  Future<void> insertar(
    TestDeps deps,
    String id,
    String fecha,
    int ingreso, {
    int? egreso,
    int? ingresoOriginal,
    String? fotoLocal,
    String? fotoPath,
    String origen = 'dispositivo',
  }) => deps.db
      .into(deps.db.fichadas)
      .insert(
        FichadasCompanion.insert(
          id: id,
          userId: fakeUserId,
          fecha: fecha,
          ingresoMin: ingreso,
          egresoMin: Value(egreso),
          ingresoOriginalMin: Value(ingresoOriginal),
          editado: Value(ingresoOriginal != null),
          fotoIngresoLocal: Value(fotoLocal),
          fotoIngresoPath: Value(fotoPath),
          origen: Value(origen),
          updatedAt: DateTime(2026, 9, 23),
          revision: const Value(1),
          syncStatus: SyncStatus.synced,
        ),
      );

  Future<TestDeps> septiembre() async {
    final deps = TestDeps();
    await deps.db
        .into(deps.db.feriados)
        .insert(
          FeriadosCompanion.insert(
            fecha: '2026-09-15',
            nombre: 'Feriado ficticio',
          ),
        );
    await insertarJornadasExactas(deps.db, habiles);
    await insertar(deps, 'c1', '2026-09-11', 480, egreso: 720);
    await insertar(
      deps,
      'c2',
      '2026-09-11',
      660,
      egreso: 960,
      origen: 'manual',
    );
    await insertar(
      deps,
      'ed',
      '2026-09-21',
      480,
      egreso: 960,
      ingresoOriginal: 470,
    );
    await insertar(deps, 'ab', '2026-09-22', 480);
    final foto = await deps.photos.save('foto_ingreso.jpg', fakeJpeg());
    await insertar(deps, 'fo', '2026-09-23', 480, egreso: 960, fotoLocal: foto);
    return deps;
  }

  Future<void> pump(
    WidgetTester tester,
    TestDeps deps, {
    bool desktop = true,
  }) async {
    if (desktop) {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    } else {
      usePhoneSize(tester);
    }
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: deps.overrides,
        child: testMaterialApp(const AsistenciaMesPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  String texto(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  Finder fila(String fecha) => find.byKey(Key('fila-$fecha'));

  /// Vuelve arriba (el resumen sale de la lista al bajar).
  Future<void> arriba(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.byKey(const Key('resumen-mes')),
      -400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  /// Lleva el widget a la vista (la tabla es más alta que la pantalla) y
  /// lo toca.
  Future<void> tocar(WidgetTester tester, String key) async {
    final f = find.byKey(Key(key));
    if (f.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        f,
        300,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
  }

  group('PC', () {
    testWidgets('tabla con todos los días: faltante, conflicto, feriado y '
        'abierto', (tester) async {
      final deps = await septiembre();
      await pump(tester, deps);

      expect(find.byKey(const Key('tabla-asistencia')), findsOneWidget);
      expect(texto(tester, 'mes-titulo'), 'Septiembre 2026');
      for (var d = 1; d <= 30; d++) {
        expect(fila('2026-09-${d.toString().padLeft(2, '0')}'), findsOneWidget);
      }
      expect(texto(tester, 'estado-2026-09-10'), 'Faltante');
      expect(texto(tester, 'estado-2026-09-11'), 'Conflicto');
      expect(texto(tester, 'estado-2026-09-15'), 'Feriado: Feriado ficticio');
      expect(texto(tester, 'estado-2026-09-22'), 'Abierto');
      expect(texto(tester, 'estado-2026-09-19'), 'Fin de semana');
      expect(texto(tester, 'estado-2026-09-24'), 'Hoy');
      expect(texto(tester, 'estado-2026-09-25'), 'Futuro');
      expect(texto(tester, 'estado-2026-09-01'), 'Trabajado');
      expect(texto(tester, 'trabajado-2026-09-01'), '8:00');
      expect(texto(tester, 'deuda-2026-09-10'), '8:00');
      expect(texto(tester, 'trabajado-2026-09-22'), '—');

      // Tramos, marcas de editado, foto y sync.
      expect(
        find.descendant(
          of: fila('2026-09-22'),
          matching: find.text('08:00–abierto'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('editado-ed')), findsOneWidget);
      expect(find.byKey(const Key('foto-fo')), findsOneWidget);
      expect(find.byKey(const Key('foto-ed')), findsNothing);
      expect(find.byKey(const Key('cerrar-ab')), findsOneWidget);
      // No se agregan tramos en feriados, fines de semana, hoy ni a futuro.
      expect(find.byKey(const Key('agregar-2026-09-10')), findsOneWidget);
      for (final f in ['15', '19', '24', '25']) {
        expect(find.byKey(Key('agregar-2026-09-$f')), findsNothing);
      }

      // Resumen de buildMonthlySummary (banco hasta hoy).
      expect(texto(tester, 'resumen-habiles'), '21');
      expect(texto(tester, 'resumen-faltantes'), '1');
      expect(texto(tester, 'resumen-conflictos'), '1');
      expect(texto(tester, 'resumen-abiertos'), '1');
      expect(texto(tester, 'resumen-deuda'), '8:00');
      expect(texto(tester, 'resumen-deuda-no-cubierta'), '8:00');
      expect(texto(tester, 'resumen-afavor'), '0:00');
      expect(texto(tester, 'resumen-variacion'), '-8:00');
      expect(texto(tester, 'resumen-revisar'), '2');

      await disposeTestApp(tester, deps);
    });

    testWidgets('las filas para revisar se resaltan', (tester) async {
      final deps = await septiembre();
      await pump(tester, deps);
      final scheme = Theme.of(tester.element(fila('2026-09-11'))).colorScheme;

      Color? fondo(String fecha) {
        final c = tester.widget<Container>(
          find
              .descendant(of: fila(fecha), matching: find.byType(Container))
              .first,
        );
        return (c.decoration as BoxDecoration?)?.color;
      }

      expect(fondo('2026-09-11'), scheme.errorContainer);
      expect(fondo('2026-09-22'), scheme.errorContainer);
      expect(fondo('2026-09-01'), isNull);

      await disposeTestApp(tester, deps);
    });

    testWidgets('filtro "para revisar" y "faltantes"', (tester) async {
      final deps = await septiembre();
      await pump(tester, deps);

      await tocar(tester, 'filtro-revisar');
      await tester.pumpAndSettle();
      expect(fila('2026-09-11'), findsOneWidget);
      expect(fila('2026-09-22'), findsOneWidget);
      expect(fila('2026-09-10'), findsNothing);
      expect(fila('2026-09-01'), findsNothing);
      expect(fila('2026-09-15'), findsNothing);

      await tocar(tester, 'filtro-faltantes');
      await tester.pumpAndSettle();
      expect(fila('2026-09-10'), findsOneWidget);
      expect(fila('2026-09-11'), findsNothing);

      await tocar(tester, 'filtro-editados');
      await tester.pumpAndSettle();
      expect(fila('2026-09-21'), findsOneWidget);
      expect(fila('2026-09-10'), findsNothing);

      await disposeTestApp(tester, deps);
    });

    testWidgets('edición en línea bloqueada por superposición', (tester) async {
      final deps = await septiembre();
      await pump(tester, deps);

      await tocar(tester, 'agregar-2026-09-23');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('editor-ingreso')), '15:00');
      await tester.enterText(find.byKey(const Key('editor-egreso')), '17:00');
      await tester.pump();

      expect(
        texto(tester, 'editor-mensaje'),
        'El tramo 15:00–17:00 se superpone con el tramo 08:00–16:00.',
      );
      final guardar = tester.widget<IconButton>(
        find.byKey(const Key('editor-guardar')),
      );
      expect(guardar.onPressed, isNull);
      // Enter tampoco guarda.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      final rows = await deps.db.select(deps.db.fichadas).get();
      expect(rows.where((r) => r.fecha == '2026-09-23'), hasLength(1));

      // Editar un tramo existente contra el de al lado también se bloquea.
      await tocar(tester, 'editor-cancelar');
      await tester.pumpAndSettle();
      await tocar(tester, 'tramo-c2');
      await tester.pumpAndSettle();
      expect(
        texto(tester, 'editor-mensaje'),
        contains('se superpone con el tramo 08:00–12:00'),
      );
      await tester.enterText(find.byKey(const Key('editor-ingreso')), '12:00');
      await tester.pump();
      expect(
        texto(tester, 'editor-mensaje'),
        'La hora anterior queda registrada como original.',
      );

      await disposeTestApp(tester, deps);
    });

    testWidgets('corregir un tramo en línea: marca editado y recalcula', (
      tester,
    ) async {
      final deps = await septiembre();
      await pump(tester, deps);

      await tocar(tester, 'tramo-fo');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('editor-egreso')), '17:00');
      await tester.pump();
      await tocar(tester, 'editor-guardar');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('editor-ingreso')), findsNothing);
      expect(texto(tester, 'afavor-2026-09-23'), '1:00');
      expect(find.byKey(const Key('editado-fo')), findsOneWidget);
      final row = await (deps.db.select(
        deps.db.fichadas,
      )..where((f) => f.id.equals('fo'))).getSingle();
      expect(row.egresoMin, 1020);
      expect(row.egresoOriginalMin, 960);
      expect(row.editado, isTrue);
      expect(row.syncStatus, SyncStatus.pending);

      await disposeTestApp(tester, deps);
    });

    testWidgets('cerrar el tramo abierto y borrar con confirmación', (
      tester,
    ) async {
      final deps = await septiembre();
      await pump(tester, deps);

      await tocar(tester, 'cerrar-ab');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('editor-egreso')), '16:00');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(texto(tester, 'estado-2026-09-22'), 'Trabajado');
      await arriba(tester);
      expect(texto(tester, 'resumen-abiertos'), '0');

      await tocar(tester, 'borrar-ab');
      await tester.pumpAndSettle();
      expect(find.text('Borrar tramo'), findsOneWidget);
      await tocar(tester, 'confirmar-borrar-tramo');
      await tester.pumpAndSettle();

      expect(texto(tester, 'estado-2026-09-22'), 'Faltante');
      await arriba(tester);
      expect(texto(tester, 'resumen-faltantes'), '2');
      final row = await (deps.db.select(
        deps.db.fichadas,
      )..where((f) => f.id.equals('ab'))).getSingle();
      expect(row.deletedAt, isNotNull);

      await disposeTestApp(tester, deps);
    });

    testWidgets('marca "manual" y filtro "Cargados a mano"', (tester) async {
      final deps = await septiembre();
      await pump(tester, deps);

      expect(find.byKey(const Key('origen-c2')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('origen-c2')),
          matching: find.text('manual'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('origen-c1')), findsNothing);
      expect(find.byKey(const Key('origen-ed')), findsNothing);

      await tocar(tester, 'filtro-manuales');
      await tester.pumpAndSettle();
      expect(fila('2026-09-11'), findsOneWidget);
      expect(fila('2026-09-21'), findsNothing);
      expect(fila('2026-09-10'), findsNothing);

      await disposeTestApp(tester, deps);
    });

    testWidgets('un tramo agregado queda como manual', (tester) async {
      final deps = await septiembre();
      await pump(tester, deps);

      await tocar(tester, 'agregar-2026-09-10');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('editor-ingreso')), '8:00');
      await tester.enterText(find.byKey(const Key('editor-egreso')), '16:00');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(texto(tester, 'estado-2026-09-10'), 'Trabajado');
      final row = await (deps.db.select(
        deps.db.fichadas,
      )..where((f) => f.fecha.equals('2026-09-10'))).getSingle();
      expect(row.origen, 'manual');
      expect(row.editado, isFalse);
      expect(find.byKey(Key('origen-${row.id}')), findsOneWidget);

      await disposeTestApp(tester, deps);
    });

    testWidgets('antes del inicio del control no se agregan tramos', (
      tester,
    ) async {
      final deps = await septiembre();
      await pump(tester, deps);

      await tocar(tester, 'mes-anterior');
      await tester.pumpAndSettle();
      expect(texto(tester, 'mes-titulo'), 'Agosto 2026');
      expect(find.byKey(const Key('agregar-2026-08-31')), findsNothing);
      await tocar(tester, 'agregar-tramo');
      await tester.pumpAndSettle();
      expect(
        find.text(
          'En agosto 2026 no hay días pasados laborables para agregar '
          'tramos.',
        ),
        findsOneWidget,
      );

      await disposeTestApp(tester, deps);
    });

    testWidgets('borrar la primera fichada avisa que corre el inicio', (
      tester,
    ) async {
      final deps = await septiembre();
      await deps.db
          .into(deps.db.bancoMovimientos)
          .insert(
            BancoMovimientosCompanion.insert(
              id: 'acumulacion-ficticia',
              userId: fakeUserId,
              tipo: 'acumulacion',
              fecha: '2026-09-01',
              minutos: 60,
              updatedAt: DateTime(2026, 9, 20),
              syncStatus: SyncStatus.synced,
            ),
          );
      await pump(tester, deps);

      await tocar(tester, 'borrar-jornada-2026-09-01');
      await tester.pumpAndSettle();
      expect(find.text('Borrar la primera fichada'), findsOneWidget);
      expect(
        texto(tester, 'texto-borrar-tramo'),
        contains(
          'el inicio del control pasa del 01/09/2026 al 02/09/2026. Los días '
          'sin fichada de ese período dejan de ser faltantes. 1 movimiento '
          'del banco de ese período deja de computar.',
        ),
      );
      await tocar(tester, 'confirmar-borrar-tramo');
      await tester.pumpAndSettle();

      expect(texto(tester, 'estado-2026-09-01'), 'Antes del control');
      expect(find.byKey(const Key('agregar-2026-09-01')), findsNothing);

      await disposeTestApp(tester, deps);
    });

    testWidgets('hoy no se carga una hora posterior a la actual', (
      tester,
    ) async {
      final deps = await septiembre();
      // Hoy (24/09, 08:02) con un tramo abierto desde las 08:00.
      await insertar(deps, 'hoy', '2026-09-24', 480);
      await pump(tester, deps);

      await tocar(tester, 'cerrar-hoy');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('editor-egreso')), '12:00');
      await tester.pump();
      expect(
        texto(tester, 'editor-mensaje'),
        'Son las 08:02: el egreso (12:00) no puede ser posterior a la hora '
        'actual.',
      );
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('editor-guardar')))
            .onPressed,
        isNull,
      );

      await disposeTestApp(tester, deps);
    });

    testWidgets('selector de mes con flechas y atajos de teclado', (
      tester,
    ) async {
      final deps = await septiembre();
      await pump(tester, deps);

      await tocar(tester, 'mes-anterior');
      await tester.pumpAndSettle();
      expect(texto(tester, 'mes-titulo'), 'Agosto 2026');
      // Agosto es anterior al inicio del control: nada es faltante.
      expect(texto(tester, 'estado-2026-08-03'), 'Antes del control');
      expect(texto(tester, 'resumen-faltantes'), '0');
      expect(fila('2026-08-31'), findsOneWidget);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();
      expect(texto(tester, 'mes-titulo'), 'Octubre 2026');
      expect(texto(tester, 'estado-2026-10-01'), 'Futuro');
      expect(texto(tester, 'resumen-variacion'), '0:00');

      await tocar(tester, 'mes-actual');
      await tester.pumpAndSettle();
      expect(texto(tester, 'mes-titulo'), 'Septiembre 2026');

      await disposeTestApp(tester, deps);
    });

    testWidgets('foto local del tramo', (tester) async {
      final deps = await septiembre();
      await pump(tester, deps);

      await tocar(tester, 'foto-fo');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dialogo-foto')), findsOneWidget);
      expect(find.byKey(const Key('foto-local')), findsOneWidget);
      expect(deps.remote.signedUrlRequests, isEmpty);

      await disposeTestApp(tester, deps);
    });

    testWidgets('foto solo en el servidor: URL firmada de 60 s', (
      tester,
    ) async {
      final deps = await septiembre();
      const path = '$fakeUserId/2026/09/remota_ingreso.jpg';
      await insertar(
        deps,
        're',
        '2026-09-02',
        1000,
        egreso: 1100,
        fotoPath: path,
      );
      await pump(tester, deps);

      // Sin conexión: avisa y no inventa una URL.
      await tocar(tester, 'foto-re');
      await tester.pumpAndSettle();
      expect(
        find.text('Sin conexión: la foto está solo en el servidor.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();

      deps.remote.online = true;
      await tocar(tester, 'foto-re');
      await tester.pumpAndSettle();
      expect(deps.remote.signedUrlRequests, [
        (path, const Duration(seconds: 60)),
      ]);
      expect(find.byKey(const Key('foto-remota')), findsOneWidget);

      await disposeTestApp(tester, deps);
    });
  });

  group('celular', () {
    testWidgets('lista de días con el mismo resumen', (tester) async {
      final deps = await septiembre();
      await pump(tester, deps, desktop: false);

      expect(find.byKey(const Key('tabla-asistencia')), findsNothing);
      expect(texto(tester, 'resumen-faltantes'), '1');
      await tocar(tester, 'filtro-revisar');
      await tester.pumpAndSettle();
      expect(fila('2026-09-11'), findsOneWidget);
      expect(texto(tester, 'estado-2026-09-11'), 'Conflicto');
      expect(
        find.text('Hay tramos superpuestos: no computan.'),
        findsOneWidget,
      );

      await disposeTestApp(tester, deps);
    });

    testWidgets('sin fichadas: aviso y ningún faltante', (tester) async {
      final deps = TestDeps();
      await pump(tester, deps, desktop: false);

      expect(find.byKey(const Key('aviso-sin-control')), findsOneWidget);
      expect(texto(tester, 'resumen-faltantes'), '0');
      await tocar(tester, 'filtro-editados');
      await tester.pumpAndSettle();
      expect(
        texto(tester, 'sin-dias'),
        'No hay tramos editados en septiembre 2026.',
      );

      await disposeTestApp(tester, deps);
    });

    testWidgets('error al leer la base', (tester) async {
      final deps = TestDeps();
      usePhoneSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            ...deps.overrides,
            misFichadasProvider.overrideWith(
              (ref) => Stream.error(StateError('base ficticia rota')),
            ),
          ],
          child: testMaterialApp(const AsistenciaMesPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('error-asistencia')), findsOneWidget);

      await disposeTestApp(tester, deps);
    });
  });
}
