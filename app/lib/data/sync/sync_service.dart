import '../../domain/domain.dart';
import '../fichadas/fichadas_repository.dart';
import '../fichadas/remote_fichada.dart';
import '../local/app_database.dart';
import 'fichadas_remote.dart';

/// Ruta de la foto en el bucket `comprobantes`:
/// `{user_id}/{yyyy}/{mm}/{id}_{ingreso|egreso}.jpg`.
String comprobantePath({
  required String userId,
  required CalendarDate fecha,
  required String fichadaId,
  required TipoFichada tipo,
}) =>
    '$userId/${fecha.year.toString().padLeft(4, '0')}/'
    '${fecha.month.toString().padLeft(2, '0')}/${fichadaId}_${tipo.name}.jpg';

/// Resultado de una pasada de sincronización.
class SyncResult {
  const SyncResult({
    this.uploaded = 0,
    this.failed = 0,
    this.downloaded = 0,
    this.offline = false,
    this.message,
  });

  /// Filas subidas.
  final int uploaded;

  /// Filas que quedaron con error.
  final int failed;

  /// Filas bajadas del servidor.
  final int downloaded;

  /// Se cortó por falta de red: lo que falta sigue pendiente.
  final bool offline;

  /// Detalle del último problema, si hubo.
  final String? message;
}

/// Cola de sincronización de fichadas.
///
/// 1. Sube las filas pendientes o con error: primero las fotos y después el
///    upsert de la fila (gana el último que sincroniza).
/// 2. Baja los cambios del servidor sin pisar lo que falta subir.
/// 3. Actualiza los feriados cada tanto.
///
/// Si no hay red corta sin marcar errores: las filas quedan pendientes.
class SyncService {
  SyncService({
    required FichadasRepository repository,
    required FichadasRemote remote,
    DateTime Function()? clock,
    this.holidaysRefreshEvery = const Duration(hours: 12),
  }) : _repo = repository,
       _api = remote,
       _clock = clock ?? DateTime.now;

  final FichadasRepository _repo;
  final FichadasRemote _api;
  final DateTime Function() _clock;
  final Duration holidaysRefreshEvery;

  /// Cursor de la última descarga, por usuario.
  static String pulledAtKey(String userId) => 'fichadas_pulled_at:$userId';
  static const holidaysAtKey = 'feriados_pulled_at';

  Future<SyncResult>? _running;
  bool _again = false;

  /// Sincroniza las fichadas de [userId]. Si ya hay una pasada en curso, se
  /// encola otra al terminar y se devuelve la misma.
  Future<SyncResult> sync(String userId) {
    final running = _running;
    if (running != null) {
      _again = true;
      return running;
    }
    final future = _loop(userId);
    _running = future;
    return future.whenComplete(() => _running = null);
  }

  Future<SyncResult> _loop(String userId) async {
    SyncResult result;
    do {
      _again = false;
      result = await _runOnce(userId);
    } while (_again && !result.offline);
    return result;
  }

  Future<SyncResult> _runOnce(String userId) async {
    var uploaded = 0;
    var failed = 0;
    var downloaded = 0;
    String? message;

    // 1. Subida.
    for (final row in await _repo.unsynced(userId)) {
      try {
        final warning = await _push(row);
        if (warning != null) {
          await _repo.markError(row.id, row.revision, warning);
          failed++;
          message = warning;
        } else {
          uploaded++;
          final stillSame = await _repo.markSynced(row.id, row.revision);
          // Cambió mientras subía: otra vuelta.
          if (!stillSame) _again = true;
        }
      } on RemoteUnavailableException catch (e) {
        return SyncResult(
          uploaded: uploaded,
          failed: failed,
          offline: true,
          message: e.message,
        );
      } on RemoteRejectedException catch (e) {
        await _repo.markError(row.id, row.revision, e.message);
        failed++;
        message = e.message;
      }
    }

    // 2. Bajada.
    try {
      final since = await _repo.readState(pulledAtKey(userId));
      final rows = await _api.fetchFichadasChangedSince(
        since == null ? null : DateTime.parse(since),
      );
      if (rows.isNotEmpty) {
        await _repo.applyRemote(rows);
        downloaded = rows.length;
        final last = rows
            .map((r) => r.updatedAt)
            .whereType<DateTime>()
            .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
        if (last != null) {
          await _repo.writeState(
            pulledAtKey(userId),
            last.toUtc().toIso8601String(),
          );
        }
      }

      // 3. Feriados.
      final holidaysAt = await _repo.readState(holidaysAtKey);
      final now = _clock();
      if (holidaysAt == null ||
          now.difference(DateTime.parse(holidaysAt)) >= holidaysRefreshEvery) {
        await _repo.replaceHolidays(await _api.fetchFeriados());
        await _repo.writeState(holidaysAtKey, now.toUtc().toIso8601String());
      }
    } on RemoteUnavailableException catch (e) {
      return SyncResult(
        uploaded: uploaded,
        failed: failed,
        downloaded: downloaded,
        offline: true,
        message: e.message,
      );
    } on RemoteRejectedException catch (e) {
      message = e.message;
    }

    return SyncResult(
      uploaded: uploaded,
      failed: failed,
      downloaded: downloaded,
      message: message,
    );
  }

  /// Sube las fotos que falten y después la fila. Devuelve un aviso si la
  /// fila se subió pero falta alguna foto en el dispositivo.
  Future<String?> _push(LocalFichada row) async {
    var ingresoPath = row.fotoIngresoPath;
    var egresoPath = row.fotoEgresoPath;
    String? warning;

    for (final tipo in TipoFichada.values) {
      final isIngreso = tipo == TipoFichada.ingreso;
      final localRef = isIngreso ? row.fotoIngresoLocal : row.fotoEgresoLocal;
      final remotePath = isIngreso ? ingresoPath : egresoPath;
      if (localRef == null || remotePath != null) continue;

      final bytes = await _repo.readPhoto(localRef);
      if (bytes == null) {
        warning =
            'No se encontró la foto de ${tipo.label} en este '
            'dispositivo. La fichada se subió sin foto.';
        continue;
      }
      final path = comprobantePath(
        userId: row.userId,
        fecha: row.date,
        fichadaId: row.id,
        tipo: tipo,
      );
      await _api.uploadPhoto(path: path, bytes: bytes);
      await _repo.setRemotePhotoPath(row.id, tipo, path);
      if (isIngreso) {
        ingresoPath = path;
      } else {
        egresoPath = path;
      }
    }

    final base = RemoteFichada.fromLocal(row);
    await _api.upsertFichada(
      RemoteFichada(
        id: base.id,
        userId: base.userId,
        fecha: base.fecha,
        ingresoMin: base.ingresoMin,
        egresoMin: base.egresoMin,
        ingresoOriginalMin: base.ingresoOriginalMin,
        egresoOriginalMin: base.egresoOriginalMin,
        editado: base.editado,
        fotoIngresoPath: ingresoPath,
        fotoEgresoPath: egresoPath,
        observacion: base.observacion,
        deletedAt: base.deletedAt,
      ),
    );
    return warning;
  }
}
