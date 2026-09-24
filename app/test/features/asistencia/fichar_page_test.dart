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
    expect(find.byKey(const Key('saldo')), findsOneWidget);
    // El botón principal es grande (táctil ≥ 48 dp de sobra).
    expect(
      tester.getSize(find.byKey(const Key('boton-fichar'))).height,
      greaterThanOrEqualTo(96),
    );

    await disposeTestApp(tester, deps);
  });

  testWidgets('camino feliz: foto, confirmar ingreso y queda pendiente', (
    tester,
  ) async {
    final deps = await pumpFichar(tester);

    await tester.tap(find.byKey(const Key('boton-fichar')));
    await tester.pumpAndSettle();

    expect(deps.capture.calls, 1);
    expect(find.text('Confirmar ingreso'), findsWidgets);
    expect(find.byKey(const Key('hora-elegida')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('hora-elegida'))).data,
      '08:02',
    );

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

    // Egreso a las 16:10 y el día queda cerrado.
    deps.now = DateTime(2026, 9, 24, 16, 10);
    await tester.tap(find.byKey(const Key('boton-fichar')));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar egreso'), findsWidgets);
    await tester.tap(find.byKey(const Key('confirmar-fichada')));
    await tester.pumpAndSettle();

    expect(find.text('08:02 – 16:10'), findsOneWidget);
    expect(find.text('Trabajado hoy: 8:08'), findsOneWidget);
    expect(find.text('Fichar ingreso'), findsOneWidget);

    await disposeTestApp(tester, deps);
  });

  testWidgets('si se cancela la cámara no se guarda nada', (tester) async {
    final deps = TestDeps();
    deps.capture.result = null;
    await pumpFichar(tester, deps: deps);

    await tester.tap(find.byKey(const Key('boton-fichar')));
    await tester.pumpAndSettle();

    expect(find.text('Confirmar ingreso'), findsNothing);
    expect(await deps.db.select(deps.db.fichadas).get(), isEmpty);

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
