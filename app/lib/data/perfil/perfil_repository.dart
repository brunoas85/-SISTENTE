import 'package:drift/drift.dart';

import '../../domain/domain.dart';
import '../fichadas/remote_fichada.dart';
import '../local/app_database.dart';

/// Perfil guardado en el dispositivo.
class Perfil {
  const Perfil({
    required this.userId,
    required this.agrupamiento,
    required this.syncStatus,
    this.syncError,
  });

  final String userId;

  /// `null` si todavía no se eligió.
  final Agrupamiento? agrupamiento;
  final SyncStatus syncStatus;
  final String? syncError;
}

/// Perfil del usuario en la base local. La UI lee solo de acá; elegir el
/// agrupamiento queda `pending` hasta que lo sube el sync.
class PerfilRepository {
  PerfilRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  $ProfilesTable get _t => _db.profiles;

  static Perfil _toPerfil(LocalProfile r) => Perfil(
    userId: r.userId,
    agrupamiento: Agrupamiento.fromDbValue(r.agrupamiento),
    syncStatus: r.syncStatus,
    syncError: r.syncError,
  );

  Future<LocalProfile?> _find(String userId) =>
      (_db.select(_t)..where((p) => p.userId.equals(userId))).getSingleOrNull();

  /// Perfil local de [userId], o `null` si todavía no se bajó ni se eligió
  /// nada en este dispositivo.
  Stream<Perfil?> watchPerfil(String userId) =>
      (_db.select(_t)..where((p) => p.userId.equals(userId)))
          .watchSingleOrNull()
          .map((r) => r == null ? null : _toPerfil(r));

  /// Guarda el agrupamiento elegido. Queda pendiente de subir.
  Future<void> setAgrupamiento(String userId, Agrupamiento agrupamiento) =>
      _db.transaction(() async {
        final current = await _find(userId);
        await _db
            .into(_t)
            .insertOnConflictUpdate(
              ProfilesCompanion.insert(
                userId: userId,
                agrupamiento: Value(agrupamiento.dbValue),
                updatedAt: _clock(),
                revision: Value((current?.revision ?? 0) + 1),
                syncStatus: SyncStatus.pending,
                syncError: const Value(null),
              ),
            );
      });

  // ---------------------------------------------------------------------------
  // Soporte para la sincronización
  // ---------------------------------------------------------------------------

  /// El perfil local si tiene cambios sin subir, o `null`.
  Future<LocalProfile?> unsynced(String userId) async {
    final r = await _find(userId);
    return r == null || r.syncStatus == SyncStatus.synced ? null : r;
  }

  /// Marca el perfil como sincronizado si no cambió desde [revision].
  Future<bool> markSynced(String userId, int revision) async {
    final n =
        await (_db.update(_t)..where(
              (p) => p.userId.equals(userId) & p.revision.equals(revision),
            ))
            .write(
              const ProfilesCompanion(
                syncStatus: Value(SyncStatus.synced),
                syncError: Value(null),
              ),
            );
    return n > 0;
  }

  Future<void> markError(String userId, int revision, String message) =>
      (_db.update(_t)..where(
            (p) => p.userId.equals(userId) & p.revision.equals(revision),
          ))
          .write(
            ProfilesCompanion(
              syncStatus: const Value(SyncStatus.error),
              syncError: Value(message),
            ),
          );

  /// Aplica el perfil bajado del servidor, salvo que haya un cambio local
  /// sin subir. Si el servidor todavía no tiene fila, se guarda como "sin
  /// agrupamiento" (así la app sabe que tiene que pedirlo).
  Future<void> applyRemote(String userId, RemotePerfil? remote) =>
      _db.transaction(() async {
        final local = await _find(userId);
        if (local != null && local.syncStatus != SyncStatus.synced) return;
        await _db
            .into(_t)
            .insertOnConflictUpdate(
              ProfilesCompanion.insert(
                userId: userId,
                agrupamiento: Value(remote?.agrupamiento),
                updatedAt: _clock(),
                revision: Value(local?.revision ?? 0),
                syncStatus: SyncStatus.synced,
                syncError: const Value(null),
              ),
            );
      });
}
