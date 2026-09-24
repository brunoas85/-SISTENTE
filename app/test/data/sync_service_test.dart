import 'package:asistente/data/fichadas/fichadas_repository.dart';
import 'package:asistente/data/fichadas/remote_fichada.dart';
import 'package:asistente/data/local/app_database.dart';
import 'package:asistente/data/sync/sync_service.dart';
import 'package:asistente/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  late AppDatabase db;
  late InMemoryPhotoStore photos;
  late FichadasRepository repo;
  late FakeFichadasRemote remote;
  late SyncService sync;
  final hoy = CalendarDate(2026, 9, 24);

  setUp(() {
    db = newTestDatabase();
    photos = InMemoryPhotoStore();
    final clock = steppingClock(DateTime(2026, 9, 24, 8));
    repo = FichadasRepository(db, photos, clock: clock, newId: sequentialIds());
    remote = FakeFichadasRemote();
    sync = SyncService(repository: repo, remote: remote, clock: clock);
  });

  tearDown(() => db.close());

  Future<LocalFichada> ingreso({int min = 480}) => repo.ficharIngreso(
    userId: fakeUserId,
    date: hoy,
    proposedMin: min,
    chosenMin: min,
    photoJpeg: fakeJpeg(),
  );

  Future<LocalFichada> egreso(String id, {int min = 960}) => repo.ficharEgreso(
    userId: fakeUserId,
    fichadaId: id,
    proposedMin: min,
    chosenMin: min,
    photoJpeg: fakeJpeg(),
  );

  test('ruta del comprobante: {user_id}/{yyyy}/{mm}/{id}_{tipo}.jpg', () {
    expect(
      comprobantePath(
        userId: fakeUserId,
        fecha: CalendarDate(2026, 3, 5),
        fichadaId: 'abc',
        tipo: TipoFichada.egreso,
      ),
      '$fakeUserId/2026/03/abc_egreso.jpg',
    );
  });

  test('sin red: no marca errores y todo queda pendiente', () async {
    final f = await ingreso();
    remote.online = false;

    final result = await sync.sync(fakeUserId);

    expect(result.offline, isTrue);
    expect(result.uploaded, 0);
    final local = (await repo.findById(f.id))!;
    expect(local.syncStatus, SyncStatus.pending);
    expect(local.syncError, isNull);
    expect(remote.calls, isEmpty);
  });

  test(
    'sube primero la foto y después la fila, y la marca sincronizada',
    () async {
      final f = await ingreso();

      final result = await sync.sync(fakeUserId);

      final path = '$fakeUserId/2026/09/${f.id}_ingreso.jpg';
      expect(result.offline, isFalse);
      expect(result.uploaded, 1);
      expect(remote.calls, ['upload:$path', 'upsert:${f.id}']);
      expect(remote.storage[path], photos.files[f.fotoIngresoLocal]);
      final subida = remote.rows[f.id]!;
      expect(subida.userId, fakeUserId);
      expect(subida.fotoIngresoPath, path);
      expect(subida.egresoMin, isNull);
      expect(subida.editado, isFalse);

      final local = (await repo.findById(f.id))!;
      expect(local.syncStatus, SyncStatus.synced);
      expect(local.fotoIngresoPath, path);
    },
  );

  test('el egreso sube solo su foto y la fila con las dos rutas', () async {
    final f = await ingreso();
    await sync.sync(fakeUserId);
    remote.calls.clear();

    await egreso(f.id);
    await sync.sync(fakeUserId);

    final pathEgreso = '$fakeUserId/2026/09/${f.id}_egreso.jpg';
    expect(remote.calls, ['upload:$pathEgreso', 'upsert:${f.id}']);
    final subida = remote.rows[f.id]!;
    expect(subida.egresoMin, 960);
    expect(subida.fotoIngresoPath, '$fakeUserId/2026/09/${f.id}_ingreso.jpg');
    expect(subida.fotoEgresoPath, pathEgreso);
    expect((await repo.findById(f.id))!.syncStatus, SyncStatus.synced);
  });

  test(
    'se corta la red a mitad de camino y al volver retoma sin duplicar',
    () async {
      final f = await ingreso();
      // La foto sube, pero el upsert falla por falta de red.
      remote.upsertsOffline = 1;
      var result = await sync.sync(fakeUserId);
      expect(result.offline, isTrue);
      var local = (await repo.findById(f.id))!;
      expect(local.syncStatus, SyncStatus.pending);
      expect(local.fotoIngresoPath, isNotNull);
      expect(remote.rows, isEmpty);

      remote.calls.clear();
      result = await sync.sync(fakeUserId);
      expect(result.offline, isFalse);
      // La foto ya tenía ruta: no se vuelve a subir.
      expect(remote.calls.where((c) => c.startsWith('upload:')), isEmpty);
      expect((await repo.findById(f.id))!.syncStatus, SyncStatus.synced);
    },
  );

  test(
    'un rechazo del servidor deja la fila en error y se reintenta sola',
    () async {
      final f = await ingreso();
      remote.rejectUpsert[f.id] = 'Regla de datos';

      var result = await sync.sync(fakeUserId);
      expect(result.failed, 1);
      var local = (await repo.findById(f.id))!;
      expect(local.syncStatus, SyncStatus.error);
      expect(local.syncError, 'Regla de datos');

      remote.rejectUpsert.clear();
      result = await sync.sync(fakeUserId);
      expect(result.uploaded, 1);
      local = (await repo.findById(f.id))!;
      expect(local.syncStatus, SyncStatus.synced);
      expect(local.syncError, isNull);
    },
  );

  test(
    'si la fila cambia mientras sube, se vuelve a subir en la misma pasada',
    () async {
      final f = await ingreso();
      var first = true;
      remote.onUpsert = (_) async {
        if (!first) return;
        first = false;
        await egreso(f.id, min: 900);
      };

      await sync.sync(fakeUserId);

      expect(remote.calls.where((c) => c == 'upsert:${f.id}'), hasLength(2));
      expect(remote.rows[f.id]!.egresoMin, 900);
      expect((await repo.findById(f.id))!.syncStatus, SyncStatus.synced);
    },
  );

  test('si falta la foto local sube la fila igual y avisa con error', () async {
    final f = await ingreso();
    photos.files.clear();

    await sync.sync(fakeUserId);

    expect(remote.rows[f.id]!.fotoIngresoPath, isNull);
    final local = (await repo.findById(f.id))!;
    expect(local.syncStatus, SyncStatus.error);
    expect(local.syncError, contains('foto de ingreso'));
  });

  test('baja cambios de otro dispositivo y guarda el cursor', () async {
    remote.putFromOtherDevice(
      const RemoteFichada(
        id: 'desde-la-pc',
        userId: fakeUserId,
        fecha: '2026-09-23',
        ingresoMin: 470,
        egresoMin: 950,
      ),
    );

    final result = await sync.sync(fakeUserId);

    expect(result.downloaded, 1);
    final local = (await repo.findById('desde-la-pc'))!;
    expect(local.syncStatus, SyncStatus.synced);
    expect(local.egresoMin, 950);
    expect(
      await repo.readState(SyncService.pulledAtKey(fakeUserId)),
      isNotNull,
    );

    await sync.sync(fakeUserId);
    expect(remote.lastSince, remote.rows['desde-la-pc']!.updatedAt);
  });

  test('conflicto: gana el último que sincroniza', () async {
    final f = await ingreso();
    await sync.sync(fakeUserId);

    // La PC cambia el ingreso en el servidor…
    final servidor = remote.rows[f.id]!;
    remote.putFromOtherDevice(
      RemoteFichada(
        id: servidor.id,
        userId: servidor.userId,
        fecha: servidor.fecha,
        ingresoMin: 470,
        fotoIngresoPath: servidor.fotoIngresoPath,
      ),
    );
    // …y el celular, sin haberlo bajado, ficha el egreso.
    await egreso(f.id, min: 960);

    await sync.sync(fakeUserId);

    // El celular sincronizó último: su versión queda en el servidor y la
    // bajada no pisó el cambio local.
    expect(remote.rows[f.id]!.ingresoMin, 480);
    expect(remote.rows[f.id]!.egresoMin, 960);
    final local = (await repo.findById(f.id))!;
    expect(local.ingresoMin, 480);
    expect(local.syncStatus, SyncStatus.synced);
  });

  test('actualiza los feriados', () async {
    remote.feriados = const [
      RemoteFeriado(fecha: '2026-10-12', nombre: 'Feriado ficticio'),
    ];
    await sync.sync(fakeUserId);
    final feriados = await repo.watchHolidays().first;
    expect(feriados.single.date, CalendarDate(2026, 10, 12));
  });

  test('dos llamadas simultáneas no suben dos veces', () async {
    await ingreso();
    await Future.wait([sync.sync(fakeUserId), sync.sync(fakeUserId)]);
    expect(remote.calls.where((c) => c.startsWith('upload:')), hasLength(1));
  });
}
