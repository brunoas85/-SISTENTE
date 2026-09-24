import 'package:asistente/data/local/app_database.dart';
import 'package:asistente/data/perfil/perfil_repository.dart';
import 'package:asistente/domain/domain.dart';
import 'package:asistente/features/perfil/perfil_page.dart';
import 'package:asistente/features/perfil/perfil_providers.dart';
import 'package:asistente/main.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_AR'));

  Future<void> guardarPerfil(TestDeps deps, String? agrupamiento) => deps.db
      .into(deps.db.profiles)
      .insert(
        ProfilesCompanion.insert(
          userId: fakeUserId,
          agrupamiento: Value(agrupamiento),
          updatedAt: DateTime(2026, 9, 23),
          syncStatus: SyncStatus.synced,
        ),
      );

  Future<TestDeps> pumpPerfil(
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
        child: testMaterialApp(const PerfilPage()),
      ),
    );
    await tester.pumpAndSettle();
    return d;
  }

  group('Perfil', () {
    testWidgets('sin agrupamiento: lo explica y al elegir queda pendiente', (
      tester,
    ) async {
      final deps = await pumpPerfil(tester);

      expect(
        find.text(
          'Todavía no lo elegiste. Mientras tanto la jornada es de 8:00 h.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('agrupamiento-guardaparque')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Tu jornada es de 7:00 h'), findsOneWidget);
      expect(find.byTooltip('Pendiente de sincronizar'), findsOneWidget);
      final row = await deps.db.select(deps.db.profiles).getSingle();
      expect(row.agrupamiento, 'guardaparque');
      expect(row.syncStatus, SyncStatus.pending);

      await disposeTestApp(tester, deps);
    });

    testWidgets('se puede cambiar el agrupamiento elegido', (tester) async {
      final deps = TestDeps();
      await guardarPerfil(deps, 'guardaparque_apoyo');
      await pumpPerfil(tester, deps: deps);

      expect(find.textContaining('Tu jornada es de 7:00 h'), findsOneWidget);
      await tester.tap(find.byKey(const Key('agrupamiento-administrativo')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tu jornada es de 8:00 h'), findsOneWidget);

      await disposeTestApp(tester, deps);
    });

    testWidgets('error al leer el perfil: muestra el error', (tester) async {
      final deps = await pumpPerfil(
        tester,
        extraOverrides: [
          miPerfilProvider.overrideWith(
            (ref) => Stream<Perfil?>.error(StateError('base rota')),
          ),
        ],
      );
      expect(find.byKey(const Key('error-perfil')), findsOneWidget);
      await disposeTestApp(tester, deps);
    });
  });

  group('App con sesión', () {
    Future<void> pumpApp(WidgetTester tester, TestDeps deps) async {
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: deps.overrides,
          child: const AsistenteApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('perfil sin agrupamiento: lo pide una vez al entrar', (
      tester,
    ) async {
      usePhoneSize(tester);
      final deps = TestDeps();
      await guardarPerfil(deps, null);
      await pumpApp(tester, deps);

      expect(find.byKey(const Key('elegir-agrupamiento')), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('agrupamiento-guardaparque_apoyo')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('elegir-agrupamiento')), findsNothing);
      expect(
        find.text('Jornada: 7:00 · Guardaparque de apoyo'),
        findsOneWidget,
      );

      // Desde la navegación se llega a Perfil y a Feriados.
      await tester.tap(find.byKey(const Key('nav-/perfil')));
      await tester.pumpAndSettle();
      expect(find.text('Perfil'), findsWidgets);
      await tester.tap(find.byKey(const Key('nav-/feriados')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sin-feriados')), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav-/banco')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('saldo-banco')), findsOneWidget);

      await disposeTestApp(tester, deps);
    });

    testWidgets('con agrupamiento elegido no lo pide', (tester) async {
      usePhoneSize(tester);
      final deps = TestDeps();
      await guardarPerfil(deps, Agrupamiento.administrativo.dbValue);
      await pumpApp(tester, deps);

      expect(find.byKey(const Key('elegir-agrupamiento')), findsNothing);
      expect(find.text('Fichar ingreso'), findsOneWidget);
      expect(find.text('Jornada: 8:00 · Administrativo'), findsOneWidget);

      await disposeTestApp(tester, deps);
    });

    testWidgets('en escritorio la navegación es un NavigationRail', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final deps = TestDeps();
      await guardarPerfil(deps, 'administrativo');
      await pumpApp(tester, deps);

      expect(find.byKey(const Key('nav-rail')), findsOneWidget);
      expect(find.byKey(const Key('nav-bar')), findsNothing);
      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
        isTrue,
      );

      await disposeTestApp(tester, deps);
    });
  });
}
