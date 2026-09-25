import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/format/formatters.dart';
import '../attachments/attachment.dart';
import '../local/app_database.dart';
import '../photos/photo_store.dart';
import 'curso.dart';
import 'remote_curso.dart';

/// El curso no se puede guardar así. El mensaje es para el usuario.
class CursoInvalidoException implements Exception {
  const CursoInvalidoException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Cursos de capacitación en la base local. La UI lee solo de acá; cada
/// escritura queda `pending` hasta que la sube el sync (fila por fila). No
/// hay borrado físico: se marca `deleted_at`.
class CursosRepository {
  CursosRepository(
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

  $CursosTable get _c => _db.cursos;

  // ---------------------------------------------------------------------------
  // Lectura
  // ---------------------------------------------------------------------------

  /// Cursos activos del usuario: los más recientes primero (por fecha de
  /// inicio; los que no tienen fecha, al final).
  Stream<List<LocalCurso>> watchCursos(String userId) =>
      (_db.select(_c)
            ..where((c) => c.userId.equals(userId) & c.deletedAt.isNull())
            ..orderBy([
              (c) => OrderingTerm(
                expression: c.fechaInicio,
                mode: OrderingMode.desc,
                nulls: NullsOrder.last,
              ),
              (c) => OrderingTerm.desc(c.updatedAt),
            ]))
          .watch();

  Future<LocalCurso?> findCurso(String id) =>
      (_db.select(_c)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<Uint8List?> readCertificado(String localRef) => _files.read(localRef);

  // ---------------------------------------------------------------------------
  // Escritura
  // ---------------------------------------------------------------------------

  /// Crea o edita un curso. Queda pendiente de subir.
  ///
  /// Lanza [CursoInvalidoException] si no se puede guardar (actividad
  /// vacía, créditos negativos o fin anterior al inicio).
  Future<LocalCurso> guardarCurso({
    required String userId,
    required CursoDraft draft,
    CambioAdjunto certificado = const MantenerAdjunto(),
  }) async {
    final original = draft.id == null ? null : await findCurso(draft.id!);
    if (draft.id != null &&
        (original == null || original.userId != userId || original.isDeleted)) {
      throw const CursoInvalidoException('No se encontró el curso.');
    }
    final motivo = draft.validar();
    if (motivo != null) throw CursoInvalidoException(motivo);

    final id = original?.id ?? _newId();

    // Certificado: se guarda local y se sube en el sync.
    var local = original?.certificadoLocal;
    var path = original?.certificadoPath;
    switch (certificado) {
      case MantenerAdjunto():
        break;
      case QuitarAdjunto():
        if (local != null) await _files.delete(local);
        local = null;
        path = null;
      case NuevoAdjunto(:final archivo):
        if (archivo.bytes.length > attachmentMaxBytes) {
          throw const CursoInvalidoException(
            'El certificado supera los 10 MB.',
          );
        }
        final nuevo = await _files.save(
          '${id}_certificado.${archivo.extension}',
          archivo.bytes,
        );
        if (local != null && local != nuevo) await _files.delete(local);
        local = nuevo;
        path = null; // hay que volver a subirlo
    }

    await _db
        .into(_c)
        .insertOnConflictUpdate(
          CursosCompanion(
            id: Value(id),
            userId: Value(userId),
            actividad: Value(draft.actividad.trim()),
            codigo: Value(_clean(draft.codigo)),
            portal: Value(_clean(draft.portal)),
            fechaInicio: Value(
              draft.fechaInicio == null ? null : toIsoDate(draft.fechaInicio!),
            ),
            fechaFin: Value(
              draft.fechaFin == null ? null : toIsoDate(draft.fechaFin!),
            ),
            creditos: Value(draft.creditos),
            estado: Value(draft.estado.dbValue),
            ifGde: Value(_clean(draft.ifGde)),
            certificadoLocal: Value(local),
            certificadoPath: Value(path),
            observacion: Value(_clean(draft.observacion)),
            updatedAt: Value(_clock()),
            revision: Value((original?.revision ?? 0) + 1),
            syncStatus: const Value(SyncStatus.pending),
            syncError: const Value(null),
          ),
        );
    return (await findCurso(id))!;
  }

  /// Borrado lógico: marca `deleted_at` y lo sube en el sync. La copia local
  /// del certificado se conserva hasta que se suba.
  Future<void> borrarCurso({required String userId, required String id}) async {
    final c = await findCurso(id);
    if (c == null || c.userId != userId || c.isDeleted) {
      throw const CursoInvalidoException('No se encontró el curso.');
    }
    await (_db.update(_c)..where((r) => r.id.equals(id))).write(
      CursosCompanion(
        deletedAt: Value(_clock()),
        updatedAt: Value(_clock()),
        revision: Value(c.revision + 1),
        syncStatus: const Value(SyncStatus.pending),
        syncError: const Value(null),
      ),
    );
  }

  static String? _clean(String? s) {
    final t = s?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  // ---------------------------------------------------------------------------
  // Soporte para la sincronización
  // ---------------------------------------------------------------------------

  Future<List<LocalCurso>> unsyncedCursos(String userId) =>
      (_db.select(_c)
            ..where(
              (c) =>
                  c.userId.equals(userId) &
                  c.syncStatus.equalsValue(SyncStatus.synced).not(),
            )
            ..orderBy([(c) => OrderingTerm.asc(c.updatedAt)]))
          .get();

  /// Guarda la ruta en Storage de un certificado ya subido. No es un cambio
  /// del usuario: no toca la revisión ni el estado.
  Future<void> setRemoteCertificadoPath(String id, String path) =>
      (_db.update(_c)..where((c) => c.id.equals(id))).write(
        CursosCompanion(certificadoPath: Value(path)),
      );

  Future<bool> markCursoSynced(String id, int revision) async {
    final n =
        await (_db.update(
          _c,
        )..where((c) => c.id.equals(id) & c.revision.equals(revision))).write(
          const CursosCompanion(
            syncStatus: Value(SyncStatus.synced),
            syncError: Value(null),
          ),
        );
    return n > 0;
  }

  Future<void> markCursoError(String id, int revision, String message) =>
      (_db.update(
        _c,
      )..where((c) => c.id.equals(id) & c.revision.equals(revision))).write(
        CursosCompanion(
          syncStatus: const Value(SyncStatus.error),
          syncError: Value(message),
        ),
      );

  /// Aplica cursos bajados del servidor sin pisar cambios locales sin subir.
  /// Conserva la copia local del certificado si es el mismo.
  Future<void> applyRemoteCursos(Iterable<RemoteCurso> rows) =>
      _db.transaction(() async {
        for (final r in rows) {
          final local = await findCurso(r.id);
          if (local != null && local.syncStatus != SyncStatus.synced) continue;
          final mismoCertificado =
              local != null &&
              local.certificadoPath != null &&
              local.certificadoPath == r.certificadoPath;
          await _db
              .into(_c)
              .insertOnConflictUpdate(
                CursosCompanion(
                  id: Value(r.id),
                  userId: Value(r.userId),
                  actividad: Value(r.actividad),
                  codigo: Value(r.codigo),
                  portal: Value(r.portal),
                  fechaInicio: Value(r.fechaInicio),
                  fechaFin: Value(r.fechaFin),
                  creditos: Value(r.creditos),
                  estado: Value(r.estado),
                  ifGde: Value(r.ifGde),
                  certificadoPath: Value(r.certificadoPath),
                  certificadoLocal: Value(
                    mismoCertificado ? local.certificadoLocal : null,
                  ),
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
