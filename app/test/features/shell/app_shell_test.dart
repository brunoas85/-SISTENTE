import 'package:asistente/core/router/app_router.dart';
import 'package:asistente/data/local/app_database.dart';
import 'package:asistente/features/shell/app_shell.dart';
import 'package:asistente/main.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

// Navegación principal (decisión de Bruno, 2026-09-25): en el celular la
// barra tiene Fichar · Asistencia · Banco · Más; "Más" abre una hoja con
// Cursos y Feriados; Perfil va en el avatar del AppBar. La PC no cambia.
// Datos ficticios. Hoy (TestDeps): jueves 24/09/2026 08:02.
void main() {
  setUpAll(() => initializeDateFormatting('es_AR'));

  /// Tamaño en dp (con densidad 3, como un celular).
  void useSize(WidgetTester tester, double width, double height) {
    final dpr = width < Breakpoints.tablet ? 3.0 : 1.0;
    tester.view.physicalSize = Size(width * dpr, height * dpr);
    tester.view.devicePixelRatio = dpr;
    addTearDown(tester.view.reset);
  }

  Future<TestDeps> pumpApp(
    WidgetTester tester, {
    double width = 390,
    double height = 844,
  }) async {
    useSize(tester, width, height);
    final deps = TestDeps();
    await deps.db
        .into(deps.db.profiles)
        .insert(
          ProfilesCompanion.insert(
            userId: fakeUserId,
            agrupamiento: const Value('administrativo'),
            updatedAt: DateTime(2026, 9, 23),
            syncStatus: SyncStatus.synced,
          ),
        );
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: deps.overrides,
        child: const AsistenteApp(),
      ),
    );
    await tester.pumpAndSettle();
    return deps;
  }

  NavigationBar barra(WidgetTester tester) =>
      tester.widget<NavigationBar>(find.byKey(const Key('nav-bar')));

  List<String> etiquetasBarra(WidgetTester tester) => [
    for (final d in barra(tester).destinations)
      (d as NavigationDestination).label,
  ];

  Future<void> tocar(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  Future<void> irPorMas(WidgetTester tester, String path) async {
    await tocar(tester, 'nav-mas');
    expect(find.byKey(const Key('hoja-mas')), findsOneWidget);
    await tocar(tester, 'nav-$path');
    expect(find.byKey(const Key('hoja-mas')), findsNothing);
  }

  test('la barra, "Más" y el avatar salen de shellDestinations', () {
    List<String> paths(PhonePlacement p) => [
      for (final d in shellDestinations)
        if (d.phone == p) d.path,
    ];
    expect(paths(PhonePlacement.bar), [
      Routes.fichar,
      Routes.asistencia,
      Routes.banco,
    ]);
    expect(paths(PhonePlacement.more), [Routes.cursos, Routes.feriados]);
    expect(paths(PhonePlacement.account), [Routes.perfil]);
  });

  group('celular', () {
    testWidgets('la barra tiene 4 destinos: Fichar, Asistencia, Banco y Más', (
      tester,
    ) async {
      final deps = await pumpApp(tester);

      expect(find.byType(NavigationRail), findsNothing);
      expect(etiquetasBarra(tester), ['Fichar', 'Asistencia', 'Banco', 'Más']);
      expect(barra(tester).selectedIndex, 0);

      await disposeTestApp(tester, deps);
    });

    testWidgets('"Más" abre la hoja, navega a Cursos y a Feriados y queda '
        'seleccionado en esas rutas', (tester) async {
      final deps = await pumpApp(tester);

      // La hoja muestra solo las secciones que no entran en la barra.
      await tocar(tester, 'nav-mas');
      final hoja = find.byKey(const Key('hoja-mas'));
      expect(
        find.descendant(of: hoja, matching: find.byType(ListTile)),
        findsNWidgets(2),
      );
      expect(
        find.descendant(of: hoja, matching: find.text('Cursos')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: hoja, matching: find.text('Feriados')),
        findsOneWidget,
      );
      await tocar(tester, 'nav-/cursos');

      expect(find.byKey(const Key('sin-cursos')), findsOneWidget);
      expect(barra(tester).selectedIndex, 3);

      await irPorMas(tester, Routes.feriados);
      expect(find.byKey(const Key('sin-feriados')), findsOneWidget);
      expect(barra(tester).selectedIndex, 3);
      // En la hoja, la sección actual se ve seleccionada.
      await tocar(tester, 'nav-mas');
      expect(
        tester
            .widget<ListTile>(find.byKey(const Key('nav-/feriados')))
            .selected,
        isTrue,
      );
      expect(
        tester.widget<ListTile>(find.byKey(const Key('nav-/cursos'))).selected,
        isFalse,
      );
      await tester.tapAt(const Offset(195, 100)); // cierra la hoja
      await tester.pumpAndSettle();

      // Desde la barra se vuelve a una sección propia.
      await tocar(tester, 'nav-/banco');
      expect(find.byKey(const Key('saldo-banco')), findsOneWidget);
      expect(barra(tester).selectedIndex, 2);

      await disposeTestApp(tester, deps);
    });

    testWidgets('el avatar está en todas las pantallas y abre Perfil; se '
        'vuelve con la flecha', (tester) async {
      final deps = await pumpApp(tester);
      final avatar = find.byKey(const Key('nav-/perfil'));

      // Fichar, Asistencia y Banco (barra) y Cursos y Feriados (Más).
      expect(avatar, findsOneWidget);
      await tocar(tester, 'nav-/asistencia');
      expect(avatar, findsOneWidget);
      await tocar(tester, 'nav-/banco');
      expect(avatar, findsOneWidget);
      await irPorMas(tester, Routes.feriados);
      expect(avatar, findsOneWidget);
      await irPorMas(tester, Routes.cursos);
      expect(avatar, findsOneWidget);
      expect(tester.widget<IconButton>(avatar).tooltip, 'Perfil');

      await tocar(tester, 'nav-/perfil');

      expect(find.text('Agrupamiento'), findsWidgets);
      expect(find.byKey(const Key('nav-bar')), findsNothing);
      expect(avatar, findsNothing);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Vuelve a donde estaba, con la barra y "Más" seleccionado.
      expect(find.byKey(const Key('sin-cursos')), findsOneWidget);
      expect(barra(tester).selectedIndex, 3);

      await disposeTestApp(tester, deps);
    });

    testWidgets('Perfil abierto directo (por ejemplo, al recargar la web): '
        'la flecha vuelve a Fichar', (tester) async {
      final deps = await pumpApp(tester);
      GoRouter.of(tester.element(find.byKey(const Key('nav-bar'))))
          .go(Routes.perfil);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('nav-bar')), findsNothing);
      await tocar(tester, 'volver-de-perfil');
      expect(find.text('Fichar ingreso'), findsOneWidget);
      expect(barra(tester).selectedIndex, 0);

      await disposeTestApp(tester, deps);
    });

    for (final ancho in [360.0, 390.0]) {
      testWidgets('sin overflow a ${ancho.toInt()} dp en todas las '
          'secciones', (tester) async {
        final deps = await pumpApp(tester, width: ancho, height: 780);
        expect(tester.takeException(), isNull);

        for (final path in [Routes.asistencia, Routes.banco, Routes.fichar]) {
          await tocar(tester, 'nav-$path');
          expect(tester.takeException(), isNull, reason: path);
        }
        for (final path in [Routes.cursos, Routes.feriados]) {
          await tocar(tester, 'nav-mas');
          expect(tester.takeException(), isNull, reason: 'hoja Más');
          await tocar(tester, 'nav-$path');
          expect(tester.takeException(), isNull, reason: path);
        }
        await tocar(tester, 'nav-/perfil');
        expect(tester.takeException(), isNull, reason: 'perfil');

        // Los 4 destinos entran en pantalla, con área táctil de al menos
        // 48 dp. (El ancho real de las etiquetas no se puede medir acá: la
        // fuente de los tests hace cada letra tan ancha como alta.)
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        final destinos = find.descendant(
          of: find.byKey(const Key('nav-bar')),
          matching: find.byType(NavigationDestination),
        );
        expect(destinos, findsNWidgets(4));
        for (var i = 0; i < 4; i++) {
          final r = tester.getRect(destinos.at(i));
          expect(r.left, greaterThanOrEqualTo(0));
          expect(r.right, lessThanOrEqualTo(ancho));
          expect(r.width, greaterThanOrEqualTo(48));
          expect(r.height, greaterThanOrEqualTo(48));
        }
        expect(tester.takeException(), isNull);

        await disposeTestApp(tester, deps);
      });
    }
  });

  group('PC (sin cambios)', () {
    testWidgets('rail con las 6 secciones en orden, sin barra, sin "Más" ni '
        'avatar', (tester) async {
      final deps = await pumpApp(tester, width: 1280, height: 800);

      expect(find.byKey(const Key('nav-bar')), findsNothing);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);
      expect(
        [for (final d in rail.destinations) (d.label as Text).data],
        ['Fichar', 'Asistencia', 'Banco', 'Cursos', 'Feriados', 'Perfil'],
      );
      expect(find.byKey(const Key('nav-mas')), findsNothing);
      expect(find.byType(CircleAvatar), findsNothing);

      // Perfil es una sección del rail: sin flecha para volver.
      await tocar(tester, 'nav-/perfil');
      expect(
        tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .selectedIndex,
        5,
      );
      expect(find.byType(BackButton), findsNothing);
      await tocar(tester, 'nav-/cursos');
      expect(
        tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .selectedIndex,
        3,
      );
      expect(find.byKey(const Key('sin-cursos')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeTestApp(tester, deps);
    });

    testWidgets('en tablet (600–1023) también es el rail, sin avatar', (
      tester,
    ) async {
      final deps = await pumpApp(tester, width: 800, height: 1000);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isFalse);
      expect(rail.destinations, hasLength(6));
      expect(find.byKey(const Key('nav-bar')), findsNothing);
      expect(find.byType(CircleAvatar), findsNothing);
      await disposeTestApp(tester, deps);
    });
  });
}
