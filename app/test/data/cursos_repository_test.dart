import 'dart:typed_data';

import 'package:asistente/data/attachments/attachment.dart';
import 'package:asistente/data/cursos/curso.dart';
import 'package:asistente/data/cursos/cursos_repository.dart';
import 'package:asistente/data/cursos/remote_curso.dart';
import 'package:asistente/data/local/app_database.dart';
import 'package:asistente/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

// Todo es ficticio. Hoy: jueves 24/09/2026.
void main() {
  late AppDatabase db;
  late InMemoryPhotoStore files;
  late CursosRepository repo;

  setUp(() {
    db = newTestDatabase();
    files = InMemoryPhotoStore();
    repo = CursosRepository(
      db,
      files,
      clock: steppingClock(DateTime(2026, 9, 24, 8)),
      newId: sequentialIds(),
    );
  });

  tearDown(() => db.close());

  Future<LocalCurso> guardar(
    CursoDraft draft, {
    CambioAdjunto certificado = const MantenerAdjunto(),
    String userId = fakeUserId,
  }) =>
      repo.guardarCurso(userId: userId, draft: draft, certificado: certificado);

  NuevoAdjunto pdf() =>
      NuevoAdjunto(PreparedAttachment(bytes: fakePdf(), extension: 'pdf'));

  test('alta: limpia espacios, queda pendiente y con revisión 1', () async {
    final c = await guardar(
      CursoDraft(
        actividad: '  Curso ficticio  ',
        codigo: ' IN-A3-00001 ',
        portal: 'INAP',
        fechaInicio: CalendarDate(2026, 3, 2),
        fechaFin: CalendarDate(2026, 4, 30),
        creditos: 3,
        estado: CourseStatus.approved,
        ifGde: '',
        observacion: '   ',
      ),
    );

    expect(c.id, '00000000-0000-4000-8000-000000000001');
    expect(c.actividad, 'Curso ficticio');
    expect(c.codigo, 'IN-A3-00001');
    expect(c.fechaInicio, '2026-03-02');
    expect(c.fechaFin, '2026-04-30');
    expect(c.creditos, 3);
    expect(c.estado, 'aprobado');
    expect(c.ifGde, isNull);
    expect(c.observacion, isNull);
    expect(c.revision, 1);
    expect(c.syncStatus, SyncStatus.pending);
    expect(c.toCourse().year, 2026);
  });

  test('edición: sube la revisión y vuelve a pendiente', () async {
    final c = await guardar(const CursoDraft(actividad: 'Curso ficticio'));
    await repo.markCursoSynced(c.id, c.revision);

    final editado = await guardar(c.toDraft(estado: CourseStatus.inProgress));

    expect(editado.id, c.id);
    expect(editado.status, CourseStatus.inProgress);
    expect(editado.revision, 2);
    expect(editado.syncStatus, SyncStatus.pending);
  });

  test('rechaza lo que el servidor no acepta', () async {
    await expectLater(
      guardar(const CursoDraft(actividad: '   ')),
      throwsA(isA<CursoInvalidoException>()),
    );
    await expectLater(
      guardar(const CursoDraft(actividad: 'Curso', creditos: -2)),
      throwsA(isA<CursoInvalidoException>()),
    );
    await expectLater(
      guardar(
        CursoDraft(
          actividad: 'Curso',
          fechaInicio: CalendarDate(2026, 5, 2),
          fechaFin: CalendarDate(2026, 5, 1),
        ),
      ),
      throwsA(
        isA<CursoInvalidoException>().having(
          (e) => e.message,
          'message',
          'La fecha de fin no puede ser anterior a la de inicio.',
        ),
      ),
    );
    expect(await db.select(db.cursos).get(), isEmpty);
  });

  test('un aprobado sin fechas no se guarda; con una fecha, sí', () async {
    final c = await guardar(const CursoDraft(actividad: 'Curso ficticio'));
    await expectLater(
      guardar(c.toDraft(estado: CourseStatus.approved)),
      throwsA(
        isA<CursoInvalidoException>().having(
          (e) => e.message,
          'message',
          'Para marcarlo aprobado, cargá la fecha de fin.',
        ),
      ),
    );
    expect((await repo.findCurso(c.id))!.status, CourseStatus.enrolled);

    final aprobado = await guardar(
      CursoDraft(
        id: c.id,
        actividad: 'Curso ficticio',
        fechaFin: CalendarDate(2026, 4, 30),
        estado: CourseStatus.approved,
      ),
    );
    expect(aprobado.status, CourseStatus.approved);
  });

  test('no edita cursos de otro usuario ni inexistentes', () async {
    final c = await guardar(const CursoDraft(actividad: 'Curso ficticio'));
    await expectLater(
      guardar(c.toDraft(), userId: 'otro-usuario-ficticio'),
      throwsA(isA<CursoInvalidoException>()),
    );
    await expectLater(
      guardar(const CursoDraft(id: 'no-existe', actividad: 'Curso')),
      throwsA(isA<CursoInvalidoException>()),
    );
  });

  group('certificado', () {
    test('se guarda local con la extensión y sin ruta remota', () async {
      final c = await guardar(
        const CursoDraft(actividad: 'Curso ficticio'),
        certificado: pdf(),
      );
      expect(c.certificadoLocal, 'mem:${c.id}_certificado.pdf');
      expect(c.certificadoPath, isNull);
      expect(c.tieneCertificado, isTrue);
      expect(c.certificadoEsPdf, isTrue);
      expect(await repo.readCertificado(c.certificadoLocal!), fakePdf());
    });

    test(
      'reemplazarlo borra el anterior y obliga a subirlo de nuevo',
      () async {
        final c = await guardar(
          const CursoDraft(actividad: 'Curso ficticio'),
          certificado: pdf(),
        );
        await repo.setRemoteCertificadoPath(c.id, 'ruta/ficticia.pdf');

        final nuevo = await guardar(
          c.toDraft(),
          certificado: NuevoAdjunto(
            PreparedAttachment(bytes: fakeJpeg(), extension: 'jpg'),
          ),
        );

        expect(nuevo.certificadoLocal, 'mem:${c.id}_certificado.jpg');
        expect(nuevo.certificadoPath, isNull);
        expect(files.files.keys, ['mem:${c.id}_certificado.jpg']);
      },
    );

    test('mantenerlo no lo toca', () async {
      final c = await guardar(
        const CursoDraft(actividad: 'Curso ficticio'),
        certificado: pdf(),
      );
      final editado = await guardar(c.toDraft(estado: CourseStatus.inProgress));
      expect(editado.certificadoLocal, c.certificadoLocal);
    });

    test('quitarlo borra el archivo y la ruta', () async {
      final c = await guardar(
        const CursoDraft(actividad: 'Curso ficticio'),
        certificado: pdf(),
      );
      await repo.setRemoteCertificadoPath(c.id, 'ruta/ficticia.pdf');
      final sin = await guardar(
        c.toDraft(),
        certificado: const QuitarAdjunto(),
      );
      expect(sin.certificadoLocal, isNull);
      expect(sin.certificadoPath, isNull);
      expect(files.files, isEmpty);
    });

    test('más de 10 MB no se acepta', () async {
      await expectLater(
        guardar(
          const CursoDraft(actividad: 'Curso ficticio'),
          certificado: NuevoAdjunto(
            PreparedAttachment(
              bytes: Uint8List(attachmentMaxBytes + 1),
              extension: 'pdf',
            ),
          ),
        ),
        throwsA(isA<CursoInvalidoException>()),
      );
    });
  });

  test('watchCursos: activos del usuario, los más recientes primero y los '
      'sin fecha al final', () async {
    await guardar(
      CursoDraft(actividad: 'Viejo', fechaInicio: CalendarDate(2025, 3, 1)),
    );
    await guardar(const CursoDraft(actividad: 'Sin fecha'));
    await guardar(
      CursoDraft(actividad: 'Nuevo', fechaInicio: CalendarDate(2026, 3, 1)),
    );
    final borrado = await guardar(const CursoDraft(actividad: 'Borrado'));
    await repo.borrarCurso(userId: fakeUserId, id: borrado.id);
    await guardar(
      const CursoDraft(actividad: 'De otro'),
      userId: 'otro-usuario-ficticio',
    );

    final lista = await repo.watchCursos(fakeUserId).first;
    expect(lista.map((c) => c.actividad), ['Nuevo', 'Viejo', 'Sin fecha']);
  });

  test('borrado lógico: marca deleted_at, queda pendiente y no se borra dos '
      'veces', () async {
    final c = await guardar(const CursoDraft(actividad: 'Curso ficticio'));
    await repo.markCursoSynced(c.id, c.revision);

    await repo.borrarCurso(userId: fakeUserId, id: c.id);

    final b = (await repo.findCurso(c.id))!;
    expect(b.deletedAt, isNotNull);
    expect(b.revision, 2);
    expect(b.syncStatus, SyncStatus.pending);
    await expectLater(
      repo.borrarCurso(userId: fakeUserId, id: c.id),
      throwsA(isA<CursoInvalidoException>()),
    );
    await expectLater(
      guardar(c.toDraft()),
      throwsA(isA<CursoInvalidoException>()),
    );
  });

  test('markCursoSynced solo si la revisión no cambió', () async {
    final c = await guardar(const CursoDraft(actividad: 'Curso ficticio'));
    await guardar(c.toDraft(estado: CourseStatus.inProgress)); // revisión 2
    expect(await repo.markCursoSynced(c.id, 1), isFalse);
    expect((await repo.findCurso(c.id))!.syncStatus, SyncStatus.pending);
    expect(await repo.markCursoSynced(c.id, 2), isTrue);
    expect((await repo.unsyncedCursos(fakeUserId)), isEmpty);
  });

  group('applyRemoteCursos', () {
    test('no pisa cambios locales sin subir', () async {
      final c = await guardar(const CursoDraft(actividad: 'Local'));
      await repo.applyRemoteCursos([
        RemoteCurso(id: c.id, userId: fakeUserId, actividad: 'Remoto'),
      ]);
      expect((await repo.findCurso(c.id))!.actividad, 'Local');
    });

    test('aplica los sincronizados y conserva el certificado local si es el '
        'mismo', () async {
      final c = await guardar(
        const CursoDraft(actividad: 'Local'),
        certificado: pdf(),
      );
      await repo.setRemoteCertificadoPath(c.id, 'ruta/ficticia.pdf');
      await repo.markCursoSynced(c.id, c.revision);

      await repo.applyRemoteCursos([
        RemoteCurso(
          id: c.id,
          userId: fakeUserId,
          actividad: 'Remoto',
          estado: 'aprobado',
          creditos: 5,
          certificadoPath: 'ruta/ficticia.pdf',
          updatedAt: DateTime.utc(2026, 9, 24, 12),
        ),
      ]);

      final r = (await repo.findCurso(c.id))!;
      expect(r.actividad, 'Remoto');
      expect(r.status, CourseStatus.approved);
      expect(r.creditos, 5);
      expect(r.certificadoLocal, c.certificadoLocal);
      expect(r.syncStatus, SyncStatus.synced);
    });

    test(
      'si el certificado remoto cambió, descarta la referencia local',
      () async {
        final c = await guardar(
          const CursoDraft(actividad: 'Local'),
          certificado: pdf(),
        );
        await repo.setRemoteCertificadoPath(c.id, 'ruta/vieja.pdf');
        await repo.markCursoSynced(c.id, c.revision);

        await repo.applyRemoteCursos([
          RemoteCurso(
            id: c.id,
            userId: fakeUserId,
            actividad: 'Local',
            certificadoPath: 'ruta/nueva.jpg',
          ),
        ]);

        final r = (await repo.findCurso(c.id))!;
        expect(r.certificadoLocal, isNull);
        expect(r.certificadoPath, 'ruta/nueva.jpg');
      },
    );
  });
}
