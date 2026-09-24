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
      clock: steppingClock(DateTime(2026, 9, 24, 23)),
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
      await insertar('2026-09-01', 480, 960); // inicio del control
      final f = await insertar('2026-09-21', 480, 960);
      await repo.borrarTramo(userId: fakeUserId, id: f.id);

      final row = await repo.findById(f.id);
      expect(row!.deletedAt, isNotNull);
      expect(row.syncStatus, SyncStatus.pending);
      expect(row.revision, f.revision + 1);
      expect(await repo.watchAll(fakeUserId).first, hasLength(1));
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
      await insertar('2026-09-01', 480, 960);
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

  group('inicio del control', () {
    Future<void> movimiento(String id, String fecha) => db
        .into(db.bancoMovimientos)
        .insert(
          BancoMovimientosCompanion.insert(
            id: id,
            userId: fakeUserId,
            tipo: 'acumulacion',
            fecha: fecha,
            minutos: 60,
            updatedAt: DateTime(2026, 9, 20),
            syncStatus: SyncStatus.synced,
          ),
        );

    test('no se agrega un tramo anterior a la primera fichada', () async {
      await insertar('2026-09-14', 480, 960);
      expect(await repo.inicioControl(fakeUserId), CalendarDate(2026, 9, 14));
      await expectLater(
        repo.agregarTramo(
          userId: fakeUserId,
          date: CalendarDate(2026, 9, 11),
          ingresoMin: 480,
          egresoMin: 960,
        ),
        throwsA(
          isA<FichadaInvalidaException>().having(
            (e) => e.message,
            'message',
            'El control empezó el 14/09/2026 (primera fichada). No se '
                'agregan tramos anteriores.',
          ),
        ),
      );
      // El mismo día del inicio sí.
      await repo.agregarTramo(
        userId: fakeUserId,
        date: CalendarDate(2026, 9, 14),
        ingresoMin: 1000,
        egresoMin: 1100,
      );
    });

    test('sin fichadas, el primer tramo agregado es el inicio', () async {
      expect(await repo.inicioControl(fakeUserId), isNull);
      await repo.agregarTramo(
        userId: fakeUserId,
        date: CalendarDate(2026, 9, 11),
        ingresoMin: 480,
        egresoMin: 960,
      );
      expect(await repo.inicioControl(fakeUserId), CalendarDate(2026, 9, 11));
    });

    test(
      'borrar la primera fichada pide confirmación y dice qué cambia',
      () async {
        final primera = await insertar('2026-09-14', 480, 960);
        final segunda = await insertar('2026-09-17', 480, 960);
        await movimiento('m-14', '2026-09-14');
        await movimiento('m-16', '2026-09-16');
        await movimiento('m-17', '2026-09-17');
        await movimiento('m-10', '2026-09-10'); // ya no computaba

        expect(
          await repo.impactoBorrado(userId: fakeUserId, id: segunda.id),
          isNull,
        );
        final cambio = await repo.impactoBorrado(
          userId: fakeUserId,
          id: primera.id,
        );
        expect(cambio!.anterior, CalendarDate(2026, 9, 14));
        expect(cambio.nuevo, CalendarDate(2026, 9, 17));
        expect(cambio.movimientosQueDejanDeComputar, 2);

        await expectLater(
          repo.borrarTramo(userId: fakeUserId, id: primera.id),
          throwsA(isA<CambioInicioControlException>()),
        );
        expect((await repo.findById(primera.id))!.deletedAt, isNull);

        await repo.borrarTramo(
          userId: fakeUserId,
          id: primera.id,
          confirmarCambioInicio: true,
        );
        expect(await repo.inicioControl(fakeUserId), CalendarDate(2026, 9, 17));
      },
    );

    test('si quedan otros tramos ese día, el inicio no cambia', () async {
      final a = await insertar('2026-09-14', 480, 720);
      await insertar('2026-09-14', 780, 960);
      expect(await repo.impactoBorrado(userId: fakeUserId, id: a.id), isNull);
      await repo.borrarTramo(userId: fakeUserId, id: a.id);
    });

    test('borrar la única fichada vuelve el control a cero', () async {
      final f = await insertar('2026-09-14', 480, 960);
      await movimiento('m-10', '2026-09-10');
      await movimiento('m-20', '2026-09-20');
      final cambio = await repo.impactoBorrado(userId: fakeUserId, id: f.id);
      expect(cambio!.nuevo, isNull);
      expect(cambio.movimientosQueDejanDeComputar, 1);
    });
  });

  group('origen', () {
    test('Fichar = dispositivo; corregirlo sigue siendo dispositivo', () async {
      final f = await repo.ficharIngreso(
        userId: fakeUserId,
        date: hoy,
        proposedMin: 480,
        chosenMin: 480,
      );
      expect(f.origen, 'dispositivo');
      final e = await repo.editarTramo(
        userId: fakeUserId,
        id: f.id,
        ingresoMin: 470,
      );
      expect(e.origenTipo, OrigenFichada.dispositivo);
      expect(e.editado, isTrue);
    });

    test('agregar a mano = manual', () async {
      final f = await repo.agregarTramo(
        userId: fakeUserId,
        date: lunes21,
        ingresoMin: 480,
        egresoMin: 960,
      );
      expect(f.origen, 'manual');
      expect(f.esManual, isTrue);
    });

    test(
      'cerrar con la hora a mano = manual; con la del dispositivo no',
      () async {
        final anterior = await insertar('2026-09-21', 480);
        final cerrado = await repo.ficharEgreso(
          userId: fakeUserId,
          fichadaId: anterior.id,
          proposedMin: null,
          chosenMin: 960,
        );
        expect(cerrado.origen, 'manual');

        final deHoy = await repo.ficharIngreso(
          userId: fakeUserId,
          date: hoy,
          proposedMin: 480,
          chosenMin: 480,
        );
        final egreso = await repo.ficharEgreso(
          userId: fakeUserId,
          fichadaId: deHoy.id,
          proposedMin: 960,
          chosenMin: 950,
        );
        expect(egreso.origen, 'dispositivo');
        expect(egreso.editado, isTrue);
      },
    );

    test('cerrar desde la vista mensual = manual', () async {
      final f = await insertar('2026-09-21', 480);
      final e = await repo.editarTramo(
        userId: fakeUserId,
        id: f.id,
        ingresoMin: 480,
        egresoMin: 960,
      );
      expect(e.origen, 'manual');
    });
  });

  group('hoy, nada posterior a la hora actual', () {
    // Reloj fijo: hoy a las 10:00.
    late FichadasRepository alas10;
    setUp(() {
      alas10 = FichadasRepository(
        db,
        InMemoryPhotoStore(),
        clock: () => DateTime(2026, 9, 24, 10),
        newId: sequentialIds(),
      );
    });

    test('ingreso posterior a la hora actual', () async {
      await expectLater(
        alas10.ficharIngreso(
          userId: fakeUserId,
          date: hoy,
          proposedMin: 600,
          chosenMin: 601,
        ),
        throwsA(
          isA<FichadaInvalidaException>().having(
            (e) => e.message,
            'message',
            'Son las 10:00: el ingreso (10:01) no puede ser posterior a la '
                'hora actual.',
          ),
        ),
      );
      final f = await alas10.ficharIngreso(
        userId: fakeUserId,
        date: hoy,
        proposedMin: 600,
        chosenMin: 600,
      );
      expect(f.ingresoMin, 600);
    });

    test(
      'egreso posterior a la hora actual (Fichar y vista mensual)',
      () async {
        final f = await insertar('2026-09-24', 480);
        await expectLater(
          alas10.ficharEgreso(
            userId: fakeUserId,
            fichadaId: f.id,
            proposedMin: 600,
            chosenMin: 660,
          ),
          throwsA(isA<FichadaInvalidaException>()),
        );
        await expectLater(
          alas10.editarTramo(
            userId: fakeUserId,
            id: f.id,
            ingresoMin: 480,
            egresoMin: 660,
          ),
          throwsA(isA<FichadaInvalidaException>()),
        );
        await expectLater(
          alas10.editarTramo(userId: fakeUserId, id: f.id, ingresoMin: 610),
          throwsA(isA<FichadaInvalidaException>()),
        );
        final e = await alas10.editarTramo(
          userId: fakeUserId,
          id: f.id,
          ingresoMin: 480,
          egresoMin: 600,
        );
        expect(e.egresoMin, 600);
      },
    );

    test('los días anteriores no tienen tope', () async {
      final f = await insertar('2026-09-23', 480);
      final e = await alas10.ficharEgreso(
        userId: fakeUserId,
        fichadaId: f.id,
        proposedMin: null,
        chosenMin: 1200,
      );
      expect(e.egresoMin, 1200);
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
