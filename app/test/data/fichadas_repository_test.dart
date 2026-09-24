import 'package:asistente/data/fichadas/fichadas_repository.dart';
import 'package:asistente/data/fichadas/remote_fichada.dart';
import 'package:asistente/data/local/app_database.dart';
import 'package:asistente/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  late AppDatabase db;
  late InMemoryPhotoStore photos;
  late FichadasRepository repo;
  final hoy = CalendarDate(2026, 9, 24);

  setUp(() {
    db = newTestDatabase();
    photos = InMemoryPhotoStore();
    repo = FichadasRepository(
      db,
      photos,
      clock: steppingClock(DateTime(2026, 9, 24, 8)),
      newId: sequentialIds(),
    );
  });

  tearDown(() => db.close());

  Future<LocalFichada> ingreso({int proposed = 480, int? chosen}) =>
      repo.ficharIngreso(
        userId: fakeUserId,
        date: hoy,
        proposedMin: proposed,
        chosenMin: chosen ?? proposed,
        photoJpeg: fakeJpeg(),
      );

  group('ficharIngreso', () {
    test(
      'crea un tramo abierto, pendiente y con la foto guardada local',
      () async {
        final f = await ingreso();

        expect(f.id, '00000000-0000-4000-8000-000000000001');
        expect(f.userId, fakeUserId);
        expect(f.fecha, '2026-09-24');
        expect(f.ingresoMin, 480);
        expect(f.egresoMin, isNull);
        expect(f.isOpen, isTrue);
        expect(f.editado, isFalse);
        expect(f.ingresoOriginalMin, isNull);
        expect(f.syncStatus, SyncStatus.pending);
        expect(f.fotoIngresoLocal, 'mem:${f.id}_ingreso.jpg');
        expect(f.fotoIngresoPath, isNull);
        expect(photos.files, contains(f.fotoIngresoLocal));
      },
    );

    test('si se corrige la hora guarda la original y marca editado', () async {
      final f = await ingreso(proposed: 490, chosen: 482);

      expect(f.ingresoMin, 482);
      expect(f.ingresoOriginalMin, 490);
      expect(f.editado, isTrue);
    });

    test('no deja abrir otro tramo si hay uno abierto ese día', () async {
      await ingreso();
      expect(
        () => ingreso(proposed: 600),
        throwsA(isA<FichadaInvalidaException>()),
      );
    });

    test('rechaza horas fuera de 0..1439', () {
      expect(
        () => ingreso(proposed: 1440),
        throwsA(isA<FichadaInvalidaException>()),
      );
    });
  });

  group('ficharEgreso', () {
    test('cierra el tramo, sube la revisión y queda pendiente', () async {
      final abierto = await ingreso();
      await repo.markSynced(abierto.id, abierto.revision);

      final f = await repo.ficharEgreso(
        userId: fakeUserId,
        fichadaId: abierto.id,
        proposedMin: 1000,
        chosenMin: 1000,
        photoJpeg: fakeJpeg(),
      );

      expect(f.egresoMin, 1000);
      expect(f.isOpen, isFalse);
      expect(f.editado, isFalse);
      expect(f.egresoOriginalMin, isNull);
      expect(f.revision, abierto.revision + 1);
      expect(f.syncStatus, SyncStatus.pending);
      expect(f.fotoEgresoLocal, 'mem:${f.id}_egreso.jpg');
    });

    test('corrección del egreso: guarda la original y editado', () async {
      final abierto = await ingreso();
      final f = await repo.ficharEgreso(
        userId: fakeUserId,
        fichadaId: abierto.id,
        proposedMin: 1010,
        chosenMin: 990,
      );
      expect(f.egresoOriginalMin, 1010);
      expect(f.editado, isTrue);
    });

    test('editado sigue true si el ingreso ya estaba corregido', () async {
      final abierto = await ingreso(proposed: 490, chosen: 480);
      final f = await repo.ficharEgreso(
        userId: fakeUserId,
        fichadaId: abierto.id,
        proposedMin: 1000,
        chosenMin: 1000,
      );
      // CHECK fichadas_editado_coherente.
      expect(f.editado, isTrue);
      expect(f.ingresoOriginalMin, 490);
      expect(f.egresoOriginalMin, isNull);
    });

    test('el egreso tiene que ser posterior al ingreso', () async {
      final abierto = await ingreso(proposed: 600);
      for (final egreso in [600, 599, 0]) {
        await expectLater(
          repo.ficharEgreso(
            userId: fakeUserId,
            fichadaId: abierto.id,
            proposedMin: egreso,
            chosenMin: egreso,
          ),
          throwsA(isA<FichadaInvalidaException>()),
        );
      }
      expect((await repo.findById(abierto.id))!.isOpen, isTrue);
    });

    test(
      'no cierra dos veces el mismo tramo ni tramos de otro usuario',
      () async {
        final abierto = await ingreso();
        await expectLater(
          repo.ficharEgreso(
            userId: 'otro-usuario',
            fichadaId: abierto.id,
            proposedMin: 950,
            chosenMin: 950,
          ),
          throwsA(isA<FichadaInvalidaException>()),
        );
        expect((await repo.findById(abierto.id))!.isOpen, isTrue);

        await repo.ficharEgreso(
          userId: fakeUserId,
          fichadaId: abierto.id,
          proposedMin: 900,
          chosenMin: 900,
        );
        await expectLater(
          repo.ficharEgreso(
            userId: fakeUserId,
            fichadaId: abierto.id,
            proposedMin: 950,
            chosenMin: 950,
          ),
          throwsA(isA<FichadaInvalidaException>()),
        );
      },
    );

    test(
      'varios tramos en el día: después de cerrar se puede volver a abrir',
      () async {
        final a = await ingreso(proposed: 480);
        await repo.ficharEgreso(
          userId: fakeUserId,
          fichadaId: a.id,
          proposedMin: 720,
          chosenMin: 720,
        );
        await ingreso(proposed: 780);
        final dia = await repo.watchDay(fakeUserId, hoy).first;
        expect(dia.map((f) => (f.ingresoMin, f.egresoMin)), [
          (480, 720),
          (780, null),
        ]);
      },
    );
  });

  group('foto opcional', () {
    test('se puede fichar ingreso y egreso sin foto', () async {
      final a = await repo.ficharIngreso(
        userId: fakeUserId,
        date: hoy,
        proposedMin: 480,
        chosenMin: 480,
      );
      expect(a.fotoIngresoLocal, isNull);
      final b = await repo.ficharEgreso(
        userId: fakeUserId,
        fichadaId: a.id,
        proposedMin: 960,
        chosenMin: 960,
      );
      expect(b.fotoEgresoLocal, isNull);
      expect(photos.files, isEmpty);
    });
  });

  group('tramo abierto de un día anterior', () {
    final ayer = CalendarDate(2026, 9, 23);

    Future<LocalFichada> abiertoAyer() => repo.ficharIngreso(
      userId: fakeUserId,
      date: ayer,
      proposedMin: 480,
      chosenMin: 480,
    );

    test('bloquea fichar un ingreso nuevo hasta cerrarlo', () async {
      await abiertoAyer();
      await expectLater(
        ingreso(proposed: 490),
        throwsA(
          isA<FichadaInvalidaException>().having(
            (e) => e.message,
            'message',
            contains('23/09/2026'),
          ),
        ),
      );
      expect(await repo.watchDay(fakeUserId, hoy).first, isEmpty);
    });

    test(
      'se cierra con la hora a mano: sin hora original ni editado',
      () async {
        final a = await abiertoAyer();
        final cerrado = await repo.ficharEgreso(
          userId: fakeUserId,
          fichadaId: a.id,
          proposedMin: null,
          chosenMin: 970,
        );
        expect(cerrado.fecha, '2026-09-23');
        expect(cerrado.egresoMin, 970);
        expect(cerrado.egresoOriginalMin, isNull);
        expect(cerrado.editado, isFalse);

        // Ya se puede fichar hoy.
        final nuevo = await ingreso();
        expect(nuevo.fecha, '2026-09-24');
      },
    );

    test('openRecords lista los abiertos del más viejo al más nuevo', () async {
      await abiertoAyer();
      final open = await repo.openRecords(fakeUserId);
      expect(open.single.fecha, '2026-09-23');
    });
  });

  group('superposición en el mismo día', () {
    test('bloquea un ingreso dentro de un tramo existente', () async {
      final a = await ingreso(proposed: 480);
      await repo.ficharEgreso(
        userId: fakeUserId,
        fichadaId: a.id,
        proposedMin: 720,
        chosenMin: 720,
      );
      await expectLater(
        ingreso(proposed: 660),
        throwsA(
          isA<FichadaInvalidaException>().having(
            (e) => e.message,
            'message',
            'El tramo 11:00–abierto se superpone con el tramo 08:00–12:00.',
          ),
        ),
      );
      // Justo al terminar el anterior sí se puede.
      final b = await ingreso(proposed: 720);
      expect(b.ingresoMin, 720);
    });

    test(
      'bloquea un ingreso corregido a una hora anterior a otro tramo',
      () async {
        final a = await ingreso(proposed: 780);
        await repo.ficharEgreso(
          userId: fakeUserId,
          fichadaId: a.id,
          proposedMin: 900,
          chosenMin: 900,
        );
        // Un tramo abierto a las 12:00 llega hasta el fin del día: choca.
        await expectLater(
          ingreso(proposed: 960, chosen: 720),
          throwsA(isA<FichadaInvalidaException>()),
        );
      },
    );

    test('bloquea un egreso que se superpone con otro tramo del día', () async {
      final a = await ingreso(proposed: 480);
      // Desde la PC se cargó otro tramo 10:00–11:00 ese día.
      await repo.applyRemote([
        RemoteFichada(
          id: 'desde-la-pc',
          userId: fakeUserId,
          fecha: '2026-09-24',
          ingresoMin: 600,
          egresoMin: 660,
          updatedAt: DateTime.utc(2026, 9, 24, 12),
        ),
      ]);
      await expectLater(
        repo.ficharEgreso(
          userId: fakeUserId,
          fichadaId: a.id,
          proposedMin: 720,
          chosenMin: 720,
        ),
        throwsA(
          isA<FichadaInvalidaException>().having(
            (e) => e.message,
            'message',
            contains('10:00–11:00'),
          ),
        ),
      );
      expect((await repo.findById(a.id))!.isOpen, isTrue);

      final ok = await repo.ficharEgreso(
        userId: fakeUserId,
        fichadaId: a.id,
        proposedMin: 720,
        chosenMin: 600,
      );
      expect(ok.egresoMin, 600);
    });
  });

  group('lectura', () {
    test('contador de no sincronizadas', () async {
      final a = await ingreso();
      expect(await repo.watchUnsyncedCount(fakeUserId).first, 1);
      await repo.markSynced(a.id, a.revision);
      expect(await repo.watchUnsyncedCount(fakeUserId).first, 0);
      await repo.markError(a.id, a.revision, 'x');
      expect(await repo.watchUnsyncedCount(fakeUserId).first, 1);
    });

    test(
      'un registro abierto se convierte en DailyRecord abierto (no computa)',
      () async {
        final f = await ingreso();
        final record = f.toDailyRecord();
        expect(record.isOpen, isTrue);
        final dia = DayCalculator(today: hoy).calculate(hoy, records: [record]);
        expect(dia.status, DayStatus.open);
        expect(dia.debtMinutes, 0);
      },
    );
  });

  group('sync', () {
    test('markSynced no marca si cambió la revisión', () async {
      final a = await ingreso();
      await repo.ficharEgreso(
        userId: fakeUserId,
        fichadaId: a.id,
        proposedMin: 900,
        chosenMin: 900,
      );
      expect(await repo.markSynced(a.id, a.revision), isFalse);
      expect((await repo.findById(a.id))!.syncStatus, SyncStatus.pending);
    });

    test(
      'applyRemote no pisa cambios locales sin subir y sí los sincronizados',
      () async {
        final pendiente = await ingreso();
        final remota = RemoteFichada(
          id: pendiente.id,
          userId: fakeUserId,
          fecha: '2026-09-24',
          ingresoMin: 300,
          updatedAt: DateTime.utc(2026, 9, 24, 12),
        );
        await repo.applyRemote([remota]);
        expect((await repo.findById(pendiente.id))!.ingresoMin, 480);

        await repo.markSynced(pendiente.id, pendiente.revision);
        await repo.applyRemote([remota]);
        final f = (await repo.findById(pendiente.id))!;
        expect(f.ingresoMin, 300);
        expect(f.syncStatus, SyncStatus.synced);
        // La foto local se conserva.
        expect(f.fotoIngresoLocal, pendiente.fotoIngresoLocal);
      },
    );

    test('las fichadas borradas en el servidor no se muestran', () async {
      await repo.applyRemote([
        RemoteFichada(
          id: 'borrada',
          userId: fakeUserId,
          fecha: '2026-09-23',
          ingresoMin: 480,
          egresoMin: 960,
          deletedAt: DateTime.utc(2026, 9, 24),
          updatedAt: DateTime.utc(2026, 9, 24),
        ),
      ]);
      expect(await repo.watchAll(fakeUserId).first, isEmpty);
    });
  });
}
