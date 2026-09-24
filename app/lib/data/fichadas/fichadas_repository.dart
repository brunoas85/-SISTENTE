import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/format/formatters.dart';
import '../../domain/domain.dart';
import '../local/app_database.dart';
import '../photos/photo_store.dart';
import 'fichada_validation.dart';
import 'remote_fichada.dart';

/// Ingreso o egreso de un tramo.
enum TipoFichada {
  ingreso,
  egreso;

  String get label => this == ingreso ? 'ingreso' : 'egreso';
}

/// La fichada no se puede guardar así. El mensaje es para el usuario.
class FichadaInvalidaException implements Exception {
  const FichadaInvalidaException(this.message);
  final String message;

  @override
  String toString() => message;
}

extension LocalFichadaX on LocalFichada {
  CalendarDate get date => parseIsoDate(fecha);

  /// Sin egreso: está abierta y no computa.
  bool get isOpen => egresoMin == null;

  bool get isDeleted => deletedAt != null;

  DailyRecord toDailyRecord() => DailyRecord(
    id: id,
    date: date,
    checkInMinutes: ingresoMin,
    checkOutMinutes: egresoMin,
  );
}

/// Fichadas en la base local. La UI lee solo de acá; cada escritura queda
/// `pending` hasta que la sube [SyncService].
class FichadasRepository {
  FichadasRepository(
    this._db,
    this._photos, {
    DateTime Function()? clock,
    String Function()? newId,
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? const Uuid().v4;

  final AppDatabase _db;
  final PhotoStore _photos;
  final DateTime Function() _clock;
  final String Function() _newId;

  $FichadasTable get _t => _db.fichadas;

  // ---------------------------------------------------------------------------
  // Lectura
  // ---------------------------------------------------------------------------

  /// Tramos activos de [date], ordenados por ingreso.
  Stream<List<LocalFichada>> watchDay(String userId, CalendarDate date) =>
      (_db.select(_t)
            ..where(
              (f) =>
                  f.userId.equals(userId) &
                  f.fecha.equals(toIsoDate(date)) &
                  f.deletedAt.isNull(),
            )
            ..orderBy([(f) => OrderingTerm.asc(f.ingresoMin)]))
          .watch();

  /// Todas las fichadas activas del usuario, por fecha e ingreso.
  Stream<List<LocalFichada>> watchAll(String userId) =>
      (_db.select(_t)
            ..where((f) => f.userId.equals(userId) & f.deletedAt.isNull())
            ..orderBy([
              (f) => OrderingTerm.asc(f.fecha),
              (f) => OrderingTerm.asc(f.ingresoMin),
            ]))
          .watch();

  /// Cantidad de fichadas que todavía no están sincronizadas (pendientes o
  /// con error).
  Stream<int> watchUnsyncedCount(String userId) {
    final count = _t.id.count();
    final query = _db.selectOnly(_t)
      ..addColumns([count])
      ..where(
        _t.userId.equals(userId) &
            _t.syncStatus.equalsValue(SyncStatus.synced).not(),
      );
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  /// Feriados guardados en el dispositivo, por fecha.
  Stream<List<Holiday>> watchHolidays() =>
      (_db.select(_db.feriados)..orderBy([(f) => OrderingTerm.asc(f.fecha)]))
          .watch()
          .map((rows) => [for (final r in rows) _toHoliday(r)]);

  static Holiday _toHoliday(LocalFeriado r) => Holiday(
    date: parseIsoDate(r.fecha),
    name: r.nombre,
    kind: HolidayKind.fromDbValue(r.tipo),
  );

  /// Feriados de [date] guardados en el dispositivo.
  Future<List<Holiday>> _holidaysOn(CalendarDate date) async => [
    for (final r in await (_db.select(
      _db.feriados,
    )..where((f) => f.fecha.equals(toIsoDate(date)))).get())
      _toHoliday(r),
  ];

  /// `true` si hay algún feriado guardado en el dispositivo.
  Future<bool> hasHolidays() async =>
      (await (_db.select(_db.feriados)..limit(1)).get()).isNotEmpty;

  Future<LocalFichada?> findById(String id) =>
      (_db.select(_t)..where((f) => f.id.equals(id))).getSingleOrNull();

  Future<Uint8List?> readPhoto(String localRef) => _photos.read(localRef);

  // ---------------------------------------------------------------------------
  // Fichar
  // ---------------------------------------------------------------------------

  /// Tramos activos sin egreso del usuario (de cualquier fecha), del más
  /// viejo al más nuevo.
  Future<List<LocalFichada>> openRecords(String userId) =>
      (_db.select(_t)
            ..where(
              (f) =>
                  f.userId.equals(userId) &
                  f.deletedAt.isNull() &
                  f.egresoMin.isNull(),
            )
            ..orderBy([
              (f) => OrderingTerm.asc(f.fecha),
              (f) => OrderingTerm.asc(f.ingresoMin),
            ]))
          .get();

  Future<List<LocalFichada>> _dayRecords(String userId, String fecha) =>
      (_db.select(_t)..where(
            (f) =>
                f.userId.equals(userId) &
                f.fecha.equals(fecha) &
                f.deletedAt.isNull(),
          ))
          .get();

  /// Abre un tramo nuevo en [date].
  ///
  /// [proposedMin] es la hora del dispositivo y [chosenMin] la que confirmó
  /// el usuario. Si difieren, se guarda la propuesta en
  /// `ingreso_original_min` y `editado = true`. La foto es opcional.
  ///
  /// No se puede fichar en un día no laborable (fin de semana, feriado o no
  /// laborable turístico, según los feriados guardados en el dispositivo).
  /// Tampoco se puede abrir un tramo si hay otro abierto (de hoy o de un día
  /// anterior: hay que cerrarlo primero) ni si se superpone con otro tramo
  /// del mismo día.
  Future<LocalFichada> ficharIngreso({
    required String userId,
    required CalendarDate date,
    required int proposedMin,
    required int chosenMin,
    Uint8List? photoJpeg,
  }) async {
    _checkMinutes(proposedMin);
    _checkMinutes(chosenMin);
    final noLaborable = nonWorkingDayFor(date, await _holidaysOn(date));
    if (noLaborable != null) {
      throw FichadaInvalidaException(
        '${motivoDiaNoLaborable(noLaborable, esHoy: date == CalendarDate.fromDateTime(_clock()))}. '
        'No se puede fichar.',
      );
    }
    final open = await openRecords(userId);
    if (open.isNotEmpty) {
      final o = open.first;
      throw FichadaInvalidaException(
        o.fecha == toIsoDate(date)
            ? 'Ya hay un tramo abierto desde las ${formatClock(o.ingresoMin)}. '
                  'Fichá el egreso primero.'
            : 'Quedó abierto el tramo del ${formatDate(o.date)} desde las '
                  '${formatClock(o.ingresoMin)}. Cerralo antes de fichar.',
      );
    }
    final motivo = validarTramo(
      fecha: date,
      ingresoMin: chosenMin,
      otrosDelDia: await _dayRecords(userId, toIsoDate(date)),
    );
    if (motivo != null) throw FichadaInvalidaException(motivo);

    final id = _newId();
    final photoRef = photoJpeg == null
        ? null
        : await _photos.save(_photoName(id, TipoFichada.ingreso), photoJpeg);
    final original = chosenMin != proposedMin ? proposedMin : null;

    await _db
        .into(_t)
        .insert(
          FichadasCompanion.insert(
            id: id,
            userId: userId,
            fecha: toIsoDate(date),
            ingresoMin: chosenMin,
            ingresoOriginalMin: Value(original),
            editado: Value(original != null),
            fotoIngresoLocal: Value(photoRef),
            updatedAt: _clock(),
            revision: const Value(1),
            syncStatus: SyncStatus.pending,
          ),
        );
    return (await findById(id))!;
  }

  /// Cierra el tramo abierto [fichadaId].
  ///
  /// El egreso tiene que ser posterior al ingreso (no hay turnos que crucen
  /// la medianoche) y el tramo cerrado no puede superponerse con otro del
  /// mismo día. Si [chosenMin] difiere de [proposedMin], se guarda la
  /// propuesta en `egreso_original_min` y `editado = true`.
  ///
  /// [proposedMin] es `null` cuando no hay hora del dispositivo que proponer
  /// (cerrar un tramo de un día anterior, con la hora a mano): no se guarda
  /// hora original. La foto es opcional.
  ///
  /// Cerrar un tramo abierto se permite siempre, aunque hoy no sea laborable
  /// (si no, un tramo abierto bloquearía las fichadas siguientes).
  Future<LocalFichada> ficharEgreso({
    required String userId,
    required String fichadaId,
    required int? proposedMin,
    required int chosenMin,
    Uint8List? photoJpeg,
  }) async {
    if (proposedMin != null) _checkMinutes(proposedMin);
    _checkMinutes(chosenMin);
    final row = await findById(fichadaId);
    if (row == null || row.userId != userId || row.isDeleted) {
      throw const FichadaInvalidaException('No se encontró el tramo abierto.');
    }
    if (!row.isOpen) {
      throw const FichadaInvalidaException('Ese tramo ya tiene egreso.');
    }
    final motivo = validarTramo(
      fecha: row.date,
      id: row.id,
      ingresoMin: row.ingresoMin,
      egresoMin: chosenMin,
      otrosDelDia: await _dayRecords(userId, row.fecha),
    );
    if (motivo != null) throw FichadaInvalidaException(motivo);

    final photoRef = photoJpeg == null
        ? null
        : await _photos.save(_photoName(row.id, TipoFichada.egreso), photoJpeg);
    final original = proposedMin != null && chosenMin != proposedMin
        ? proposedMin
        : null;

    await (_db.update(_t)..where((f) => f.id.equals(row.id))).write(
      FichadasCompanion(
        egresoMin: Value(chosenMin),
        egresoOriginalMin: Value(original),
        // Coherente con el CHECK fichadas_editado_coherente.
        editado: Value(row.ingresoOriginalMin != null || original != null),
        fotoEgresoLocal: Value(photoRef),
        fotoEgresoPath: const Value(null),
        updatedAt: Value(_clock()),
        revision: Value(row.revision + 1),
        syncStatus: const Value(SyncStatus.pending),
        syncError: const Value(null),
      ),
    );
    return (await findById(row.id))!;
  }

  // ---------------------------------------------------------------------------
  // Carga a mano (vista mensual, PC)
  // ---------------------------------------------------------------------------

  CalendarDate get _hoy => CalendarDate.fromDateTime(_clock());

  Future<LocalFichada> _activa(String userId, String id) async {
    final row = await findById(id);
    if (row == null || row.userId != userId || row.isDeleted) {
      throw const FichadaInvalidaException('No se encontró el tramo.');
    }
    return row;
  }

  /// Agrega un tramo completo en un día pasado, con las horas a mano.
  ///
  /// Sin hora del dispositivo no hay hora original: queda `editado = false`
  /// (el CHECK `fichadas_editado_coherente` exige una hora original para
  /// marcarlo). Un tramo agregado desde cero se reconoce porque no tiene
  /// foto; distinguirlo de verdad necesita una columna en el backend.
  ///
  /// Reglas: ver [validarTramoManual] (solo días pasados y laborables, con
  /// egreso posterior al ingreso y sin superposición).
  Future<LocalFichada> agregarTramo({
    required String userId,
    required CalendarDate date,
    required int ingresoMin,
    required int egresoMin,
  }) async {
    final motivo = validarTramoManual(
      accion: EdicionTramo.alta,
      fecha: date,
      hoy: _hoy,
      ingresoMin: ingresoMin,
      egresoMin: egresoMin,
      otrosDelDia: await _dayRecords(userId, toIsoDate(date)),
      feriados: await _holidaysOn(date),
    );
    if (motivo != null) throw FichadaInvalidaException(motivo);

    final id = _newId();
    await _db
        .into(_t)
        .insert(
          FichadasCompanion.insert(
            id: id,
            userId: userId,
            fecha: toIsoDate(date),
            ingresoMin: ingresoMin,
            egresoMin: Value(egresoMin),
            updatedAt: _clock(),
            revision: const Value(1),
            syncStatus: SyncStatus.pending,
          ),
        );
    return (await findById(id))!;
  }

  /// Cambia las horas del tramo [id] a mano: corrige el ingreso o el egreso,
  /// o carga el egreso de un tramo abierto.
  ///
  /// Igual que al fichar, cada hora corregida guarda en `*_original_min` la
  /// que tenía antes de la primera corrección (la del dispositivo, si la
  /// había) y queda `editado = true`. Si una hora vuelve a su valor
  /// original, se borra la original. Cargar el egreso de un tramo abierto no
  /// tiene hora original (igual que cerrar un tramo anterior desde Fichar).
  ///
  /// No se puede quitar el egreso. Reglas: ver [validarTramoManual].
  Future<LocalFichada> editarTramo({
    required String userId,
    required String id,
    required int ingresoMin,
    int? egresoMin,
  }) async {
    final row = await _activa(userId, id);
    if (row.egresoMin != null && egresoMin == null) {
      throw const FichadaInvalidaException(
        'No se puede quitar el egreso. Si el tramo está mal, borralo.',
      );
    }
    if (row.ingresoMin == ingresoMin && row.egresoMin == egresoMin) return row;

    final cambiaHoras =
        row.ingresoMin != ingresoMin ||
        (row.egresoMin != null && row.egresoMin != egresoMin);
    final motivo = validarTramoManual(
      accion: cambiaHoras ? EdicionTramo.edicion : EdicionTramo.cierre,
      fecha: row.date,
      hoy: _hoy,
      id: row.id,
      ingresoMin: ingresoMin,
      egresoMin: egresoMin,
      otrosDelDia: await _dayRecords(userId, row.fecha),
      feriados: await _holidaysOn(row.date),
    );
    if (motivo != null) throw FichadaInvalidaException(motivo);

    final ingresoOriginal = _original(
      anterior: row.ingresoMin,
      original: row.ingresoOriginalMin,
      nueva: ingresoMin,
    );
    final egresoAnterior = row.egresoMin;
    final egresoOriginal = egresoAnterior == null
        ? null // se está cerrando: no hay hora anterior
        : _original(
            anterior: egresoAnterior,
            original: row.egresoOriginalMin,
            nueva: egresoMin!,
          );

    await (_db.update(_t)..where((f) => f.id.equals(row.id))).write(
      FichadasCompanion(
        ingresoMin: Value(ingresoMin),
        egresoMin: Value(egresoMin),
        ingresoOriginalMin: Value(ingresoOriginal),
        egresoOriginalMin: Value(egresoOriginal),
        // Coherente con el CHECK fichadas_editado_coherente.
        editado: Value(ingresoOriginal != null || egresoOriginal != null),
        updatedAt: Value(_clock()),
        revision: Value(row.revision + 1),
        syncStatus: const Value(SyncStatus.pending),
        syncError: const Value(null),
      ),
    );
    return (await findById(row.id))!;
  }

  /// Hora original después de corregir [anterior] a [nueva]: se conserva la
  /// primera ([original] o, si no había, [anterior]) y se borra si la hora
  /// vuelve a ser esa.
  static int? _original({
    required int anterior,
    required int? original,
    required int nueva,
  }) {
    if (nueva == anterior) return original;
    final primera = original ?? anterior;
    return primera == nueva ? null : primera;
  }

  /// Borrado lógico del tramo [id]: marca `deleted_at` y lo sube en el sync.
  /// Las fotos quedan (en el dispositivo y en el bucket).
  Future<void> borrarTramo({required String userId, required String id}) async {
    final row = await _activa(userId, id);
    await (_db.update(_t)..where((f) => f.id.equals(row.id))).write(
      FichadasCompanion(
        deletedAt: Value(_clock()),
        updatedAt: Value(_clock()),
        revision: Value(row.revision + 1),
        syncStatus: const Value(SyncStatus.pending),
        syncError: const Value(null),
      ),
    );
  }

  static void _checkMinutes(int m) {
    if (m < 0 || m > 1439) {
      throw const FichadaInvalidaException('La hora no es válida.');
    }
  }

  static String _photoName(String id, TipoFichada tipo) =>
      '${id}_${tipo.name}.jpg';

  // ---------------------------------------------------------------------------
  // Soporte para la sincronización
  // ---------------------------------------------------------------------------

  /// Filas a subir (pendientes y con error), de la más vieja a la más nueva.
  Future<List<LocalFichada>> unsynced(String userId) =>
      (_db.select(_t)
            ..where(
              (f) =>
                  f.userId.equals(userId) &
                  f.syncStatus.equalsValue(SyncStatus.synced).not(),
            )
            ..orderBy([(f) => OrderingTerm.asc(f.updatedAt)]))
          .get();

  /// Guarda la ruta en Storage de una foto ya subida. No es un cambio del
  /// usuario: no toca la revisión ni el estado.
  Future<void> setRemotePhotoPath(String id, TipoFichada tipo, String path) =>
      (_db.update(_t)..where((f) => f.id.equals(id))).write(
        tipo == TipoFichada.ingreso
            ? FichadasCompanion(fotoIngresoPath: Value(path))
            : FichadasCompanion(fotoEgresoPath: Value(path)),
      );

  /// Marca la fila como sincronizada si no cambió desde [revision].
  /// Devuelve `false` si hubo un cambio local mientras se subía.
  Future<bool> markSynced(String id, int revision) async {
    final n =
        await (_db.update(
          _t,
        )..where((f) => f.id.equals(id) & f.revision.equals(revision))).write(
          const FichadasCompanion(
            syncStatus: Value(SyncStatus.synced),
            syncError: Value(null),
          ),
        );
    return n > 0;
  }

  /// Marca la fila con error si no cambió desde [revision].
  Future<void> markError(String id, int revision, String message) =>
      (_db.update(
        _t,
      )..where((f) => f.id.equals(id) & f.revision.equals(revision))).write(
        FichadasCompanion(
          syncStatus: const Value(SyncStatus.error),
          syncError: Value(message),
        ),
      );

  /// Aplica filas bajadas del servidor. Una fila local con cambios sin
  /// subir no se pisa: se sube después y gana (el último que sincroniza).
  Future<void> applyRemote(Iterable<RemoteFichada> rows) =>
      _db.transaction(() async {
        for (final r in rows) {
          final local = await findById(r.id);
          if (local != null && local.syncStatus != SyncStatus.synced) continue;
          await _db
              .into(_t)
              .insertOnConflictUpdate(
                FichadasCompanion(
                  id: Value(r.id),
                  userId: Value(r.userId),
                  fecha: Value(r.fecha),
                  ingresoMin: Value(r.ingresoMin),
                  egresoMin: Value(r.egresoMin),
                  ingresoOriginalMin: Value(r.ingresoOriginalMin),
                  egresoOriginalMin: Value(r.egresoOriginalMin),
                  editado: Value(r.editado),
                  fotoIngresoPath: Value(r.fotoIngresoPath),
                  fotoEgresoPath: Value(r.fotoEgresoPath),
                  observacion: Value(r.observacion),
                  deletedAt: Value(r.deletedAt),
                  updatedAt: Value(r.updatedAt ?? _clock()),
                  syncStatus: const Value(SyncStatus.synced),
                  syncError: const Value(null),
                ),
              );
        }
      });

  Future<void> replaceHolidays(Iterable<RemoteFeriado> feriados) =>
      _db.transaction(() async {
        await _db.delete(_db.feriados).go();
        await _db.batch(
          (b) => b.insertAll(_db.feriados, [
            for (final f in feriados)
              FeriadosCompanion.insert(
                fecha: f.fecha,
                nombre: f.nombre,
                tipo: Value(f.tipo),
              ),
          ]),
        );
      });

  Future<String?> readState(String key) async => (await (_db.select(
    _db.syncState,
  )..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<void> writeState(String key, String value) => _db
      .into(_db.syncState)
      .insertOnConflictUpdate(
        SyncStateCompanion.insert(key: key, value: value),
      );
}
