import 'package:asistente/data/fichadas/fichadas_repository.dart';
import 'package:asistente/data/fichadas/remote_fichada.dart';
import 'package:asistente/data/local/app_database.dart';
import 'package:asistente/data/perfil/perfil_repository.dart';
import 'package:asistente/data/sync/sync_service.dart';
import 'package:asistente/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  late AppDatabase db;
  late InMemoryPhotoStore photos;
  late FichadasRepository repo;
  late FakeFichadasRemote remote;
  late PerfilRepository perfiles;
  late SyncService sync;
  final hoy = CalendarDate(2026, 9, 24);

  setUp(() {
    db = newTestDatabase();
    photos = InMemoryPhotoStore();
    final clock = steppingClock(DateTime(2026, 9, 24, 8));
    repo = FichadasRepository(db, photos, clock: clock, newId: sequentialIds());
    remote = FakeFichadasRemote();
    perfiles = PerfilRepository(db, clock: clock);
    sync = SyncService(
      repository: repo,
      perfiles: perfiles,
      remote: remote,
      clock: clock,
    );
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

  test(
    'una fichada sin foto se sube sin foto_*_path y queda sincronizada',
    () async {
      final f = await repo.ficharIngreso(
        userId: fakeUserId,
        date: hoy,
        proposedMin: 480,
        chosenMin: 480,
      );
      await repo.ficharEgreso(
        userId: fakeUserId,
        fichadaId: f.id,
        proposedMin: 960,
        chosenMin: 960,
      );

      final result = await sync.sync(fakeUserId);

      expect(result.uploaded, 1);
      expect(remote.calls, ['upsert:${f.id}']);
      expect(remote.storage, isEmpty);
      final subida = remote.rows[f.id]!;
      expect(subida.fotoIngresoPath, isNull);
      expect(subida.fotoEgresoPath, isNull);
      expect(subida.toJson()['foto_ingreso_path'], isNull);
      final local = (await repo.findById(f.id))!;
      expect(local.syncStatus, SyncStatus.synced);
      expect(local.syncError, isNull);
    },
  );

  test('foto solo en el egreso: sube esa y deja el ingreso sin ruta', () async {
    final f = await repo.ficharIngreso(
      userId: fakeUserId,
      date: hoy,
      proposedMin: 480,
      chosenMin: 480,
    );
    await egreso(f.id);

    await sync.sync(fakeUserId);

    expect(remote.calls, [
      'upload:$fakeUserId/2026/09/${f.id}_egreso.jpg',
      'upsert:${f.id}',
    ]);
    expect(remote.rows[f.id]!.fotoIngresoPath, isNull);
    expect((await repo.findById(f.id))!.syncStatus, SyncStatus.synced);
  });

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

  test('los feriados guardan el tipo', () async {
    remote.feriados = const [
      RemoteFeriado(
        fecha: '2026-07-10',
        nombre: 'Puente ficticio',
        tipo: 'no_laborable',
      ),
      RemoteFeriado(
        fecha: '2026-06-15',
        nombre: 'Feriado ficticio',
        tipo: 'trasladable',
      ),
    ];
    await sync.sync(fakeUserId);
    final feriados = await repo.watchHolidays().first;
    // Ordenados por fecha.
    expect(feriados.map((h) => h.kind), [
      HolidayKind.movable,
      HolidayKind.nonWorking,
    ]);
  });

  test(
    'sin feriados guardados los vuelve a bajar aunque no pasaron 12 h',
    () async {
      await sync.sync(fakeUserId); // el servidor todavía no tenía feriados
      expect(remote.feriadosFetches, 1);
      remote.feriados = const [
        RemoteFeriado(fecha: '2026-10-12', nombre: 'Feriado ficticio'),
      ];
      await sync.sync(fakeUserId);
      expect(remote.feriadosFetches, 2);
      expect(await repo.hasHolidays(), isTrue);
      // Con feriados guardados, no se vuelven a pedir hasta que pasen 12 h.
      await sync.sync(fakeUserId);
      expect(remote.feriadosFetches, 2);
    },
  );

  group('perfil', () {
    test('baja el agrupamiento del servidor', () async {
      remote.perfil = const RemotePerfil(
        userId: fakeUserId,
        agrupamiento: 'guardaparque',
      );
      await sync.sync(fakeUserId);
      final p = await perfiles.watchPerfil(fakeUserId).first;
      expect(p!.agrupamiento, Agrupamiento.guardaparque);
      expect(p.syncStatus, SyncStatus.synced);
    });

    test('sin agrupamiento en el servidor queda guardado como null', () async {
      remote.perfil = const RemotePerfil(userId: fakeUserId);
      await sync.sync(fakeUserId);
      final p = await perfiles.watchPerfil(fakeUserId).first;
      expect(p, isNotNull);
      expect(p!.agrupamiento, isNull);
    });

    test('el elegido sin red queda pendiente y se sube después', () async {
      remote.online = false;
      await perfiles.setAgrupamiento(
        fakeUserId,
        Agrupamiento.guardaparqueApoyo,
      );
      await sync.sync(fakeUserId);
      var p = await perfiles.watchPerfil(fakeUserId).first;
      expect(p!.syncStatus, SyncStatus.pending);
      expect(p.agrupamiento, Agrupamiento.guardaparqueApoyo);

      remote.online = true;
      await sync.sync(fakeUserId);
      expect(remote.perfil!.agrupamiento, 'guardaparque_apoyo');
      p = await perfiles.watchPerfil(fakeUserId).first;
      expect(p!.syncStatus, SyncStatus.synced);
    });

    test('sin la columna en el servidor: queda pendiente, sin error, y las '
        'fichadas se sincronizan igual', () async {
      remote.perfilSinColumna = true;
      final f = await ingreso();
      await perfiles.setAgrupamiento(fakeUserId, Agrupamiento.guardaparque);

      final result = await sync.sync(fakeUserId);

      expect(result.offline, isFalse);
      expect(result.message, isNull);
      expect((await repo.findById(f.id))!.syncStatus, SyncStatus.synced);
      var p = await perfiles.watchPerfil(fakeUserId).first;
      expect(p!.agrupamiento, Agrupamiento.guardaparque);
      expect(p.syncStatus, SyncStatus.pending);
      expect(p.syncError, isNull);

      // Cuando se aplica la migración, se sube en la próxima pasada.
      remote.perfilSinColumna = false;
      await sync.sync(fakeUserId);
      expect(remote.perfil!.agrupamiento, 'guardaparque');
      p = await perfiles.watchPerfil(fakeUserId).first;
      expect(p!.syncStatus, SyncStatus.synced);
    });

    test(
      'sin la columna y sin perfil local: no crea nada (la app lo pide)',
      () async {
        remote.perfilSinColumna = true;
        final result = await sync.sync(fakeUserId);
        expect(result.message, isNull);
        expect(await perfiles.watchPerfil(fakeUserId).first, isNull);
      },
    );

    test('la bajada no pisa un cambio local sin subir', () async {
      remote.perfil = const RemotePerfil(
        userId: fakeUserId,
        agrupamiento: 'administrativo',
      );
      remote.rejectPerfil = 'rechazo ficticio';
      await perfiles.setAgrupamiento(fakeUserId, Agrupamiento.guardaparque);
      final result = await sync.sync(fakeUserId);

      final p = await perfiles.watchPerfil(fakeUserId).first;
      expect(p!.agrupamiento, Agrupamiento.guardaparque);
      expect(p.syncStatus, SyncStatus.error);
      expect(p.syncError, contains('rechazo ficticio'));
      expect(result.message, contains('agrupamiento'));
    });
  });

  test('dos llamadas simultáneas no suben dos veces', () async {
    await ingreso();
    await Future.wait([sync.sync(fakeUserId), sync.sync(fakeUserId)]);
    expect(remote.calls.where((c) => c.startsWith('upload:')), hasLength(1));
  });
}
