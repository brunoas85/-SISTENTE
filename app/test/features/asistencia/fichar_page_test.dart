import 'package:asistente/data/local/app_database.dart';
import 'package:asistente/features/asistencia/asistencia_providers.dart';
import 'package:asistente/features/asistencia/fichar_page.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_AR'));

  Future<TestDeps> pumpFichar(
    WidgetTester tester, {
    TestDeps? deps,
    List<dynamic> extraOverrides = const [],
  }) async {
    usePhoneSize(tester);
    final d = deps ?? TestDeps();
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [...d.overrides, ...extraOverrides.cast()],
        child: testMaterialApp(const FicharPage()),
      ),
    );
    await tester.pumpAndSettle();
    return d;
  }

  testWidgets('sin fichadas: muestra el estado vacío y "Fichar ingreso"', (
    tester,
  ) async {
    final deps = await pumpFichar(tester);

    expect(find.text('Hoy, jueves 24/09/2026'), findsOneWidget);
    expect(find.byKey(const Key('sin-tramos')), findsOneWidget);
    expect(find.text('Sin fichadas'), findsOneWidget);
    expect(find.text('Fichar ingreso'), findsOneWidget);
    // Sin agrupamiento elegido la jornada es de 8 h.
    expect(find.text('Jornada: 8:00'), findsOneWidget);
    expect(find.byKey(const Key('aviso-no-laborable')), findsNothing);
    expect(find.byKey(const Key('saldo')), findsOneWidget);
    // El botón principal es grande (táctil ≥ 48 dp de sobra).
    expect(
      tester.getSize(find.byKey(const Key('boton-fichar'))).height,
      greaterThanOrEqualTo(96),
    );

    await disposeTestApp(tester, deps);
  });

  Future<void> insertar(
    TestDeps deps, {
    required String id,
    required String fecha,
    required int ingreso,
    int? egreso,
  }) => deps.db
      .into(deps.db.fichadas)
      .insert(
        FichadasCompanion.insert(
          id: id,
          userId: fakeUserId,
          fecha: fecha,
          ingresoMin: ingreso,
          egresoMin: Value(egreso),
          updatedAt: DateTime(2026, 9, 23),
          syncStatus: SyncStatus.synced,
        ),
      );

  testWidgets('camino feliz: fichar con foto, confirmar y queda pendiente', (
    tester,
  ) async {
    final deps = await pumpFichar(tester);

    // Toque 1: abre la confirmación directo (la cámara es opcional).
    await tester.tap(find.byKey(const Key('boton-fichar')));
    await tester.pumpAndSettle();
    expect(deps.capture.calls, 0);
    expect(find.text('Confirmar ingreso'), findsWidgets);
    expect(
      tester.widget<Text>(find.byKey(const Key('hora-elegida'))).data,
      '08:02',
    );

    await tester.tap(find.byKey(const Key('sacar-foto')));
    await tester.pumpAndSettle();
    expect(deps.capture.calls, 1);
    expect(find.byKey(const Key('quitar-foto')), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirmar-fichada')));
    await tester.pumpAndSettle();

    // De vuelta en Fichar: tramo abierto y el botón pasa a egreso.
    expect(find.text('Tramo abierto desde las 08:02'), findsOneWidget);
    expect(find.text('08:02 – abierto'), findsOneWidget);
    expect(find.text('Fichar egreso'), findsOneWidget);
    expect(find.byTooltip('Pendiente de sincronizar'), findsOneWidget);
    expect(find.textContaining('Ingreso fichado a las 08:02'), findsOneWidget);

    final rows = await deps.db.select(deps.db.fichadas).get();
    expect(rows.single.ingresoMin, 8 * 60 + 2);
    expect(rows.single.syncStatus, SyncStatus.pending);
    expect(rows.single.editado, isFalse);
    expect(deps.photos.files, hasLength(1));

    // Egreso a las 12:10, sin foto (2 toques).
    deps.now = DateTime(2026, 9, 24, 12, 10);
    await tester.tap(find.byKey(const Key('boton-fichar')));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar egreso'), findsWidgets);
    await tester.tap(find.byKey(const Key('confirmar-fichada')));
    await tester.pumpAndSettle();

    expect(find.text('08:02 – 12:10'), findsOneWidget);
    // Hoy la deuda es provisoria: se informa pero no resta.
    expect(find.text('Trabajado hoy: 4:08 · faltan 3:52'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('saldo')))
          .textSpan!
          .toPlainText(),
      'Banco · mes 0:00 · total 0:00',
    );
    expect(find.text('Fichar ingreso'), findsOneWidget);
    expect(deps.photos.files, hasLength(1));

    await disposeTestApp(tester, deps);
  });

  testWidgets('sin foto: si se cancela la cámara se puede confirmar igual', (
    tester,
  ) async {
    final deps = TestDeps();
    deps.capture.result = null;
    await pumpFichar(tester, deps: deps);

    await tester.tap(find.byKey(const Key('boton-fichar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sacar-foto')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('quitar-foto')), findsNothing);

    await tester.tap(find.byKey(const Key('confirmar-fichada')));
    await tester.pumpAndSettle();

    final rows = await deps.db.select(deps.db.fichadas).get();
    expect(rows.single.fotoIngresoLocal, isNull);
    expect(deps.photos.files, isEmpty);
    expect(find.text('Fichar egreso'), findsOneWidget);

    await disposeTestApp(tester, deps);
  });

  testWidgets('tramo abierto de ayer: hay que cerrarlo con la hora a mano', (
    tester,
  ) async {
    final deps = TestDeps();
    await insertar(deps, id: 'ayer', fecha: '2026-09-23', ingreso: 480);
    await pumpFichar(tester, deps: deps);

    expect(find.byKey(const Key('aviso-tramo-anterior')), findsOneWidget);
    expect(find.text('Cerrar tramo del 23/09/2026'), findsOneWidget);
    expect(find.text('Fichar ingreso'), findsNothing);

    await tester.tap(find.byKey(const Key('boton-fichar')));
    await tester.pumpAndSettle();

    // Sin hora propuesta: hay que elegirla antes de confirmar.
    expect(
      tester.widget<Text>(find.byKey(const Key('hora-elegida'))).data,
      '--:--',
    );
    final confirmar = find.byKey(const Key('confirmar-fichada'));
    expect(tester.widget<FilledButton>(confirmar).onPressed, isNull);

    await tester.tap(find.byKey(const Key('elegir-hora')));
    await tester.pumpAndSettle();
    // Modo teclado del selector de hora.
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final campos = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(campos.at(0), '16');
    await tester.enterText(campos.at(1), '05');
    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('hora-elegida'))).data,
      '16:05',
    );
    await tester.tap(confirmar);
    await tester.pumpAndSettle();

    final ayer = await (deps.db.select(
      deps.db.fichadas,
    )..where((f) => f.id.equals('ayer'))).getSingle();
    expect(ayer.egresoMin, 16 * 60 + 5);
    expect(ayer.egresoOriginalMin, isNull);
    expect(ayer.editado, isFalse);
    // Ahora sí se puede fichar hoy.
    expect(find.text('Fichar ingreso'), findsOneWidget);
    expect(find.byKey(const Key('aviso-tramo-anterior')), findsNothing);

    await disposeTestApp(tester, deps);
  });

  testWidgets('un ingreso que se superpone se bloquea y muestra el motivo', (
    tester,
  ) async {
    final deps = TestDeps(now: DateTime(2026, 9, 24, 11));
    // Tramo de hoy 08:00–12:00 cargado desde la PC; son las 11:00.
    await insertar(
      deps,
      id: 'pc',
      fecha: '2026-09-24',
      ingreso: 480,
      egreso: 720,
    );
    await pumpFichar(tester, deps: deps);

    await tester.tap(find.byKey(const Key('boton-fichar')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'El tramo 11:00–abierto se superpone con el tramo 08:00–12:00.',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('confirmar-fichada')))
          .onPressed,
      isNull,
    );

    await disposeTestApp(tester, deps);
  });

  testWidgets('error al leer la base: muestra el error y deja reintentar', (
    tester,
  ) async {
    final deps = await pumpFichar(
      tester,
      extraOverrides: [
        misFichadasProvider.overrideWith(
          (ref) => Stream<List<LocalFichada>>.error(StateError('base rota')),
        ),
      ],
    );

    expect(find.byKey(const Key('error-fichadas')), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Fichar ingreso'), findsNothing);

    await disposeTestApp(tester, deps);
  });

  group('días no laborables', () {
    testWidgets('sábado: el botón está deshabilitado y explica por qué', (
      tester,
    ) async {
      final deps = TestDeps(now: DateTime(2026, 9, 26, 9)); // sábado
      await pumpFichar(tester, deps: deps);

      expect(find.text('Hoy es sábado: no es día laborable'), findsOneWidget);
      final boton = find.byKey(const Key('boton-fichar'));
      expect(tester.widget<ButtonStyleButton>(boton).onPressed, isNull);
      await tester.tap(boton, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Confirmar ingreso'), findsNothing);

      await disposeTestApp(tester, deps);
    });

    testWidgets('feriado: muestra el nombre y no deja fichar', (tester) async {
      final deps = TestDeps(now: DateTime(2026, 10, 12, 9)); // lunes
      await deps.db
          .into(deps.db.feriados)
          .insert(
            FeriadosCompanion.insert(
              fecha: '2026-10-12',
              nombre: 'Feriado ficticio',
              tipo: const Value('trasladable'),
            ),
          );
      await pumpFichar(tester, deps: deps);

      expect(find.text('Hoy es feriado: Feriado ficticio'), findsOneWidget);
      expect(
        tester
            .widget<ButtonStyleButton>(find.byKey(const Key('boton-fichar')))
            .onPressed,
        isNull,
      );

      await disposeTestApp(tester, deps);
    });

    testWidgets('no laborable turístico: tampoco deja fichar', (tester) async {
      final deps = TestDeps(now: DateTime(2026, 10, 13, 9)); // martes
      await deps.db
          .into(deps.db.feriados)
          .insert(
            FeriadosCompanion.insert(
              fecha: '2026-10-13',
              nombre: 'Puente ficticio',
              tipo: const Value('no_laborable'),
            ),
          );
      await pumpFichar(tester, deps: deps);

      expect(
        find.text('Hoy es día no laborable: Puente ficticio'),
        findsOneWidget,
      );

      await disposeTestApp(tester, deps);
    });

    testWidgets('un sábado se puede cerrar el tramo abierto del viernes', (
      tester,
    ) async {
      final deps = TestDeps(now: DateTime(2026, 9, 26, 9));
      await insertar(deps, id: 'viernes', fecha: '2026-09-25', ingreso: 480);
      await pumpFichar(tester, deps: deps);

      expect(find.byKey(const Key('aviso-no-laborable')), findsNothing);
      final boton = find.byKey(const Key('boton-fichar'));
      expect(tester.widget<ButtonStyleButton>(boton).onPressed, isNotNull);
      expect(find.text('Cerrar tramo del 25/09/2026'), findsOneWidget);

      await tester.tap(boton);
      await tester.pumpAndSettle();
      expect(find.text('Confirmar egreso'), findsWidgets);

      await disposeTestApp(tester, deps);
    });
  });

  testWidgets('guardaparque: "faltan" y el a favor usan la jornada de 7 h', (
    tester,
  ) async {
    final deps = TestDeps(now: DateTime(2026, 9, 24, 13));
    await deps.db
        .into(deps.db.profiles)
        .insert(
          ProfilesCompanion.insert(
            userId: fakeUserId,
            agrupamiento: const Value('guardaparque'),
            updatedAt: DateTime(2026, 9, 23),
            syncStatus: SyncStatus.synced,
          ),
        );
    // Ayer: 08:00–15:30 (7:30 → 0:30 a favor). Hoy: 08:00–12:00.
    await insertar(
      deps,
      id: 'ayer',
      fecha: '2026-09-23',
      ingreso: 480,
      egreso: 930,
    );
    await insertar(
      deps,
      id: 'hoy',
      fecha: '2026-09-24',
      ingreso: 480,
      egreso: 720,
    );
    await pumpFichar(tester, deps: deps);

    expect(find.text('Jornada: 7:00 · Guardaparque'), findsOneWidget);
    expect(find.text('Trabajado hoy: 4:00 · faltan 3:00'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('saldo')))
          .textSpan!
          .toPlainText(),
      'Banco · mes 0:30 · total 0:30',
    );

    await disposeTestApp(tester, deps);
  });

  testWidgets('saldo negativo con formato -H:MM', (tester) async {
    final deps = TestDeps(now: DateTime(2026, 9, 24, 18));
    // Día anterior con 4 h trabajadas: deuda 4:00 (día hábil).
    await deps.db
        .into(deps.db.fichadas)
        .insert(
          FichadasCompanion.insert(
            id: 'ficticia-1',
            userId: fakeUserId,
            fecha: '2026-09-23',
            ingresoMin: 480,
            egresoMin: const Value(720),
            updatedAt: DateTime(2026, 9, 23),
            syncStatus: SyncStatus.synced,
          ),
        );
    // Hoy, tramo abierto (no computa).
    await deps.db
        .into(deps.db.fichadas)
        .insert(
          FichadasCompanion.insert(
            id: 'ficticia-2',
            userId: fakeUserId,
            fecha: '2026-09-24',
            ingresoMin: 480,
            updatedAt: DateTime(2026, 9, 24),
            syncStatus: SyncStatus.pending,
          ),
        );
    await pumpFichar(tester, deps: deps);

    final saldo = tester.widget<Text>(find.byKey(const Key('saldo')));
    expect(saldo.textSpan!.toPlainText(), 'Banco · mes -4:00 · total -4:00');

    await disposeTestApp(tester, deps);
  });
}
