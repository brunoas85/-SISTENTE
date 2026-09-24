import 'package:asistente/data/fichadas/fichada_validation.dart';
import 'package:asistente/data/fichadas/fichadas_repository.dart';
import 'package:asistente/data/local/app_database.dart';
import 'package:asistente/domain/domain.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

// Carga a mano desde la vista mensual. Datos ficticios; hoy es jueves
// 24/09/2026 y el martes 15/09 es un feriado ficticio.
void main() {
  late AppDatabase db;
  late FichadasRepository repo;
  final hoy = CalendarDate(2026, 9, 24);
  final lunes21 = CalendarDate(2026, 9, 21);

  setUp(() async {
    db = newTestDatabase();
    repo = FichadasRepository(
      db,
      InMemoryPhotoStore(),
      clock: steppingClock(DateTime(2026, 9, 24, 8)),
      newId: sequentialIds(),
    );
    await db
        .into(db.feriados)
        .insert(
          FeriadosCompanion.insert(
            fecha: '2026-09-15',
            nombre: 'Feriado ficticio',
          ),
        );
  });

  tearDown(() => db.close());

  Future<LocalFichada> insertar(
    String fecha,
    int ingreso, [
    int? egreso,
    String? id,
  ]) async {
    final fid = id ?? 'f-$fecha-$ingreso';
    await db
        .into(db.fichadas)
        .insert(
          FichadasCompanion.insert(
            id: fid,
            userId: fakeUserId,
            fecha: fecha,
            ingresoMin: ingreso,
            egresoMin: Value(egreso),
            updatedAt: DateTime(2026, 9, 20),
            revision: const Value(3),
            syncStatus: SyncStatus.synced,
          ),
        );
    return (await repo.findById(fid))!;
  }

  group('agregarTramo', () {
    test('agrega un tramo completo a mano: pendiente y sin editado', () async {
      final f = await repo.agregarTramo(
        userId: fakeUserId,
        date: lunes21,
        ingresoMin: 480,
        egresoMin: 960,
      );
      expect(f.fecha, '2026-09-21');
      expect(f.ingresoMin, 480);
      expect(f.egresoMin, 960);
      // Sin hora del dispositivo no hay original: el CHECK
      // fichadas_editado_coherente no deja marcarlo editado.
      expect(f.editado, isFalse);
      expect(f.ingresoOriginalMin, isNull);
      expect(f.egresoOriginalMin, isNull);
      expect(f.fotoIngresoLocal, isNull);
      expect(f.syncStatus, SyncStatus.pending);
      expect(await repo.unsynced(fakeUserId), hasLength(1));
    });

    test('no agrega en hoy ni a futuro', () async {
      for (final fecha in [hoy, CalendarDate(2026, 9, 25)]) {
        await expectLater(
          repo.agregarTramo(
            userId: fakeUserId,
            date: fecha,
            ingresoMin: 480,
            egresoMin: 960,
          ),
          throwsA(isA<FichadaInvalidaException>()),
        );
      }
      expect(await repo.unsynced(fakeUserId), isEmpty);
    });

    test('no agrega en feriados ni fines de semana', () async {
      await expectLater(
        repo.agregarTramo(
          userId: fakeUserId,
          date: CalendarDate(2026, 9, 15),
          ingresoMin: 480,
          egresoMin: 960,
        ),
        throwsA(
          isA<FichadaInvalidaException>().having(
            (e) => e.message,
            'message',
            contains('Feriado ficticio'),
          ),
        ),
      );
      await expectLater(
        repo.agregarTramo(
          userId: fakeUserId,
          date: CalendarDate(2026, 9, 19), // sábado
          ingresoMin: 480,
          egresoMin: 960,
        ),
        throwsA(isA<FichadaInvalidaException>()),
      );
    });

    test('no agrega un tramo superpuesto con otro del día', () async {
      await insertar('2026-09-21', 480, 720);
      await expectLater(
        repo.agregarTramo(
          userId: fakeUserId,
          date: lunes21,
          ingresoMin: 700,
          egresoMin: 900,
        ),
        throwsA(
          isA<FichadaInvalidaException>().having(
            (e) => e.message,
            'message',
            contains('se superpone con el tramo 08:00–12:00'),
          ),
        ),
      );
      // Pegado al anterior sí se puede.
      final f = await repo.agregarTramo(
        userId: fakeUserId,
        date: lunes21,
        ingresoMin: 720,
        egresoMin: 900,
      );
      expect(f.ingresoMin, 720);
    });

    test('egreso posterior al ingreso', () async {
      await expectLater(
        repo.agregarTramo(
          userId: fakeUserId,
          date: lunes21,
          ingresoMin: 900,
          egresoMin: 900,
        ),
        throwsA(isA<FichadaInvalidaException>()),
      );
    });
  });

  group('editarTramo', () {
    test(
      'corregir el ingreso guarda la hora anterior y marca editado',
      () async {
        final f = await insertar('2026-09-21', 480, 960);
        final e = await repo.editarTramo(
          userId: fakeUserId,
          id: f.id,
          ingresoMin: 490,
          egresoMin: 960,
        );
        expect(e.ingresoMin, 490);
        expect(e.ingresoOriginalMin, 480);
        expect(e.egresoOriginalMin, isNull);
        expect(e.editado, isTrue);
        expect(e.syncStatus, SyncStatus.pending);
        expect(e.revision, f.revision + 1);
      },
    );

    test(
      'conserva la primera original y la borra si se vuelve a ella',
      () async {
        final f = await insertar('2026-09-21', 480, 960);
        await repo.editarTramo(
          userId: fakeUserId,
          id: f.id,
          ingresoMin: 490,
          egresoMin: 970,
        );
        final dos = await repo.editarTramo(
          userId: fakeUserId,
          id: f.id,
          ingresoMin: 495,
          egresoMin: 970,
        );
        expect(dos.ingresoOriginalMin, 480);
        expect(dos.egresoOriginalMin, 960);

        final vuelta = await repo.editarTramo(
          userId: fakeUserId,
          id: f.id,
          ingresoMin: 480,
          egresoMin: 960,
        );
        expect(vuelta.ingresoOriginalMin, isNull);
        expect(vuelta.egresoOriginalMin, isNull);
        expect(vuelta.editado, isFalse);
      },
    );

    test('respeta la hora original del dispositivo al fichar', () async {
      final f = await repo.ficharIngreso(
        userId: fakeUserId,
        date: hoy,
        proposedMin: 490,
        chosenMin: 482,
      );
      final e = await repo.editarTramo(
        userId: fakeUserId,
        id: f.id,
        ingresoMin: 485,
      );
      expect(e.ingresoOriginalMin, 490);
      expect(e.editado, isTrue);
    });

    test('cerrar un tramo abierto no guarda hora original', () async {
      final f = await insertar('2026-09-21', 480);
      final e = await repo.editarTramo(
        userId: fakeUserId,
        id: f.id,
        ingresoMin: 480,
        egresoMin: 960,
      );
      expect(e.egresoMin, 960);
      expect(e.egresoOriginalMin, isNull);
      expect(e.editado, isFalse);
      expect(e.syncStatus, SyncStatus.pending);
    });

    test('bloquea una edición que se superpone', () async {
      await insertar('2026-09-21', 480, 720);
      final tarde = await insertar('2026-09-21', 780, 960);
      await expectLater(
        repo.editarTramo(
          userId: fakeUserId,
          id: tarde.id,
          ingresoMin: 700,
          egresoMin: 960,
        ),
        throwsA(isA<FichadaInvalidaException>()),
      );
      final sinCambios = await repo.findById(tarde.id);
      expect(sinCambios!.ingresoMin, 780);
      expect(sinCambios.syncStatus, SyncStatus.synced);
    });

    test('no deja quitar el egreso ni dejarlo antes del ingreso', () async {
      final f = await insertar('2026-09-21', 480, 960);
      await expectLater(
        repo.editarTramo(userId: fakeUserId, id: f.id, ingresoMin: 480),
        throwsA(isA<FichadaInvalidaException>()),
      );
      await expectLater(
        repo.editarTramo(
          userId: fakeUserId,
          id: f.id,
          ingresoMin: 480,
          egresoMin: 470,
        ),
        throwsA(isA<FichadaInvalidaException>()),
      );
    });

    test('en un día no laborable no cambia horas pero sí cierra', () async {
      final horas = await insertar('2026-09-19', 480, 600, 'sabado-1');
      await expectLater(
        repo.editarTramo(
          userId: fakeUserId,
          id: horas.id,
          ingresoMin: 490,
          egresoMin: 600,
        ),
        throwsA(isA<FichadaInvalidaException>()),
      );
      final abierto = await insertar('2026-09-15', 480, null, 'feriado-1');
      final cerrado = await repo.editarTramo(
        userId: fakeUserId,
        id: abierto.id,
        ingresoMin: 480,
        egresoMin: 600,
      );
      expect(cerrado.egresoMin, 600);
    });

    test('no edita tramos a futuro', () async {
      final f = await insertar('2026-09-25', 480, 960);
      await expectLater(
        repo.editarTramo(
          userId: fakeUserId,
          id: f.id,
          ingresoMin: 490,
          egresoMin: 960,
        ),
        throwsA(isA<FichadaInvalidaException>()),
      );
    });

    test('sin cambios no toca la fila', () async {
      final f = await insertar('2026-09-21', 480, 960);
      final e = await repo.editarTramo(
        userId: fakeUserId,
        id: f.id,
        ingresoMin: 480,
        egresoMin: 960,
      );
      expect(e.revision, f.revision);
      expect(e.syncStatus, SyncStatus.synced);
    });
  });

  group('borrarTramo', () {
    test('borrado lógico: pendiente de subir y fuera de la lista', () async {
      final f = await insertar('2026-09-21', 480, 960);
      await repo.borrarTramo(userId: fakeUserId, id: f.id);

      final row = await repo.findById(f.id);
      expect(row!.deletedAt, isNotNull);
      expect(row.syncStatus, SyncStatus.pending);
      expect(row.revision, f.revision + 1);
      expect(await repo.watchAll(fakeUserId).first, isEmpty);
      expect((await repo.unsynced(fakeUserId)).single.id, f.id);
      // El hueco se puede volver a cargar.
      await repo.agregarTramo(
        userId: fakeUserId,
        date: lunes21,
        ingresoMin: 480,
        egresoMin: 960,
      );
    });

    test('no borra dos veces ni tramos de otro usuario', () async {
      final f = await insertar('2026-09-21', 480, 960);
      await expectLater(
        repo.borrarTramo(userId: 'otro-usuario-ficticio', id: f.id),
        throwsA(isA<FichadaInvalidaException>()),
      );
      await repo.borrarTramo(userId: fakeUserId, id: f.id);
      await expectLater(
        repo.borrarTramo(userId: fakeUserId, id: f.id),
        throwsA(isA<FichadaInvalidaException>()),
      );
    });
  });

  group('parseClock', () {
    test('acepta HH:MM, H:MM, HHMM y horas enteras', () {
      expect(parseClock('08:05'), 485);
      expect(parseClock('8:05'), 485);
      expect(parseClock('0805'), 485);
      expect(parseClock('8'), 480);
      expect(parseClock(' 23:59 '), 1439);
      expect(parseClock('0:00'), 0);
    });

    test('no adivina', () {
      for (final t in ['', '24:00', '8:75', '8.30', '8:5', '-1:00', 'ab']) {
        expect(parseClock(t), isNull, reason: t);
      }
    });
  });

  group('validarTramoManual', () {
    test('un alta necesita egreso', () {
      expect(
        validarTramoManual(
          accion: EdicionTramo.alta,
          fecha: lunes21,
          hoy: hoy,
          ingresoMin: 480,
          otrosDelDia: const [],
          feriados: const [],
        ),
        'Falta la hora de egreso.',
      );
    });

    test('editar el ingreso de un tramo abierto de hoy es válido', () {
      expect(
        validarTramoManual(
          accion: EdicionTramo.edicion,
          fecha: hoy,
          hoy: hoy,
          ingresoMin: 470,
          otrosDelDia: const [],
          feriados: const [],
        ),
        isNull,
      );
    });
  });
}
