import 'package:asistente/data/fichadas/remote_fichada.dart';
import 'package:asistente/data/local/app_database.dart';
import 'package:asistente/domain/domain.dart';
import 'package:asistente/features/asistencia/asistencia_providers.dart';
import 'package:asistente/features/feriados/feriados_page.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../support/test_app.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_AR'));

  // Feriados ficticios (nombres inventados, no el calendario oficial).
  Future<void> cargar(TestDeps deps) => deps.db.batch(
    (b) => b.insertAll(deps.db.feriados, [
      FeriadosCompanion.insert(
        fecha: '2026-07-09',
        nombre: 'Feriado ficticio de julio',
      ),
      FeriadosCompanion.insert(
        fecha: '2026-07-10',
        nombre: 'Puente ficticio',
        tipo: const Value('no_laborable'),
      ),
      FeriadosCompanion.insert(
        fecha: '2026-10-12',
        nombre: 'Feriado ficticio de octubre',
        tipo: const Value('trasladable'),
      ),
      FeriadosCompanion.insert(
        fecha: '2026-12-25',
        nombre: 'Feriado ficticio de diciembre',
      ),
    ]),
  );

  Future<TestDeps> pumpFeriados(
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
        child: testMaterialApp(const FeriadosPage()),
      ),
    );
    await tester.pumpAndSettle();
    return d;
  }

  testWidgets('lista por mes, con tipo, día de la semana y el próximo '
      'destacado', (tester) async {
    final deps = TestDeps(); // hoy: jueves 24/09/2026
    await cargar(deps);
    await pumpFeriados(tester, deps: deps);

    expect(find.text('Feriados 2026'), findsOneWidget);
    expect(find.text('Julio'), findsOneWidget);
    expect(find.text('Octubre'), findsOneWidget);
    expect(find.text('Jueves 09/07/2026 · Inamovible'), findsOneWidget);
    expect(
      find.text('Viernes 10/07/2026 · No laborable turístico'),
      findsOneWidget,
    );

    // El próximo feriado es el 12/10 (lunes, trasladable), faltan 18 días.
    final proximo = find.byKey(const Key('proximo-feriado'));
    expect(proximo, findsOneWidget);
    expect(
      find.descendant(
        of: proximo,
        matching: find.text('Próximo feriado · Faltan 18 días'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: proximo,
        matching: find.text('Feriado ficticio de octubre'),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<ListTile>(find.byKey(const Key('feriado-2026-10-12')))
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<ListTile>(find.byKey(const Key('feriado-2026-07-09')))
          .selected,
      isFalse,
    );

    await disposeTestApp(tester, deps);
  });

  testWidgets(
    'vacío: ofrece sincronizar; sin red lo avisa y con red los baja',
    (tester) async {
      final deps = await pumpFeriados(tester);

      expect(find.byKey(const Key('sin-feriados')), findsOneWidget);
      // La primera pasada del sync corrió sin red.
      expect(find.byKey(const Key('feriados-sin-conexion')), findsOneWidget);

      deps.remote
        ..online = true
        ..feriados = const [
          RemoteFeriado(fecha: '2026-11-23', nombre: 'Feriado ficticio'),
        ];
      await tester.tap(find.byKey(const Key('sincronizar-feriados')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sin-feriados')), findsNothing);
      expect(find.text('Feriado ficticio'), findsWidgets);
      expect(find.text('Noviembre'), findsOneWidget);

      await disposeTestApp(tester, deps);
    },
  );

  testWidgets('error al leer la base: muestra el error y deja reintentar', (
    tester,
  ) async {
    final deps = await pumpFeriados(
      tester,
      extraOverrides: [
        feriadosLocalesProvider.overrideWith(
          (ref) => Stream<List<Holiday>>.error(StateError('base rota')),
        ),
      ],
    );

    expect(find.byKey(const Key('error-feriados')), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    await disposeTestApp(tester, deps);
  });
}
