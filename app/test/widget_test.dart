import 'package:asistente/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/test_app.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_AR'));

  testWidgets('sin sesión muestra el login y al entrar va a Fichar', (
    tester,
  ) async {
    usePhoneSize(tester);
    final deps = TestDeps(userId: null);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: deps.overrides,
        child: const AsistenteApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('@sistente'), findsOneWidget);
    expect(find.byKey(const Key('login-submit')), findsOneWidget);
    // No hay registro abierto.
    expect(find.textContaining('Registr'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('login-email')),
      'agente@example.com',
    );
    await tester.enterText(find.byKey(const Key('login-password')), 'mala');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-error')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('login-password')),
      'clave-ficticia',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    // Primera vez: pide el agrupamiento (una sola vez) y después va a Fichar.
    expect(find.byKey(const Key('elegir-agrupamiento')), findsOneWidget);
    await tester.tap(find.byKey(const Key('agrupamiento-guardaparque')));
    await tester.pumpAndSettle();

    expect(find.text('Fichar ingreso'), findsOneWidget);
    expect(find.text('Jornada: 7:00 · Guardaparque'), findsOneWidget);
    expect(find.byKey(const Key('nav-bar')), findsOneWidget);

    await disposeTestApp(tester, deps);
  });
}
