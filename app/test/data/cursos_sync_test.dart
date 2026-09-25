import 'package:asistente/data/attachments/attachment.dart';
import 'package:asistente/data/cursos/curso.dart';
import 'package:asistente/data/cursos/cursos_repository.dart';
import 'package:asistente/data/cursos/remote_curso.dart';
import 'package:asistente/data/fichadas/fichadas_repository.dart';
import 'package:asistente/data/local/app_database.dart';
import 'package:asistente/data/perfil/perfil_repository.dart';
import 'package:asistente/data/sync/cursos_sync.dart';
import 'package:asistente/data/sync/sync_service.dart';
import 'package:asistente/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

// Todo es ficticio. Hoy: jueves 24/09/2026.
void main() {
  late AppDatabase db;
  late InMemoryPhotoStore files;
  late CursosRepository cursos;
  late FakeCursosRemote remote;
  late SyncService sync;

  setUp(() {
    db = newTestDatabase();
    files = InMemoryPhotoStore();
    final clock = steppingClock(DateTime(2026, 9, 24, 8));
    cursos = CursosRepository(db, files, clock: clock, newId: sequentialIds());
    remote = FakeCursosRemote();
    sync = SyncService(
      repository: FichadasRepository(db, files, clock: clock),
      perfiles: PerfilRepository(db, clock: clock),
      remote: FakeFichadasRemote(),
      cursos: CursosSync(repository: cursos, remote: remote, clock: clock),
      clock: clock,
    );
  });

  tearDown(() => db.close());

  Future<LocalCurso> curso({
    CalendarDate? inicio,
    CalendarDate? fin,
    CourseStatus estado = CourseStatus.approved,
    CambioAdjunto certificado = const MantenerAdjunto(),
  }) => cursos.guardarCurso(
    userId: fakeUserId,
    draft: CursoDraft(
      actividad: 'Curso ficticio',
      codigo: 'IN-A3-00001',
      portal: 'INAP',
      fechaInicio: inicio,
      fechaFin: fin,
      creditos: 3,
      estado: estado,
      ifGde: 'IF-2026-00000001-APN-FICTICIO',
    ),
    certificado: certificado,
  );

  NuevoAdjunto pdf() =>
      NuevoAdjunto(PreparedAttachment(bytes: fakePdf(), extension: 'pdf'));

  test('ruta del certificado: {user_id}/{yyyy}/{id}_certificado.{ext}', () {
    expect(
      certificadoCursoPath(
        userId: fakeUserId,
        year: 2026,
        cursoId: 'abc',
        extension: 'pdf',
      ),
      '$fakeUserId/2026/abc_certificado.pdf',
    );
  });

  test('sin certificado: solo el upsert, con certificado_path null', () async {
    final c = await curso(fin: CalendarDate(2026, 4, 30));

    final result = await sync.sync(fakeUserId);

    expect(result.offline, isFalse);
    expect(result.uploaded, 1);
    expect(remote.calls, ['curso:${c.id}']);
    expect(remote.storage, isEmpty);
    final json = remote.cursos[c.id]!.toJson();
    expect(json['certificado_path'], isNull);
    expect(json['actividad'], 'Curso ficticio');
    expect(json['estado'], 'aprobado');
    expect(json['creditos'], 3);
    expect(json['fecha_fin'], '2026-04-30');
    expect(json['if_gde'], 'IF-2026-00000001-APN-FICTICIO');
    expect((await cursos.findCurso(c.id))!.syncStatus, SyncStatus.synced);
  });

  test('con certificado PDF: sube primero el archivo (año de la fecha de '
      'fin) y después la fila', () async {
    final c = await curso(
      inicio: CalendarDate(2025, 12, 1),
      fin: CalendarDate(2026, 2, 15),
      certificado: pdf(),
    );

    await sync.sync(fakeUserId);

    final path = '$fakeUserId/2026/${c.id}_certificado.pdf';
    expect(remote.calls, ['upload:$path', 'curso:${c.id}']);
    expect(remote.contentTypes[path], 'application/pdf');
    expect(remote.storage[path], files.files[c.certificadoLocal]);
    expect(remote.cursos[c.id]!.certificadoPath, path);
    final local = (await cursos.findCurso(c.id))!;
    expect(local.syncStatus, SyncStatus.synced);
    expect(local.certificadoPath, path);
  });

  test(
    'con certificado imagen y solo inicio: año del inicio, image/jpeg',
    () async {
      final c = await curso(
        inicio: CalendarDate(2025, 5, 1),
        certificado: NuevoAdjunto(
          PreparedAttachment(bytes: fakeJpeg(), extension: 'jpg'),
        ),
      );
      await sync.sync(fakeUserId);
      final path = '$fakeUserId/2025/${c.id}_certificado.jpg';
      expect(remote.contentTypes[path], 'image/jpeg');
      expect(remote.cursos[c.id]!.certificadoPath, path);
    },
  );

  test('sin fechas: el certificado va al año de la subida', () async {
    // Un aprobado necesita fecha: sin fechas solo puede estar sin aprobar.
    final c = await curso(estado: CourseStatus.inProgress, certificado: pdf());
    await sync.sync(fakeUserId);
    expect(
      remote.cursos[c.id]!.certificadoPath,
      '$fakeUserId/2026/${c.id}_certificado.pdf',
    );
  });

  test('sin red: todo queda pendiente y sin errores', () async {
    final c = await curso(fin: CalendarDate(2026, 4, 30), certificado: pdf());
    remote.online = false;

    final result = await sync.sync(fakeUserId);

    expect(result.offline, isTrue);
    final local = (await cursos.findCurso(c.id))!;
    expect(local.syncStatus, SyncStatus.pending);
    expect(local.syncError, isNull);
    expect(local.certificadoPath, isNull);
    expect(remote.calls, isEmpty);
  });

  test('un rechazo deja el curso en error y se reintenta solo', () async {
    final c = await curso(fin: CalendarDate(2026, 4, 30));
    remote.rejectCurso[c.id] = 'Regla ficticia';

    var result = await sync.sync(fakeUserId);
    expect(result.failed, 1);
    var local = (await cursos.findCurso(c.id))!;
    expect(local.syncStatus, SyncStatus.error);
    expect(local.syncError, 'Curso "Curso ficticio": Regla ficticia');

    remote.rejectCurso.clear();
    result = await sync.sync(fakeUserId);
    local = (await cursos.findCurso(c.id))!;
    expect(local.syncStatus, SyncStatus.synced);
    expect(local.syncError, isNull);
  });

  test(
    'si el certificado ya subió, no se vuelve a subir al reintentar',
    () async {
      final c = await curso(fin: CalendarDate(2026, 4, 30), certificado: pdf());
      remote.rejectCurso[c.id] = 'Regla ficticia';
      await sync.sync(fakeUserId);
      remote.rejectCurso.clear();
      remote.calls.clear();

      await sync.sync(fakeUserId);

      expect(remote.calls, ['curso:${c.id}']);
    },
  );

  test(
    'si falta el certificado local sube la fila y avisa con error',
    () async {
      final c = await curso(fin: CalendarDate(2026, 4, 30), certificado: pdf());
      files.files.clear();

      await sync.sync(fakeUserId);

      expect(remote.cursos[c.id]!.certificadoPath, isNull);
      final local = (await cursos.findCurso(c.id))!;
      expect(local.syncStatus, SyncStatus.error);
      expect(local.syncError, contains('No se encontró el certificado'));
    },
  );

  test('un curso borrado sube deleted_at sin subir el certificado', () async {
    final c = await curso(fin: CalendarDate(2026, 4, 30), certificado: pdf());
    await cursos.borrarCurso(userId: fakeUserId, id: c.id);

    await sync.sync(fakeUserId);

    expect(remote.calls, ['curso:${c.id}']);
    expect(remote.cursos[c.id]!.deletedAt, isNotNull);
    expect((await cursos.findCurso(c.id))!.syncStatus, SyncStatus.synced);
  });

  test('baja cursos de otro dispositivo con cursor por updated_at', () async {
    remote.putFromOtherDevice(
      const RemoteCurso(
        id: 'desde-la-pc',
        userId: fakeUserId,
        actividad: 'Curso cargado en la PC',
        estado: 'en_curso',
        fechaInicio: '2026-08-01',
        creditos: 2,
      ),
    );

    final result = await sync.sync(fakeUserId);

    expect(result.downloaded, 1);
    final local = (await cursos.findCurso('desde-la-pc'))!;
    expect(local.status, CourseStatus.inProgress);
    expect(local.syncStatus, SyncStatus.synced);
    expect(
      await cursos.readState(CursosSync.pulledAtKey(fakeUserId)),
      isNotNull,
    );

    await sync.sync(fakeUserId);
    expect(remote.lastSince, remote.cursos['desde-la-pc']!.updatedAt);
  });

  test('gana el último que sincroniza: lo local sin subir no se pisa y '
      'después se sube', () async {
    final c = await curso(fin: CalendarDate(2026, 4, 30));
    await sync.sync(fakeUserId);
    // Otro dispositivo lo cambió y acá también (sin subir todavía).
    remote.putFromOtherDevice(
      RemoteCurso.fromLocal((await cursos.findCurso(c.id))!)
          .withUpdatedAt(DateTime.utc(2026)),
    );
    await cursos.guardarCurso(
      userId: fakeUserId,
      draft: (await cursos.findCurso(c.id))!
          .toDraft(estado: CourseStatus.abandoned),
    );

    await sync.sync(fakeUserId);

    expect(remote.cursos[c.id]!.estado, 'abandonado');
    expect((await cursos.findCurso(c.id))!.status, CourseStatus.abandoned);
  });
}
