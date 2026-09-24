import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/format/formatters.dart';
import '../../domain/domain.dart';
import '../attachments/attachment.dart';
import '../fichadas/fichadas_repository.dart';
import '../local/app_database.dart';
import '../photos/photo_store.dart';
import 'movimiento.dart';
import 'remote_banco.dart';

/// El movimiento o el tipo de documento no se puede guardar así. El mensaje
/// es para el usuario.
class BancoInvalidoException implements Exception {
  const BancoInvalidoException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Movimientos manuales del banco de horas y catálogo de tipos de documento
/// GDE en la base local. La UI lee solo de acá; cada escritura queda
/// `pending` hasta que la sube el sync. No hay borrado físico: se marca
/// `deleted_at`.
class BancoRepository {
  BancoRepository(
    this._db,
    this._files, {
    DateTime Function()? clock,
    String Function()? newId,
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? const Uuid().v4;

  final AppDatabase _db;
  final PhotoStore _files;
  final DateTime Function() _clock;
  final String Function() _newId;

  $BancoMovimientosTable get _m => _db.bancoMovimientos;
  $TiposDocumentoGdeTable get _t => _db.tiposDocumentoGde;

  // ---------------------------------------------------------------------------
  // Lectura
  // ---------------------------------------------------------------------------

  /// Movimientos activos del usuario, del más nuevo al más viejo.
  Stream<List<LocalMovimiento>> watchMovimientos(String userId) =>
      (_db.select(_m)
            ..where((m) => m.userId.equals(userId) & m.deletedAt.isNull())
            ..orderBy([
              (m) => OrderingTerm.desc(m.fecha),
              (m) => OrderingTerm.desc(m.updatedAt),
            ]))
          .watch();

  /// Tipos de documento del usuario (incluidos los borrados, para mostrar
  /// el código de movimientos viejos), por código.
  Stream<List<LocalTipoDocumento>> watchTipos(String userId) =>
      (_db.select(_t)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.asc(t.codigo)]))
          .watch();

  Future<LocalMovimiento?> findMovimiento(String id) =>
      (_db.select(_m)..where((m) => m.id.equals(id))).getSingleOrNull();

  Future<LocalTipoDocumento?> findTipo(String id) =>
      (_db.select(_t)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Uint8List?> readAdjunto(String localRef) => _files.read(localRef);

  /// Todo lo necesario para validar contra el saldo, leído de la base local.
  Future<BancoContexto> contexto(String userId) async {
    final fichadas = await (_db.select(
      _db.fichadas,
    )..where((f) => f.userId.equals(userId) & f.deletedAt.isNull())).get();
    final records = [for (final f in fichadas) f.toDailyRecord()];
    final holidays = [
      for (final r in await _db.select(_db.feriados).get())
        Holiday(
          date: parseIsoDate(r.fecha),
          name: r.nombre,
          kind: HolidayKind.fromDbValue(r.tipo),
        ),
    ];
    final perfil = await (_db.select(
      _db.profiles,
    )..where((p) => p.userId.equals(userId))).getSingleOrNull();
    final movimientos = await (_db.select(
      _m,
    )..where((m) => m.userId.equals(userId) & m.deletedAt.isNull())).get();
    return BancoContexto(
      calculator: buildBankCalculator(
        today: CalendarDate.fromDateTime(_clock()),
        records: records,
        holidays: holidays,
        agrupamiento: Agrupamiento.fromDbValue(perfil?.agrupamiento),
      ),
      records: records,
      movimientos: movimientos,
      holidays: holidays,
    );
  }

  // ---------------------------------------------------------------------------
  // Movimientos
  // ---------------------------------------------------------------------------

  /// Valida [draft] como lo haría [guardarMovimiento], sin guardar.
  Future<String?> validar(String userId, MovimientoDraft draft) async {
    final original = draft.id == null ? null : await findMovimiento(draft.id!);
    return validarMovimiento(
      draft: draft,
      contexto: await contexto(userId),
      original: original,
    );
  }

  /// Crea o edita un movimiento. Queda pendiente de subir.
  ///
  /// - Acumulación: cualquier día (el caso típico es un sábado).
  /// - Usufructo total: solo día hábil; los minutos son la jornada vigente.
  /// - Usufructo parcial: solo día hábil.
  /// - Un usufructo se valida contra el saldo disponible, que incluye los
  ///   usufructos ya cargados a futuro (ver [validarMovimiento]).
  ///
  /// Lanza [BancoInvalidoException] si no se puede guardar.
  Future<LocalMovimiento> guardarMovimiento({
    required String userId,
    required MovimientoDraft draft,
    CambioAdjunto adjunto = const MantenerAdjunto(),
  }) async {
    final original = draft.id == null ? null : await findMovimiento(draft.id!);
    if (draft.id != null &&
        (original == null || original.userId != userId || original.isDeleted)) {
      throw const BancoInvalidoException('No se encontró el movimiento.');
    }
    final ctx = await contexto(userId);
    final motivo = validarMovimiento(
      draft: draft,
      contexto: ctx,
      original: original,
    );
    if (motivo != null) throw BancoInvalidoException(motivo);
    await _checkTipoDocumento(userId, draft.tipoDocumentoId, original);

    final id = original?.id ?? _newId();
    final minutos = minutosEfectivos(draft, ctx.calculator)!;

    // Adjunto: se guarda local y se sube en el sync.
    var adjuntoLocal = original?.adjuntoLocal;
    var adjuntoPath = original?.adjuntoPath;
    switch (adjunto) {
      case MantenerAdjunto():
        break;
      case QuitarAdjunto():
        if (adjuntoLocal != null) await _files.delete(adjuntoLocal);
        adjuntoLocal = null;
        adjuntoPath = null;
      case NuevoAdjunto(:final archivo):
        final nuevo = await _files.save(
          '${id}_adjunto.${archivo.extension}',
          archivo.bytes,
        );
        if (adjuntoLocal != null && adjuntoLocal != nuevo) {
          await _files.delete(adjuntoLocal);
        }
        adjuntoLocal = nuevo;
        adjuntoPath = null; // hay que volver a subirlo
    }

    final companion = BancoMovimientosCompanion(
      id: Value(id),
      userId: Value(userId),
      tipo: Value(draft.tipo.tipoDb),
      alcance: Value(draft.tipo.alcanceDb),
      fecha: Value(toIsoDate(draft.fecha)),
      minutos: Value(minutos),
      estado: Value(original?.estado ?? estadoVigente),
      tipoDocumentoId: Value(draft.tipoDocumentoId),
      numeroGde: Value(_clean(draft.numeroGde)),
      observacion: Value(_clean(draft.observacion)),
      adjuntoLocal: Value(adjuntoLocal),
      adjuntoPath: Value(adjuntoPath),
      updatedAt: Value(_clock()),
      revision: Value((original?.revision ?? 0) + 1),
      syncStatus: const Value(SyncStatus.pending),
      syncError: const Value(null),
    );
    await _db.into(_m).insertOnConflictUpdate(companion);
    return (await findMovimiento(id))!;
  }

  /// Marca un movimiento como perdido (no computa) o lo vuelve a vigente.
  /// Volver a vigente un usufructo se valida contra el saldo disponible.
  Future<LocalMovimiento> marcarPerdido({
    required String userId,
    required String id,
    required bool perdido,
  }) async {
    final m = await _activo(userId, id);
    if (m.perdido == perdido) return m;
    if (!perdido && m.kind.esUsufructo) {
      final motivo = validarSaldoUsufructo(
        contexto: await contexto(userId),
        id: m.id,
        tipo: m.kind,
        fecha: m.date,
        minutos: m.minutos,
      );
      if (motivo != null) {
        throw BancoInvalidoException('No se puede volver a vigente. $motivo');
      }
    }
    await _touch(
      m,
      BancoMovimientosCompanion(
        estado: Value(perdido ? estadoPerdido : estadoVigente),
      ),
    );
    return (await findMovimiento(id))!;
  }

  /// Borrado lógico: marca `deleted_at` y lo sube en el sync.
  Future<void> borrarMovimiento({
    required String userId,
    required String id,
  }) async {
    final m = await _activo(userId, id);
    await _touch(m, BancoMovimientosCompanion(deletedAt: Value(_clock())));
  }

  Future<LocalMovimiento> _activo(String userId, String id) async {
    final m = await findMovimiento(id);
    if (m == null || m.userId != userId || m.isDeleted) {
      throw const BancoInvalidoException('No se encontró el movimiento.');
    }
    return m;
  }

  Future<void> _touch(LocalMovimiento m, BancoMovimientosCompanion change) =>
      (_db.update(_m)..where((r) => r.id.equals(m.id))).write(
        change.copyWith(
          updatedAt: Value(_clock()),
          revision: Value(m.revision + 1),
          syncStatus: const Value(SyncStatus.pending),
          syncError: const Value(null),
        ),
      );

  /// El tipo de documento tiene que ser del usuario (FK compuesta
  /// `banco_tipo_documento_fk`) y estar activo, salvo que ya estuviera
  /// asignado antes de borrarlo.
  Future<void> _checkTipoDocumento(
    String userId,
    String? tipoId,
    LocalMovimiento? original,
  ) async {
    if (tipoId == null) return;
    final t = await findTipo(tipoId);
    if (t == null || t.userId != userId) {
      throw const BancoInvalidoException(
        'El tipo de documento elegido no existe.',
      );
    }
    if (t.isDeleted && original?.tipoDocumentoId != tipoId) {
      throw const BancoInvalidoException(
        'El tipo de documento elegido fue borrado del catálogo.',
      );
    }
  }

  static String? _clean(String? s) {
    final t = s?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  // ---------------------------------------------------------------------------
  // Catálogo de tipos de documento GDE
  // ---------------------------------------------------------------------------

  /// Crea o edita un tipo de documento. El código es único por usuario sin
  /// distinguir mayúsculas.
  Future<LocalTipoDocumento> guardarTipo({
    required String userId,
    String? id,
    required String codigo,
    String? descripcion,
  }) async {
    final original = id == null ? null : await findTipo(id);
    if (id != null &&
        (original == null || original.userId != userId || original.isDeleted)) {
      throw const BancoInvalidoException(
        'No se encontró el tipo de documento.',
      );
    }
    final existentes = await (_db.select(
      _t,
    )..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())).get();
    final motivo = validarCodigoTipo(
      codigo: codigo,
      id: id,
      existentes: existentes,
    );
    if (motivo != null) throw BancoInvalidoException(motivo);

    final newId = original?.id ?? _newId();
    await _db
        .into(_t)
        .insertOnConflictUpdate(
          TiposDocumentoGdeCompanion(
            id: Value(newId),
            userId: Value(userId),
            codigo: Value(codigo.trim()),
            descripcion: Value(_clean(descripcion)),
            updatedAt: Value(_clock()),
            revision: Value((original?.revision ?? 0) + 1),
            syncStatus: const Value(SyncStatus.pending),
            syncError: const Value(null),
          ),
        );
    return (await findTipo(newId))!;
  }

  /// Borrado lógico. Los movimientos que lo usan lo conservan (se muestra
  /// como borrado).
  Future<void> borrarTipo({required String userId, required String id}) async {
    final t = await findTipo(id);
    if (t == null || t.userId != userId || t.isDeleted) {
      throw const BancoInvalidoException(
        'No se encontró el tipo de documento.',
      );
    }
    await (_db.update(_t)..where((r) => r.id.equals(id))).write(
      TiposDocumentoGdeCompanion(
        deletedAt: Value(_clock()),
        updatedAt: Value(_clock()),
        revision: Value(t.revision + 1),
        syncStatus: const Value(SyncStatus.pending),
        syncError: const Value(null),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Soporte para la sincronización
  // ---------------------------------------------------------------------------

  Future<List<LocalTipoDocumento>> unsyncedTipos(String userId) =>
      (_db.select(_t)
            ..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.syncStatus.equalsValue(SyncStatus.synced).not(),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.updatedAt)]))
          .get();

  Future<List<LocalMovimiento>> unsyncedMovimientos(String userId) =>
      (_db.select(_m)
            ..where(
              (m) =>
                  m.userId.equals(userId) &
                  m.syncStatus.equalsValue(SyncStatus.synced).not(),
            )
            ..orderBy([(m) => OrderingTerm.asc(m.updatedAt)]))
          .get();

  /// Guarda la ruta en Storage de un adjunto ya subido. No es un cambio del
  /// usuario: no toca la revisión ni el estado.
  Future<void> setRemoteAdjuntoPath(String id, String path) =>
      (_db.update(_m)..where((m) => m.id.equals(id))).write(
        BancoMovimientosCompanion(adjuntoPath: Value(path)),
      );

  Future<bool> markMovimientoSynced(String id, int revision) async {
    final n =
        await (_db.update(
          _m,
        )..where((m) => m.id.equals(id) & m.revision.equals(revision))).write(
          const BancoMovimientosCompanion(
            syncStatus: Value(SyncStatus.synced),
            syncError: Value(null),
          ),
        );
    return n > 0;
  }

  Future<void> markMovimientoError(String id, int revision, String message) =>
      (_db.update(
        _m,
      )..where((m) => m.id.equals(id) & m.revision.equals(revision))).write(
        BancoMovimientosCompanion(
          syncStatus: const Value(SyncStatus.error),
          syncError: Value(message),
        ),
      );

  Future<bool> markTipoSynced(String id, int revision) async {
    final n =
        await (_db.update(
          _t,
        )..where((t) => t.id.equals(id) & t.revision.equals(revision))).write(
          const TiposDocumentoGdeCompanion(
            syncStatus: Value(SyncStatus.synced),
            syncError: Value(null),
          ),
        );
    return n > 0;
  }

  Future<void> markTipoError(String id, int revision, String message) =>
      (_db.update(
        _t,
      )..where((t) => t.id.equals(id) & t.revision.equals(revision))).write(
        TiposDocumentoGdeCompanion(
          syncStatus: const Value(SyncStatus.error),
          syncError: Value(message),
        ),
      );

  /// Aplica tipos bajados del servidor sin pisar cambios locales sin subir.
  Future<void> applyRemoteTipos(Iterable<RemoteTipoDocumento> rows) =>
      _db.transaction(() async {
        for (final r in rows) {
          final local = await findTipo(r.id);
          if (local != null && local.syncStatus != SyncStatus.synced) continue;
          await _db
              .into(_t)
              .insertOnConflictUpdate(
                TiposDocumentoGdeCompanion(
                  id: Value(r.id),
                  userId: Value(r.userId),
                  codigo: Value(r.codigo),
                  descripcion: Value(r.descripcion),
                  deletedAt: Value(r.deletedAt),
                  updatedAt: Value(r.updatedAt ?? _clock()),
                  syncStatus: const Value(SyncStatus.synced),
                  syncError: const Value(null),
                ),
              );
        }
      });

  /// Aplica movimientos bajados del servidor sin pisar cambios locales sin
  /// subir. Conserva la copia local del adjunto si la hay.
  Future<void> applyRemoteMovimientos(Iterable<RemoteMovimiento> rows) =>
      _db.transaction(() async {
        for (final r in rows) {
          final local = await findMovimiento(r.id);
          if (local != null && local.syncStatus != SyncStatus.synced) continue;
          // Si en otro dispositivo cambiaron el adjunto, la copia local ya no
          // es la misma.
          final mismoAdjunto =
              local != null &&
              local.adjuntoPath != null &&
              local.adjuntoPath == r.adjuntoPath;
          await _db
              .into(_m)
              .insertOnConflictUpdate(
                BancoMovimientosCompanion(
                  id: Value(r.id),
                  userId: Value(r.userId),
                  tipo: Value(r.tipo),
                  alcance: Value(r.alcance),
                  fecha: Value(r.fecha),
                  minutos: Value(r.minutos),
                  estado: Value(r.estado),
                  tipoDocumentoId: Value(r.tipoDocumentoId),
                  numeroGde: Value(r.numeroGde),
                  adjuntoPath: Value(r.adjuntoPath),
                  adjuntoLocal: Value(mismoAdjunto ? local.adjuntoLocal : null),
                  observacion: Value(r.observacion),
                  deletedAt: Value(r.deletedAt),
                  updatedAt: Value(r.updatedAt ?? _clock()),
                  syncStatus: const Value(SyncStatus.synced),
                  syncError: const Value(null),
                ),
              );
        }
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

/// Cantidad de cambios sin sincronizar (fichadas, movimientos del banco y
/// tipos de documento) del usuario. Es el contador global de la UI.
Stream<int> watchUnsyncedTotal(AppDatabase db, String userId) {
  const synced = 'synced';
  return db
      .customSelect(
        'SELECT '
        '(SELECT COUNT(*) FROM fichadas WHERE user_id = ?1 AND sync_status <> ?2) + '
        '(SELECT COUNT(*) FROM banco_movimientos WHERE user_id = ?1 AND sync_status <> ?2) + '
        '(SELECT COUNT(*) FROM tipos_documento_gde WHERE user_id = ?1 AND sync_status <> ?2) '
        'AS total',
        variables: [Variable.withString(userId), Variable.withString(synced)],
        readsFrom: {db.fichadas, db.bancoMovimientos, db.tiposDocumentoGde},
      )
      .watchSingle()
      .map((row) => row.read<int>('total'));
}

/// Referencia útil en los mensajes: "Acumulación del 26/09/2026".
String describirMovimiento(LocalMovimiento m) =>
    '${m.kind.label} del ${formatDate(m.date)}';

/// Extensión del adjunto guardado en el dispositivo (para subirlo).
String adjuntoExtension(LocalMovimiento m) =>
    extensionOf(m.adjuntoLocal) ?? 'jpg';
