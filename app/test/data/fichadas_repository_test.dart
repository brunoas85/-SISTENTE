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
