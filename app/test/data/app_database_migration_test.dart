import 'package:asistente/data/local/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

/// `fichadas` tal como estaba antes de la versión 4 (sin `origen`).
const _fichadasSinOrigen =
    'CREATE TABLE fichadas (id TEXT NOT NULL, user_id TEXT NOT NULL, '
    'fecha TEXT NOT NULL, ingreso_min INTEGER NOT NULL, '
    'egreso_min INTEGER NULL, ingreso_original_min INTEGER NULL, '
    'egreso_original_min INTEGER NULL, editado INTEGER NOT NULL '
    'DEFAULT 0, foto_ingreso_path TEXT NULL, foto_egreso_path TEXT '
    'NULL, foto_ingreso_local TEXT NULL, foto_egreso_local TEXT NULL, '
    'observacion TEXT NULL, deleted_at INTEGER NULL, updated_at '
    'INTEGER NOT NULL, revision INTEGER NOT NULL DEFAULT 0, '
    'sync_status TEXT NOT NULL, sync_error TEXT NULL, '
    'PRIMARY KEY (id))';

void main() {
  test(
    'v1 → v2: agrega feriados.tipo, crea profiles y rebaja feriados',
    () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            // Tablas de la versión 1 que toca la migración.
            raw.execute(_fichadasSinOrigen);
            raw.execute(
              'CREATE TABLE feriados (fecha TEXT NOT NULL, '
              'nombre TEXT NOT NULL, PRIMARY KEY (fecha))',
            );
            raw.execute(
              'CREATE TABLE sync_state (key TEXT NOT NULL, '
              'value TEXT NOT NULL, PRIMARY KEY (key))',
            );
            raw.execute(
              "INSERT INTO feriados VALUES ('2026-10-12', 'Feriado ficticio')",
            );
            raw.execute(
              "INSERT INTO sync_state VALUES ('feriados_pulled_at', "
              "'2026-09-24T00:00:00.000Z')",
            );
            raw.execute('PRAGMA user_version = 1');
          },
        ),
      );
      addTearDown(db.close);

      final feriado = await db.select(db.feriados).getSingle();
      expect(feriado.tipo, 'inamovible');
      expect(await db.select(db.syncState).get(), isEmpty);

      await db
          .into(db.profiles)
          .insert(
            ProfilesCompanion.insert(
              userId: fakeUserId,
              updatedAt: DateTime(2026, 9, 24),
              syncStatus: SyncStatus.pending,
            ),
          );
      expect(await db.select(db.profiles).get(), hasLength(1));
    },
  );

  test('v2 → v3: crea las tablas del banco sin tocar las fichadas', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute(_fichadasSinOrigen);
          raw.execute(
            "INSERT INTO fichadas (id, user_id, fecha, ingreso_min, "
            "updated_at, sync_status) VALUES ('ficticia', '$fakeUserId', "
            "'2026-09-24', 480, 0, 'pending')",
          );
          raw.execute('PRAGMA user_version = 2');
        },
      ),
    );
    addTearDown(db.close);

    expect(await db.select(db.fichadas).get(), hasLength(1));
    expect(await db.select(db.bancoMovimientos).get(), isEmpty);
    expect(await db.select(db.tiposDocumentoGde).get(), isEmpty);
    await db
        .into(db.tiposDocumentoGde)
        .insert(
          TiposDocumentoGdeCompanion.insert(
            id: 'tipo-ficticio',
            userId: fakeUserId,
            codigo: 'FSOLI',
            updatedAt: DateTime(2026, 9, 24),
            syncStatus: SyncStatus.pending,
          ),
        );
    expect(await db.select(db.tiposDocumentoGde).get(), hasLength(1));
  });

  test(
    'v3 → v4: agrega fichadas.origen y las filas quedan dispositivo',
    () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute(_fichadasSinOrigen);
            raw.execute(
              "INSERT INTO fichadas (id, user_id, fecha, ingreso_min, "
              "updated_at, sync_status) VALUES ('ficticia', '$fakeUserId', "
              "'2026-09-24', 480, 0, 'synced')",
            );
            raw.execute('PRAGMA user_version = 3');
          },
        ),
      );
      addTearDown(db.close);

      final vieja = await db.select(db.fichadas).getSingle();
      expect(vieja.origen, 'dispositivo');
      // La migración no toca el estado de sync (no hay nada que subir).
      expect(vieja.syncStatus, SyncStatus.synced);

      await db
          .into(db.fichadas)
          .insert(
            FichadasCompanion.insert(
              id: 'manual-ficticia',
              userId: fakeUserId,
              fecha: '2026-09-23',
              ingresoMin: 480,
              origen: const Value('manual'),
              updatedAt: DateTime(2026, 9, 24),
              syncStatus: SyncStatus.pending,
            ),
          );
      final manual = await (db.select(
        db.fichadas,
      )..where((f) => f.id.equals('manual-ficticia'))).getSingle();
      expect(manual.origen, 'manual');
    },
  );
}
