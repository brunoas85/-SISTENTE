import 'package:asistente/data/banco/banco_repository.dart';
import 'package:asistente/data/local/app_database.dart';
import 'package:asistente/features/banco_horas/banco_providers.dart';
import 'package:asistente/features/banco_horas/tipos_documento_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_AR'));

  Future<TestDeps> pumpTipos(
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
        child: testMaterialApp(const TiposDocumentoPage()),
      ),
    );
    await tester.pumpAndSettle();
    return d;
  }

  testWidgets('catálogo vacío: sugiere FSOLI y FOESC y crea solo los '
      'confirmados', (tester) async {
    final deps = await pumpTipos(tester);

    expect(find.byKey(const Key('sin-tipos')), findsOneWidget);
    // No se crea nada solo.
    expect(await deps.db.select(deps.db.tiposDocumentoGde).get(), isEmpty);

    await tester.tap(find.byKey(const Key('sugerir-tipos')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sugerencia-FOESC')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar-sugerencias')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tipo-FSOLI')), findsOneWidget);
    expect(find.byKey(const Key('tipo-FOESC')), findsNothing);
    final rows = await deps.db.select(deps.db.tiposDocumentoGde).get();
    expect(rows.single.codigo, 'FSOLI');
    expect(rows.single.syncStatus, SyncStatus.pending);

    await disposeTestApp(tester, deps);
  });

  testWidgets('alta, código repetido sin distinguir mayúsculas y borrado', (
    tester,
  ) async {
    final deps = TestDeps();
    await BancoRepository(
      deps.db,
      deps.photos,
    ).guardarTipo(userId: fakeUserId, codigo: 'FSOLI');
    await pumpTipos(tester, deps: deps);

    await tester.tap(find.byKey(const Key('nuevo-tipo')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('tipo-codigo')), 'fsoli');
    await tester.pumpAndSettle();
    expect(
      find.text('Ya hay un tipo de documento con el código fsoli.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('guardar-tipo')))
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byKey(const Key('tipo-codigo')), 'FOESC');
    await tester.enterText(
      find.byKey(const Key('tipo-descripcion')),
      'Descripción ficticia',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('guardar-tipo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tipo-FOESC')), findsOneWidget);
    expect(find.text('Descripción ficticia'), findsOneWidget);

    await tester.tap(find.byKey(const Key('borrar-tipo-FSOLI')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar-borrar-tipo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tipo-FSOLI')), findsNothing);

    await disposeTestApp(tester, deps);
  });

  testWidgets('error al leer el catálogo', (tester) async {
    final deps = await pumpTipos(
      tester,
      extraOverrides: [
        tiposDocumentoProvider.overrideWith(
          (ref) => Stream<List<LocalTipoDocumento>>.error('rota (ficticio)'),
        ),
      ],
    );
    expect(find.byKey(const Key('error-tipos')), findsOneWidget);
    await disposeTestApp(tester, deps);
  });
}
