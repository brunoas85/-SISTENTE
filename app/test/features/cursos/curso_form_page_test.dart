import 'package:asistente/data/attachments/attachment_picker.dart';
import 'package:asistente/data/cursos/curso.dart';
import 'package:asistente/data/cursos/cursos_repository.dart';
import 'package:asistente/data/local/app_database.dart';
import 'package:asistente/domain/domain.dart';
import 'package:asistente/features/cursos/curso_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

// Datos ficticios. Hoy (TestDeps): jueves 24/09/2026 08:02.
void main() {
  setUpAll(() => initializeDateFormatting('es_AR'));

  Future<TestDeps> pumpForm(
    WidgetTester tester, {
    TestDeps? deps,
    LocalCurso? curso,
  }) async {
    usePhoneSize(tester);
    final d = deps ?? TestDeps();
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: d.overrides,
        child: testMaterialApp(CursoFormPage(curso: curso)),
      ),
    );
    await tester.pumpAndSettle();
    return d;
  }

  CursosRepository repo(TestDeps deps) =>
      CursosRepository(deps.db, deps.photos, clock: () => deps.now);

  FilledButton guardar(WidgetTester tester) => tester.widget<FilledButton>(
    find.ancestor(
      of: find.text('Guardar'),
      matching: find.byWidgetPredicate((w) => w is FilledButton),
    ),
  );

  Future<void> elegirFecha(WidgetTester tester, String cual, String dia) async {
    await tester.ensureVisible(find.byKey(Key('fecha-$cual')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('fecha-$cual')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(dia));
    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();
  }

  testWidgets('sin actividad no se puede guardar', (tester) async {
    final deps = await pumpForm(tester);
    expect(find.text('Nuevo curso'), findsOneWidget);
    expect(guardar(tester).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('curso-actividad')), '   ');
    await tester.pumpAndSettle();
    expect(guardar(tester).onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('curso-actividad')),
      'Curso ficticio',
    );
    await tester.pumpAndSettle();
    expect(guardar(tester).onPressed, isNotNull);
    await disposeTestApp(tester, deps);
  });

  testWidgets('los créditos solo aceptan enteros', (tester) async {
    final deps = await pumpForm(tester);
    await tester.enterText(find.byKey(const Key('curso-creditos')), '2,5');
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.byKey(const Key('curso-creditos')),
    );
    expect(field.controller!.text, '25');
    await disposeTestApp(tester, deps);
  });

  testWidgets('fin anterior al inicio: lo explica y no deja guardar', (
    tester,
  ) async {
    final deps = await pumpForm(tester);
    await tester.enterText(
      find.byKey(const Key('curso-actividad')),
      'Curso ficticio',
    );
    await elegirFecha(tester, 'inicio', '20');
    await elegirFecha(tester, 'fin', '10');

    expect(
      tester.widget<Text>(find.byKey(const Key('curso-error'))).data,
      'La fecha de fin no puede ser anterior a la de inicio.',
    );
    expect(guardar(tester).onPressed, isNull);

    // Quitar la fecha de fin lo resuelve.
    await tester.tap(find.byKey(const Key('quitar-fecha-fin')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('curso-error')), findsNothing);
    expect(guardar(tester).onPressed, isNotNull);
    await disposeTestApp(tester, deps);
  });

  testWidgets('aprobado sin fechas: no deja guardar y pide la fecha de fin', (
    tester,
  ) async {
    final deps = await pumpForm(tester);
    await tester.enterText(
      find.byKey(const Key('curso-actividad')),
      'Curso ficticio',
    );
    await tester.ensureVisible(find.byKey(const Key('curso-estado')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('curso-estado')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('estado-aprobado')).last);
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('curso-error'))).data,
      'Para marcarlo aprobado, cargá la fecha de fin.',
    );
    expect(guardar(tester).onPressed, isNull);

    // Con la fecha de fin ya se puede guardar.
    await elegirFecha(tester, 'fin', '10');
    expect(find.byKey(const Key('curso-error')), findsNothing);
    expect(guardar(tester).onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('guardar-curso')));
    await tester.pumpAndSettle();
    final row = await deps.db.select(deps.db.cursos).getSingle();
    expect(row.estado, 'aprobado');
    expect(row.fechaFin, '2026-09-10');
    await disposeTestApp(tester, deps);
  });

  testWidgets('aprobado sin certificado ni IF: avisa pero guarda igual', (
    tester,
  ) async {
    final deps = await pumpForm(tester);
    await tester.enterText(
      find.byKey(const Key('curso-actividad')),
      'Curso ficticio',
    );
    await tester.enterText(find.byKey(const Key('curso-creditos')), '3');
    // Un aprobado necesita al menos una fecha.
    await elegirFecha(tester, 'fin', '10');
    await tester.ensureVisible(find.byKey(const Key('curso-estado')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('curso-estado')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('estado-aprobado')).last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('avisos-curso')), findsOneWidget);
    expect(
      find.textContaining('Aprobado sin certificado · Aprobado sin IF'),
      findsOneWidget,
    );

    // Con el IF queda solo el aviso del certificado.
    await tester.enterText(
      find.byKey(const Key('curso-if')),
      'IF-2026-00000001-APN-FICTICIO',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Aprobado sin IF'), findsNothing);
    expect(find.textContaining('Aprobado sin certificado'), findsOneWidget);

    expect(guardar(tester).onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('guardar-curso')));
    await tester.pumpAndSettle();

    final row = await deps.db.select(deps.db.cursos).getSingle();
    expect(row.actividad, 'Curso ficticio');
    expect(row.creditos, 3);
    expect(row.estado, 'aprobado');
    expect(row.fechaFin, '2026-09-10');
    expect(row.ifGde, 'IF-2026-00000001-APN-FICTICIO');
    expect(row.syncStatus, SyncStatus.pending);
    await disposeTestApp(tester, deps);
  });

  testWidgets('edición con certificado PDF: lo muestra y lo reemplaza', (
    tester,
  ) async {
    final deps = TestDeps();
    final c = await repo(deps).guardarCurso(
      userId: fakeUserId,
      draft: CursoDraft(
        actividad: 'Curso ficticio',
        portal: 'INAP',
        fechaFin: CalendarDate(2026, 4, 30),
        estado: CourseStatus.approved,
      ),
    );
    deps.picker.result = PickedFile(name: 'ficticio.pdf', bytes: fakePdf());
    await pumpForm(tester, deps: deps, curso: c);

    expect(find.text('Editar curso'), findsOneWidget);
    expect(find.byKey(const Key('borrar-curso')), findsOneWidget);
    expect(find.text('Fecha de fin: 30/04/2026'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('certificado-archivo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('certificado-archivo')));
    await tester.pumpAndSettle();
    expect(find.text('Certificado PDF'), findsOneWidget);
    expect(find.textContaining('Aprobado sin certificado'), findsNothing);

    await tester.tap(find.byKey(const Key('guardar-curso')));
    await tester.pumpAndSettle();
    final row = (await repo(deps).findCurso(c.id))!;
    expect(row.certificadoLocal, endsWith('_certificado.pdf'));
    expect(row.revision, 2);
    expect(deps.picker.calls, 1);
    await disposeTestApp(tester, deps);
  });
}
