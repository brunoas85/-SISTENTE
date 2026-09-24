import 'package:asistente/data/attachments/attachment_picker.dart';
import 'package:asistente/data/banco/banco_repository.dart';
import 'package:asistente/data/banco/movimiento.dart';
import 'package:asistente/data/local/app_database.dart';
import 'package:asistente/domain/domain.dart';
import 'package:asistente/features/banco_horas/banco_page.dart';
import 'package:asistente/features/banco_horas/banco_providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

// Datos ficticios. Hoy (TestDeps): jueves 24/09/2026 08:02.
void main() {
  setUpAll(() => initializeDateFormatting('es_AR'));

  Future<TestDeps> pumpBanco(
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
        child: testMaterialApp(const BancoPage()),
      ),
    );
    await tester.pumpAndSettle();
    return d;
  }

  Future<void> fichada(TestDeps deps, String fecha, int ingreso, int egreso) =>
      deps.db
          .into(deps.db.fichadas)
          .insert(
            FichadasCompanion.insert(
              id: 'fichada-$fecha',
              userId: fakeUserId,
              fecha: fecha,
              ingresoMin: ingreso,
              egresoMin: Value(egreso),
              updatedAt: DateTime(2026, 9, 18),
              syncStatus: SyncStatus.synced,
            ),
          );

  BancoRepository repo(TestDeps deps) =>
      BancoRepository(deps.db, deps.photos, clock: () => deps.now);

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  testWidgets('saldo negativo: muestra -24:00 con el desglose', (tester) async {
    final deps = TestDeps();
    // Viernes 18/09 jornada exacta (inicio del control); lunes 21, martes 22
    // y miércoles 23 sin fichada: 3 faltantes de 8:00.
    await fichada(deps, '2026-09-18', 480, 960);
    await pumpBanco(tester, deps: deps);

    expect(textOf(tester, 'saldo-banco'), '-24:00');
    expect(textOf(tester, 'desglose-deuda'), '-24:00');
    expect(textOf(tester, 'desglose-afavor'), '0:00');
    expect(textOf(tester, 'desglose-usufructos'), '0:00');
    expect(
      textOf(tester, 'saldo-faltantes'),
      'Incluye 3 días hábiles sin fichada ni usufructo.',
    );
    // Sin movimientos manuales: estado vacío.
    expect(find.byKey(const Key('sin-movimientos')), findsOneWidget);

    await disposeTestApp(tester, deps);
  });

  testWidgets('camino feliz en el celular: lista con estado de sync y filtro '
      'por mes', (tester) async {
    final deps = TestDeps();
    final r = repo(deps);
    await r.guardarMovimiento(
      userId: fakeUserId,
      draft: MovimientoDraft(
        tipo: TipoMovimiento.acumulacion,
        fecha: CalendarDate(2026, 9, 19),
        minutos: 300,
      ),
    );
    final u = await r.guardarMovimiento(
      userId: fakeUserId,
      draft: MovimientoDraft(
        tipo: TipoMovimiento.usufructoParcial,
        fecha: CalendarDate(2026, 9, 28),
        minutos: 60,
      ),
    );
    await r.markMovimientoSynced(u.id, u.revision);
    await pumpBanco(tester, deps: deps);

    expect(textOf(tester, 'saldo-banco'), '+5:00');
    expect(
      textOf(tester, 'saldo-disponible'),
      'Usufructos cargados a futuro: -1:00 · disponible +4:00',
    );
    expect(textOf(tester, 'desglose-acumulaciones'), '+5:00');
    expect(find.text('Acumulación +5:00'), findsOneWidget);
    expect(find.text('Usufructo parcial -1:00'), findsOneWidget);
    expect(find.byTooltip('Pendiente de sincronizar'), findsOneWidget);
    expect(find.byTooltip('Sincronizada'), findsOneWidget);
    expect(find.byKey(const Key('tabla-movimientos')), findsNothing);

    // Filtro: agosto 2026 no tiene movimientos.
    await tester.tap(find.byKey(const Key('filtro-mes')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agosto').last);
    await tester.pumpAndSettle();
    expect(find.text('No hay movimientos en agosto 2026.'), findsOneWidget);
    expect(
      textOf(tester, 'variacion-mes'),
      'Variación del banco en agosto 2026: 0:00',
    );

    await disposeTestApp(tester, deps);
  });

  testWidgets('en la PC (≥ 1024) los movimientos van en una tabla', (
    tester,
  ) async {
    final deps = TestDeps();
    await repo(deps).guardarMovimiento(
      userId: fakeUserId,
      draft: MovimientoDraft(
        tipo: TipoMovimiento.acumulacion,
        fecha: CalendarDate(2026, 9, 19),
        minutos: 150,
        numeroGde: 'NO-2026-00000001-APN-PNL#APNAC',
      ),
    );
    await pumpBanco(tester, deps: deps, desktop: true);

    expect(find.byKey(const Key('tabla-movimientos')), findsOneWidget);
    final tabla = find.byKey(const Key('tabla-movimientos'));
    expect(
      find.descendant(of: tabla, matching: find.text('+2:30')),
      findsOneWidget,
    );
    expect(find.text('NO-2026-00000001-APN-PNL#APNAC'), findsOneWidget);
    expect(find.text('Vigente'), findsOneWidget);
    // Las acciones entran en pantalla (sin scroll horizontal).
    expect(
      tester.getBottomRight(find.byTooltip('Borrar')).dx,
      lessThanOrEqualTo(1440),
    );

    // Marcar como perdido desde la tabla: deja de computar.
    await tester.tap(find.byTooltip('Marcar como perdido'));
    await tester.pumpAndSettle();
    expect(find.text('Perdido'), findsOneWidget);
    expect(textOf(tester, 'saldo-banco'), '0:00');
    expect(
      textOf(tester, 'desglose-perdidos'),
      'usufructos 0:00 · acumulaciones 2:30',
    );

    // Borrar pide confirmación.
    await tester.tap(find.byTooltip('Borrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar-borrar')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tabla-movimientos')), findsNothing);
    final row = await deps.db.select(deps.db.bancoMovimientos).getSingle();
    expect(row.deletedAt, isNotNull);

    await disposeTestApp(tester, deps);
  });

  testWidgets('error al leer la base: lo explica y ofrece reintentar', (
    tester,
  ) async {
    final deps = await pumpBanco(
      tester,
      extraOverrides: [
        misMovimientosProvider.overrideWith(
          (ref) => Stream<List<LocalMovimiento>>.error('base ficticia rota'),
        ),
      ],
    );
    expect(find.byKey(const Key('error-banco')), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    await disposeTestApp(tester, deps);
  });

  group('alta de movimientos', () {
    testWidgets(
      'usufructo bloqueado por saldo: "Saldo disponible X, pedís Y"',
      (tester) async {
        final deps = TestDeps();
        await repo(deps).guardarMovimiento(
          userId: fakeUserId,
          draft: MovimientoDraft(
            tipo: TipoMovimiento.acumulacion,
            fecha: CalendarDate(2026, 9, 19),
            minutos: 60,
          ),
        );
        await pumpBanco(tester, deps: deps);

        await tester.tap(find.byKey(const Key('nuevo-movimiento')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('tipo-usufructoParcial')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('minutos')), '2:00');
        await tester.pumpAndSettle();

        expect(
          textOf(tester, 'movimiento-error'),
          'Saldo disponible 1:00, pedís 2:00.',
        );
        FilledButton guardar() => tester.widget<FilledButton>(
          find.ancestor(
            of: find.text('Guardar'),
            matching: find.byWidgetPredicate((w) => w is FilledButton),
          ),
        );
        expect(guardar().onPressed, isNull);

        // Usufructo total: los minutos son la jornada y tampoco alcanza.
        await tester.tap(find.byKey(const Key('tipo-usufructoTotal')));
        await tester.pumpAndSettle();
        expect(textOf(tester, 'minutos-total'), '8:00');
        expect(
          textOf(tester, 'movimiento-error'),
          'Saldo disponible 1:00, pedís 8:00.',
        );
        expect(guardar().onPressed, isNull);

        // Con lo disponible sí se puede.
        await tester.tap(find.byKey(const Key('tipo-usufructoParcial')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('minutos')), '1:00');
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('movimiento-error')), findsNothing);
        await tester.tap(find.byKey(const Key('guardar-movimiento')));
        await tester.pumpAndSettle();

        expect(find.text('Usufructo parcial -1:00'), findsOneWidget);
        expect(textOf(tester, 'saldo-banco'), '0:00');

        await disposeTestApp(tester, deps);
      },
    );

    testWidgets(
      'acumulación en un sábado, con tipo de documento y adjunto PDF',
      (tester) async {
        final deps = TestDeps();
        deps.picker.result = PickedFile(name: 'ficticio.pdf', bytes: fakePdf());
        final t = await repo(deps)
            .guardarTipo(userId: fakeUserId, codigo: 'FOESC');
        await pumpBanco(tester, deps: deps);

        await tester.tap(find.byKey(const Key('nuevo-movimiento')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tipo-movimiento')), findsOneWidget);

        // Cambia la fecha al sábado 19/09/2026 con el selector.
        await tester.tap(find.byKey(const Key('elegir-fecha')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('19'));
        await tester.tap(find.text('Aceptar'));
        await tester.pumpAndSettle();
        expect(textOf(tester, 'fecha-elegida'), 'Fecha: sábado 19/09/2026');
        expect(
          textOf(tester, 'aviso-dia-no-laborable'),
          'El 19/09/2026 es sábado. Las horas de un día no laborable se '
          'cargan como acumulación.',
        );

        await tester.enterText(find.byKey(const Key('minutos')), '4:30');
        await tester.tap(find.byKey(const Key('tipo-documento')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('FOESC').last);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('numero-gde')),
          'NO-2026-00000002-APN-PNL#APNAC',
        );
        await tester.ensureVisible(find.byKey(const Key('adjunto-archivo')));
        await tester.tap(find.byKey(const Key('adjunto-archivo')));
        await tester.pumpAndSettle();
        expect(find.text('Adjunto PDF'), findsOneWidget);

        await tester.tap(find.byKey(const Key('guardar-movimiento')));
        await tester.pumpAndSettle();

        expect(find.text('Acumulación +4:30'), findsOneWidget);
        expect(textOf(tester, 'saldo-banco'), '+4:30');
        final row = await deps.db.select(deps.db.bancoMovimientos).getSingle();
        expect(row.tipo, 'acumulacion');
        expect(row.alcance, isNull);
        expect(row.fecha, '2026-09-19');
        expect(row.minutos, 270);
        expect(row.tipoDocumentoId, t.id);
        expect(row.numeroGde, 'NO-2026-00000002-APN-PNL#APNAC');
        expect(row.adjuntoLocal, endsWith('_adjunto.pdf'));
        expect(row.syncStatus, SyncStatus.pending);
        expect(deps.picker.calls, 1);

        await disposeTestApp(tester, deps);
      },
    );

    testWidgets('usufructo en sábado: se explica y no se puede guardar', (
      tester,
    ) async {
      final deps = TestDeps(now: DateTime(2026, 9, 26, 10)); // sábado
      await pumpBanco(tester, deps: deps);
      await tester.tap(find.byKey(const Key('nuevo-movimiento')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tipo-usufructoTotal')));
      await tester.pumpAndSettle();
      expect(
        textOf(tester, 'movimiento-error'),
        'El 26/09/2026 es sábado. El usufructo se carga solo en día hábil.',
      );
      await disposeTestApp(tester, deps);
    });
  });
}
