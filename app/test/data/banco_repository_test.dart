import 'package:asistente/data/attachments/attachment.dart';
import 'package:asistente/data/banco/banco_repository.dart';
import 'package:asistente/data/banco/movimiento.dart';
import 'package:asistente/data/banco/remote_banco.dart';
import 'package:asistente/data/local/app_database.dart';
import 'package:asistente/domain/domain.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

// Todo es ficticio. Hoy: jueves 24/09/2026.
final sabadoPasado = CalendarDate(2026, 9, 19);
final lunes = CalendarDate(2026, 9, 21);
final martes = CalendarDate(2026, 9, 22);
final hoy = CalendarDate(2026, 9, 24);
final viernes = CalendarDate(2026, 9, 25);
final lunesQueViene = CalendarDate(2026, 9, 28);
final martesQueViene = CalendarDate(2026, 9, 29);

void main() {
  late AppDatabase db;
  late InMemoryPhotoStore files;
  late BancoRepository repo;

  setUp(() {
    db = newTestDatabase();
    files = InMemoryPhotoStore();
    repo = BancoRepository(
      db,
      files,
      clock: steppingClock(DateTime(2026, 9, 24, 8)),
      newId: sequentialIds(),
    );
  });

  tearDown(() => db.close());

  Future<void> fichada(CalendarDate d, int ingreso, int egreso) => db
      .into(db.fichadas)
      .insert(
        FichadasCompanion.insert(
          id: 'fichada-$d',
          userId: fakeUserId,
          fecha: d.toString(),
          ingresoMin: ingreso,
          egresoMin: Value(egreso),
          updatedAt: DateTime(2026, 9, 20),
          syncStatus: SyncStatus.synced,
        ),
      );

  Future<void> perfil(String agrupamiento) => db
      .into(db.profiles)
      .insert(
        ProfilesCompanion.insert(
          userId: fakeUserId,
          agrupamiento: Value(agrupamiento),
          updatedAt: DateTime(2026, 9, 20),
          syncStatus: SyncStatus.synced,
        ),
      );

  Future<LocalMovimiento> guardar(
    TipoMovimiento tipo,
    CalendarDate fecha, {
    int? minutos,
    String? id,
    String? tipoDocumentoId,
    String? numeroGde,
    CambioAdjunto adjunto = const MantenerAdjunto(),
  }) => repo.guardarMovimiento(
    userId: fakeUserId,
    draft: MovimientoDraft(
      id: id,
      tipo: tipo,
      fecha: fecha,
      minutos: minutos,
      tipoDocumentoId: tipoDocumentoId,
      numeroGde: numeroGde,
    ),
    adjunto: adjunto,
  );

  Matcher rechazo(Object mensaje) => throwsA(
    isA<BancoInvalidoException>().having((e) => e.message, 'message', mensaje),
  );

  group('acumulación', () {
    test('se puede cargar en un sábado y queda pendiente', () async {
      final m = await guardar(
        TipoMovimiento.acumulacion,
        sabadoPasado,
        minutos: 240,
        numeroGde: '  ',
      );
      expect(m.tipo, 'acumulacion');
      expect(m.alcance, isNull); // CHECK banco_alcance_solo_usufructo
      expect(m.fecha, '2026-09-19');
      expect(m.minutos, 240);
      expect(m.estado, 'vigente');
      expect(m.numeroGde, isNull);
      expect(m.syncStatus, SyncStatus.pending);
      expect(m.revision, 1);
    });

    test('sin minutos o con más de 24:00 se rechaza', () async {
      await expectLater(
        guardar(TipoMovimiento.acumulacion, sabadoPasado),
        rechazo(contains('H:MM')),
      );
      await expectLater(
        guardar(TipoMovimiento.acumulacion, sabadoPasado, minutos: 1441),
        rechazo(contains('24:00')),
      );
    });
  });

  group('usufructo', () {
    test(
      'total: los minutos son la jornada vigente (guardaparque 7:00)',
      () async {
        await perfil('guardaparque');
        await guardar(TipoMovimiento.acumulacion, sabadoPasado, minutos: 600);
        final m = await guardar(
          TipoMovimiento.usufructoTotal,
          viernes,
          minutos: 999, // se ignora
        );
        expect(m.tipo, 'usufructo');
        expect(m.alcance, 'total');
        expect(m.minutos, 420);
      },
    );

    test('solo en día hábil (sábado y feriado se rechazan)', () async {
      await db
          .into(db.feriados)
          .insert(
            FeriadosCompanion.insert(
              fecha: '2026-10-12',
              nombre: 'Feriado ficticio',
            ),
          );
      await guardar(TipoMovimiento.acumulacion, sabadoPasado, minutos: 900);
      await expectLater(
        guardar(TipoMovimiento.usufructoTotal, CalendarDate(2026, 9, 26)),
        rechazo(
          'El 26/09/2026 es sábado. El usufructo se carga solo en día hábil.',
        ),
      );
      await expectLater(
        guardar(
          TipoMovimiento.usufructoParcial,
          CalendarDate(2026, 10, 12),
          minutos: 60,
        ),
        rechazo(contains('feriado: Feriado ficticio')),
      );
    });

    test('parcial igual o mayor que la jornada se rechaza', () async {
      await guardar(TipoMovimiento.acumulacion, sabadoPasado, minutos: 900);
      await expectLater(
        guardar(TipoMovimiento.usufructoParcial, viernes, minutos: 480),
        rechazo(contains('menor que la jornada (8:00)')),
      );
    });

    test('sin saldo se bloquea con "Saldo disponible X, pedís Y"', () async {
      await expectLater(
        guardar(TipoMovimiento.usufructoParcial, viernes, minutos: 120),
        rechazo('Saldo disponible 0:00, pedís 2:00.'),
      );
      expect(await db.select(db.bancoMovimientos).get(), isEmpty);
    });

    test(
      'el saldo disponible incluye los usufructos cargados a futuro',
      () async {
        await guardar(TipoMovimiento.acumulacion, sabadoPasado, minutos: 180);
        await guardar(
          TipoMovimiento.usufructoParcial,
          lunesQueViene,
          minutos: 120,
        );
        await expectLater(
          guardar(
            TipoMovimiento.usufructoParcial,
            martesQueViene,
            minutos: 120,
          ),
          rechazo('Saldo disponible 1:00, pedís 2:00.'),
        );
        // Justo lo disponible sí se puede.
        final ok = await guardar(
          TipoMovimiento.usufructoParcial,
          martesQueViene,
          minutos: 60,
        );
        expect(ok.minutos, 60);
      },
    );

    test('con saldo negativo por deuda no se puede usufructuar', () async {
      // Lunes 8 h exactas (inicio del control), martes y miércoles faltantes.
      await fichada(lunes, 480, 960);
      await guardar(TipoMovimiento.acumulacion, sabadoPasado, minutos: 240);
      await expectLater(
        guardar(TipoMovimiento.usufructoParcial, viernes, minutos: 60),
        rechazo('Saldo disponible -12:00, pedís 1:00.'),
      );
    });

    test('un usufructo total sobre un día faltante cubre su deuda', () async {
      // Lunes 10 h (+2:00), martes faltante (-8:00), miércoles 14 h (+6:00).
      await fichada(lunes, 420, 1020);
      await fichada(CalendarDate(2026, 9, 23), 360, 1200);
      await guardar(TipoMovimiento.acumulacion, sabadoPasado, minutos: 30);
      // Antes del usufructo el saldo es 0:30; sin la deuda del martes, 8:30.
      final m = await guardar(TipoMovimiento.usufructoTotal, martes);
      expect(m.minutos, 480);
    });

    test('no se cargan dos usufructos que se pisen el mismo día', () async {
      await guardar(TipoMovimiento.acumulacion, sabadoPasado, minutos: 1200);
      await guardar(TipoMovimiento.usufructoParcial, viernes, minutos: 60);
      await expectLater(
        guardar(TipoMovimiento.usufructoTotal, viernes),
        rechazo('Ya hay un usufructo cargado el 25/09/2026.'),
      );
      await guardar(TipoMovimiento.usufructoTotal, lunesQueViene);
      await expectLater(
        guardar(TipoMovimiento.usufructoParcial, lunesQueViene, minutos: 30),
        rechazo('El 28/09/2026 ya tiene un usufructo total.'),
      );
    });

    test('editar solo el respaldo no vuelve a validar el saldo; cambiar los '
        'minutos sí', () async {
      final acum = await guardar(
        TipoMovimiento.acumulacion,
        sabadoPasado,
        minutos: 120,
      );
      final u = await guardar(
        TipoMovimiento.usufructoParcial,
        viernes,
        minutos: 120,
      );
      // La acumulación se pierde: el saldo queda en -2:00.
      await repo.marcarPerdido(userId: fakeUserId, id: acum.id, perdido: true);

      final editado = await guardar(
        TipoMovimiento.usufructoParcial,
        viernes,
        id: u.id,
        minutos: 120,
        numeroGde: 'NO-2026-00000001-APN-PNL#APNAC',
      );
      expect(editado.numeroGde, 'NO-2026-00000001-APN-PNL#APNAC');
      expect(editado.revision, 2);

      await expectLater(
        guardar(
          TipoMovimiento.usufructoParcial,
          viernes,
          id: u.id,
          minutos: 90,
        ),
        rechazo('Saldo disponible 0:00, pedís 1:30.'),
      );
    });
  });

  group('perdido / vigente / borrar', () {
    test(
      'marcar perdido deja de computar y volver a vigente valida el saldo',
      () async {
        final acum = await guardar(
          TipoMovimiento.acumulacion,
          sabadoPasado,
          minutos: 120,
        );
        final u = await guardar(
          TipoMovimiento.usufructoParcial,
          viernes,
          minutos: 120,
        );
        final perdido = await repo.marcarPerdido(
          userId: fakeUserId,
          id: u.id,
          perdido: true,
        );
        expect(perdido.estado, 'perdido');
        expect(perdido.syncStatus, SyncStatus.pending);
        expect(perdido.revision, 2);

        await repo.marcarPerdido(
          userId: fakeUserId,
          id: acum.id,
          perdido: true,
        );
        await expectLater(
          repo.marcarPerdido(userId: fakeUserId, id: u.id, perdido: false),
          rechazo(
            'No se puede volver a vigente. Saldo disponible 0:00, pedís 2:00.',
          ),
        );

        await repo.marcarPerdido(
          userId: fakeUserId,
          id: acum.id,
          perdido: false,
        );
        final vigente = await repo.marcarPerdido(
          userId: fakeUserId,
          id: u.id,
          perdido: false,
        );
        expect(vigente.estado, 'vigente');
      },
    );

    test('borrar es lógico: queda con deleted_at y pendiente', () async {
      final m = await guardar(
        TipoMovimiento.acumulacion,
        sabadoPasado,
        minutos: 60,
      );
      await repo.borrarMovimiento(userId: fakeUserId, id: m.id);
      final row = (await repo.findMovimiento(m.id))!;
      expect(row.deletedAt, isNotNull);
      expect(row.syncStatus, SyncStatus.pending);
      expect(await repo.watchMovimientos(fakeUserId).first, isEmpty);
      await expectLater(
        repo.borrarMovimiento(userId: fakeUserId, id: m.id),
        rechazo('No se encontró el movimiento.'),
      );
    });

    test('no se edita un movimiento de otro usuario', () async {
      final m = await guardar(
        TipoMovimiento.acumulacion,
        sabadoPasado,
        minutos: 60,
      );
      await expectLater(
        repo.marcarPerdido(userId: 'otro-usuario', id: m.id, perdido: true),
        rechazo('No se encontró el movimiento.'),
      );
    });
  });

  group('tipo de documento del movimiento', () {
    test('tiene que ser del usuario y estar activo', () async {
      final t = await repo.guardarTipo(userId: fakeUserId, codigo: 'FSOLI');
      final m = await guardar(
        TipoMovimiento.acumulacion,
        sabadoPasado,
        minutos: 60,
        tipoDocumentoId: t.id,
      );
      expect(m.tipoDocumentoId, t.id);

      await expectLater(
        guardar(
          TipoMovimiento.acumulacion,
          sabadoPasado,
          minutos: 60,
          tipoDocumentoId: 'no-existe',
        ),
        rechazo('El tipo de documento elegido no existe.'),
      );

      await repo.borrarTipo(userId: fakeUserId, id: t.id);
      // El que ya lo tenía lo conserva al editarse…
      await guardar(
        TipoMovimiento.acumulacion,
        sabadoPasado,
        id: m.id,
        minutos: 90,
        tipoDocumentoId: t.id,
      );
      // …pero no se puede asignar a uno nuevo.
      await expectLater(
        guardar(
          TipoMovimiento.acumulacion,
          sabadoPasado,
          minutos: 60,
          tipoDocumentoId: t.id,
        ),
        rechazo(contains('borrado')),
      );
    });
  });

  group('catálogo de tipos de documento', () {
    test('código obligatorio y único sin distinguir mayúsculas', () async {
      final t = await repo.guardarTipo(
        userId: fakeUserId,
        codigo: ' FOESC ',
        descripcion: 'Descripción ficticia',
      );
      expect(t.codigo, 'FOESC');
      expect(t.descripcion, 'Descripción ficticia');
      expect(t.syncStatus, SyncStatus.pending);

      await expectLater(
        repo.guardarTipo(userId: fakeUserId, codigo: 'foesc'),
        rechazo('Ya hay un tipo de documento con el código foesc.'),
      );
      await expectLater(
        repo.guardarTipo(userId: fakeUserId, codigo: '   '),
        rechazo(contains('Cargá el código')),
      );
      // Editar el mismo tipo con el mismo código está bien.
      final editado = await repo.guardarTipo(
        userId: fakeUserId,
        id: t.id,
        codigo: 'Foesc',
      );
      expect(editado.codigo, 'Foesc');
      expect(editado.revision, 2);
    });

    test('otro usuario puede usar el mismo código', () async {
      await repo.guardarTipo(userId: fakeUserId, codigo: 'FSOLI');
      final otro = await repo.guardarTipo(
        userId: 'otro-usuario-ficticio',
        codigo: 'FSOLI',
      );
      expect(otro.codigo, 'FSOLI');
    });

    test('borrar es lógico y libera el código', () async {
      final t = await repo.guardarTipo(userId: fakeUserId, codigo: 'FSOLI');
      await repo.borrarTipo(userId: fakeUserId, id: t.id);
      final row = (await repo.findTipo(t.id))!;
      expect(row.deletedAt, isNotNull);
      expect(row.syncStatus, SyncStatus.pending);
      final nuevo = await repo.guardarTipo(userId: fakeUserId, codigo: 'fsoli');
      expect(nuevo.id, isNot(t.id));
    });
  });

  group('adjunto', () {
    final pdf = PreparedAttachment(bytes: fakePdf(), extension: 'pdf');

    test('nuevo, reemplazo y quitar', () async {
      final m = await guardar(
        TipoMovimiento.acumulacion,
        sabadoPasado,
        minutos: 60,
        adjunto: NuevoAdjunto(pdf),
      );
      expect(m.adjuntoLocal, 'mem:${m.id}_adjunto.pdf');
      expect(m.adjuntoPath, isNull);
      expect(files.files.keys, [m.adjuntoLocal]);

      // Simula que ya se subió.
      await repo.setRemoteAdjuntoPath(m.id, '$fakeUserId/2026/09/x.pdf');

      final jpg = PreparedAttachment(bytes: fakeJpeg(), extension: 'jpg');
      final reemplazado = await guardar(
        TipoMovimiento.acumulacion,
        sabadoPasado,
        id: m.id,
        minutos: 60,
        adjunto: NuevoAdjunto(jpg),
      );
      expect(reemplazado.adjuntoLocal, 'mem:${m.id}_adjunto.jpg');
      expect(reemplazado.adjuntoPath, isNull); // hay que volver a subirlo
      expect(files.files.keys, [reemplazado.adjuntoLocal]);

      final sin = await guardar(
        TipoMovimiento.acumulacion,
        sabadoPasado,
        id: m.id,
        minutos: 60,
        adjunto: const QuitarAdjunto(),
      );
      expect(sin.adjuntoLocal, isNull);
      expect(sin.adjuntoPath, isNull);
      expect(files.files, isEmpty);
    });
  });

  group('sync', () {
    test('lo bajado no pisa cambios locales sin subir', () async {
      final m = await guardar(
        TipoMovimiento.acumulacion,
        sabadoPasado,
        minutos: 60,
      );
      await repo.applyRemoteMovimientos([
        RemoteMovimiento(
          id: m.id,
          userId: fakeUserId,
          tipo: 'acumulacion',
          fecha: '2026-09-19',
          minutos: 999,
          updatedAt: DateTime.utc(2026, 9, 24, 13),
        ),
      ]);
      expect((await repo.findMovimiento(m.id))!.minutos, 60);
    });

    test('conserva el adjunto local si la ruta remota no cambió', () async {
      final m = await guardar(
        TipoMovimiento.acumulacion,
        sabadoPasado,
        minutos: 60,
        adjunto: NuevoAdjunto(
          PreparedAttachment(bytes: fakeJpeg(), extension: 'jpg'),
        ),
      );
      const path = '$fakeUserId/2026/09/ficticio_adjunto.jpg';
      await repo.setRemoteAdjuntoPath(m.id, path);
      await repo.markMovimientoSynced(m.id, m.revision);

      RemoteMovimiento remoto(String? adjunto) => RemoteMovimiento(
        id: m.id,
        userId: fakeUserId,
        tipo: 'acumulacion',
        fecha: '2026-09-19',
        minutos: 90,
        adjuntoPath: adjunto,
        updatedAt: DateTime.utc(2026, 9, 24, 13),
      );
      await repo.applyRemoteMovimientos([remoto(path)]);
      var row = (await repo.findMovimiento(m.id))!;
      expect(row.minutos, 90);
      expect(row.adjuntoLocal, m.adjuntoLocal);

      await repo.applyRemoteMovimientos([
        remoto('$fakeUserId/2026/09/otro.pdf'),
      ]);
      row = (await repo.findMovimiento(m.id))!;
      expect(row.adjuntoLocal, isNull);
      expect(row.adjuntoPath, '$fakeUserId/2026/09/otro.pdf');
    });

    test('el contador global suma fichadas, movimientos y tipos', () async {
      await fichada(lunes, 480, 960); // sincronizada: no cuenta
      await db
          .into(db.fichadas)
          .insert(
            FichadasCompanion.insert(
              id: 'pendiente',
              userId: fakeUserId,
              fecha: '2026-09-24',
              ingresoMin: 480,
              updatedAt: DateTime(2026, 9, 24),
              syncStatus: SyncStatus.pending,
            ),
          );
      await guardar(TipoMovimiento.acumulacion, sabadoPasado, minutos: 60);
      await repo.guardarTipo(userId: fakeUserId, codigo: 'FSOLI');
      expect(await watchUnsyncedTotal(db, fakeUserId).first, 3);
    });
  });

  test('las fechas del contexto usan hoy del reloj', () async {
    final ctx = await repo.contexto(fakeUserId);
    expect(ctx.calculator.today, hoy);
  });
}
