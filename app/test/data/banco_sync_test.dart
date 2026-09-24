import 'package:asistente/data/attachments/attachment.dart';
import 'package:asistente/data/banco/banco_repository.dart';
import 'package:asistente/data/banco/movimiento.dart';
import 'package:asistente/data/banco/remote_banco.dart';
import 'package:asistente/data/fichadas/fichadas_repository.dart';
import 'package:asistente/data/local/app_database.dart';
import 'package:asistente/data/perfil/perfil_repository.dart';
import 'package:asistente/data/sync/banco_sync.dart';
import 'package:asistente/data/sync/fichadas_remote.dart';
import 'package:asistente/data/sync/sync_service.dart';
import 'package:asistente/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  late AppDatabase db;
  late InMemoryPhotoStore files;
  late BancoRepository banco;
  late FakeFichadasRemote fichadasRemote;
  late FakeBancoRemote remote;
  late SyncService sync;
  final sabado = CalendarDate(2026, 9, 19);

  setUp(() {
    db = newTestDatabase();
    files = InMemoryPhotoStore();
    final clock = steppingClock(DateTime(2026, 9, 24, 8));
    banco = BancoRepository(db, files, clock: clock, newId: sequentialIds());
    fichadasRemote = FakeFichadasRemote();
    remote = FakeBancoRemote();
    sync = SyncService(
      repository: FichadasRepository(db, files, clock: clock),
      perfiles: PerfilRepository(db, clock: clock),
      remote: fichadasRemote,
      banco: BancoSync(repository: banco, remote: remote),
      clock: clock,
    );
  });

  tearDown(() => db.close());

  Future<LocalMovimiento> acumulacion({
    int minutos = 240,
    CambioAdjunto adjunto = const MantenerAdjunto(),
    String? tipoDocumentoId,
  }) => banco.guardarMovimiento(
    userId: fakeUserId,
    draft: MovimientoDraft(
      tipo: TipoMovimiento.acumulacion,
      fecha: sabado,
      minutos: minutos,
      tipoDocumentoId: tipoDocumentoId,
      numeroGde: 'NO-2026-00000001-APN-PNL#APNAC',
    ),
    adjunto: adjunto,
  );

  test('ruta del adjunto: {user_id}/{yyyy}/{mm}/{id}_adjunto.{ext}', () {
    expect(
      adjuntoMovimientoPath(
        userId: fakeUserId,
        fecha: CalendarDate(2026, 3, 5),
        movimientoId: 'abc',
        extension: 'pdf',
      ),
      '$fakeUserId/2026/03/abc_adjunto.pdf',
    );
  });

  test('con adjunto PDF: sube primero el archivo y después la fila', () async {
    final m = await acumulacion(
      adjunto: NuevoAdjunto(
        PreparedAttachment(bytes: fakePdf(), extension: 'pdf'),
      ),
    );

    final result = await sync.sync(fakeUserId);

    final path = '$fakeUserId/2026/09/${m.id}_adjunto.pdf';
    expect(result.offline, isFalse);
    expect(result.uploaded, 1);
    expect(remote.calls, ['upload:$path', 'movimiento:${m.id}']);
    expect(remote.contentTypes[path], 'application/pdf');
    expect(remote.storage[path], files.files[m.adjuntoLocal]);
    final subido = remote.movimientos[m.id]!;
    expect(subido.adjuntoPath, path);
    expect(subido.tipo, 'acumulacion');
    expect(subido.alcance, isNull);
    expect(subido.minutos, 240);
    expect(subido.numeroGde, 'NO-2026-00000001-APN-PNL#APNAC');
    final local = (await banco.findMovimiento(m.id))!;
    expect(local.syncStatus, SyncStatus.synced);
    expect(local.adjuntoPath, path);
  });

  test('con adjunto imagen: sube .jpg como image/jpeg', () async {
    final m = await acumulacion(
      adjunto: NuevoAdjunto(
        PreparedAttachment(bytes: fakeJpeg(), extension: 'jpg'),
      ),
    );
    await sync.sync(fakeUserId);
    final path = '$fakeUserId/2026/09/${m.id}_adjunto.jpg';
    expect(remote.contentTypes[path], 'image/jpeg');
    expect(remote.movimientos[m.id]!.adjuntoPath, path);
  });

  test('sin adjunto: solo el upsert, con adjunto_path null', () async {
    final m = await acumulacion();
    final result = await sync.sync(fakeUserId);
    expect(result.uploaded, 1);
    expect(remote.calls, ['movimiento:${m.id}']);
    expect(remote.storage, isEmpty);
    expect(remote.movimientos[m.id]!.toJson()['adjunto_path'], isNull);
    expect((await banco.findMovimiento(m.id))!.syncStatus, SyncStatus.synced);
  });

  test('el tipo de documento sube antes que el movimiento (FK)', () async {
    final t = await banco.guardarTipo(userId: fakeUserId, codigo: 'FSOLI');
    final m = await acumulacion(tipoDocumentoId: t.id);

    await sync.sync(fakeUserId);

    expect(remote.calls, ['tipo:${t.id}', 'movimiento:${m.id}']);
    expect(remote.movimientos[m.id]!.tipoDocumentoId, t.id);
    expect((await banco.findTipo(t.id))!.syncStatus, SyncStatus.synced);
    expect((await banco.findMovimiento(m.id))!.syncStatus, SyncStatus.synced);
  });

  test(
    'usufructo: sube con alcance (CHECK banco_alcance_solo_usufructo)',
    () async {
      await acumulacion(minutos: 600);
      final u = await banco.guardarMovimiento(
        userId: fakeUserId,
        draft: MovimientoDraft(
          tipo: TipoMovimiento.usufructoTotal,
          fecha: CalendarDate(2026, 9, 25),
        ),
      );
      await sync.sync(fakeUserId);
      final subido = remote.movimientos[u.id]!;
      expect(subido.tipo, 'usufructo');
      expect(subido.alcance, 'total');
      expect(subido.minutos, 480);
    },
  );

  test('sin red: todo queda pendiente y sin errores', () async {
    final m = await acumulacion(
      adjunto: NuevoAdjunto(
        PreparedAttachment(bytes: fakePdf(), extension: 'pdf'),
      ),
    );
    remote.online = false;

    final result = await sync.sync(fakeUserId);

    expect(result.offline, isTrue);
    final local = (await banco.findMovimiento(m.id))!;
    expect(local.syncStatus, SyncStatus.pending);
    expect(local.syncError, isNull);
    expect(local.adjuntoPath, isNull);
    expect(remote.calls, isEmpty);
  });

  test('un rechazo deja el movimiento en error y se reintenta solo', () async {
    final m = await acumulacion();
    remote.rejectMovimiento[m.id] = 'Regla ficticia';

    var result = await sync.sync(fakeUserId);
    expect(result.failed, 1);
    var local = (await banco.findMovimiento(m.id))!;
    expect(local.syncStatus, SyncStatus.error);
    expect(local.syncError, 'Regla ficticia');

    remote.rejectMovimiento.clear();
    result = await sync.sync(fakeUserId);
    local = (await banco.findMovimiento(m.id))!;
    expect(local.syncStatus, SyncStatus.synced);
    expect(local.syncError, isNull);
  });

  test('si el adjunto ya subió, no se vuelve a subir al reintentar', () async {
    final m = await acumulacion(
      adjunto: NuevoAdjunto(
        PreparedAttachment(bytes: fakePdf(), extension: 'pdf'),
      ),
    );
    remote.rejectMovimiento[m.id] = 'Regla ficticia';
    await sync.sync(fakeUserId);
    remote.rejectMovimiento.clear();
    remote.calls.clear();

    await sync.sync(fakeUserId);

    expect(remote.calls, ['movimiento:${m.id}']);
  });

  test('si falta el adjunto local sube la fila y avisa con error', () async {
    final m = await acumulacion(
      adjunto: NuevoAdjunto(
        PreparedAttachment(bytes: fakePdf(), extension: 'pdf'),
      ),
    );
    files.files.clear();

    await sync.sync(fakeUserId);

    expect(remote.movimientos[m.id]!.adjuntoPath, isNull);
    final local = (await banco.findMovimiento(m.id))!;
    expect(local.syncStatus, SyncStatus.error);
    expect(local.syncError, contains('No se encontró el adjunto'));
  });

  test('el borrado lógico sube deleted_at (sin DELETE)', () async {
    final m = await acumulacion();
    await sync.sync(fakeUserId);
    await banco.borrarMovimiento(userId: fakeUserId, id: m.id);

    await sync.sync(fakeUserId);

    expect(remote.movimientos[m.id]!.deletedAt, isNotNull);
    expect((await banco.findMovimiento(m.id))!.syncStatus, SyncStatus.synced);
  });

  test(
    'baja movimientos de otro dispositivo con cursor por updated_at',
    () async {
      remote.putFromOtherDevice(
        const RemoteMovimiento(
          id: 'desde-la-pc',
          userId: fakeUserId,
          tipo: 'usufructo',
          alcance: 'parcial',
          fecha: '2026-09-21',
          minutos: 90,
        ),
      );

      final result = await sync.sync(fakeUserId);

      expect(result.downloaded, 1);
      final local = (await banco.findMovimiento('desde-la-pc'))!;
      expect(local.kind, TipoMovimiento.usufructoParcial);
      expect(local.syncStatus, SyncStatus.synced);
      expect(
        await banco.readState(BancoSync.movimientosPulledAtKey(fakeUserId)),
        isNotNull,
      );

      await sync.sync(fakeUserId);
      expect(
        remote.lastMovimientosSince,
        remote.movimientos['desde-la-pc']!.updatedAt,
      );
    },
  );

  test(
    'un tipo con el código repetido en el servidor queda en error',
    () async {
      // El servidor ya tiene "fsoli" de otro dispositivo (índice único).
      final t = await banco.guardarTipo(userId: fakeUserId, codigo: 'FSOLI');
      final fake = _RechazaTipos();
      final s = SyncService(
        repository: FichadasRepository(db, files),
        perfiles: PerfilRepository(db),
        remote: fichadasRemote,
        banco: BancoSync(repository: banco, remote: fake),
      );
      await s.sync(fakeUserId);
      final local = (await banco.findTipo(t.id))!;
      expect(local.syncStatus, SyncStatus.error);
      expect(local.syncError, contains('FSOLI'));
    },
  );
}

/// Rechaza todos los tipos (como el índice único del servidor).
class _RechazaTipos extends FakeBancoRemote {
  @override
  Future<void> upsertTipoDocumento(RemoteTipoDocumento tipo) async =>
      throw const RemoteRejectedException(
        'Ya existe un registro con esos datos (ficticio).',
      );
}
