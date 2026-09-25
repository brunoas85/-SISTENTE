import '../../domain/domain.dart';
import '../banco/banco_repository.dart';
import '../banco/movimiento.dart';
import '../banco/remote_banco.dart';
import '../attachments/attachment.dart';
import '../local/app_database.dart';
import 'banco_remote.dart';
import 'fichadas_remote.dart';

/// Ruta del adjunto de un movimiento en el bucket `comprobantes`:
/// `{user_id}/{yyyy}/{mm}/{id}_adjunto.{ext}` (año y mes de la fecha del
/// movimiento).
String adjuntoMovimientoPath({
  required String userId,
  required CalendarDate fecha,
  required String movimientoId,
  required String extension,
}) =>
    '$userId/${fecha.year.toString().padLeft(4, '0')}/'
    '${fecha.month.toString().padLeft(2, '0')}/'
    '${movimientoId}_adjunto.$extension';

/// Resultado de una parte (banco, cursos, …) de una pasada de
/// sincronización.
typedef BancoSyncResult = SectionSyncResult;

/// Resultado de una parte (banco, cursos, …) de una pasada de
/// sincronización.
class SectionSyncResult {
  const SectionSyncResult({
    this.uploaded = 0,
    this.failed = 0,
    this.downloaded = 0,
    this.again = false,
    this.message,
  });

  final int uploaded;
  final int failed;
  final int downloaded;

  /// Alguna fila cambió mientras se subía: conviene otra pasada.
  final bool again;
  final String? message;
}

/// Sincroniza el catálogo de tipos de documento y los movimientos del banco.
///
/// 1. Sube los tipos pendientes (antes que los movimientos, por la FK).
/// 2. Sube los movimientos pendientes: primero el adjunto y después el
///    upsert de la fila.
/// 3. Baja los cambios con cursor por `updated_at`, sin pisar lo que falta
///    subir.
///
/// Sin red lanza [RemoteUnavailableException] y lo que falta queda
/// pendiente.
class BancoSync {
  BancoSync({required BancoRepository repository, required BancoRemote remote})
    : _repo = repository,
      _api = remote;

  final BancoRepository _repo;
  final BancoRemote _api;

  static String tiposPulledAtKey(String userId) =>
      'tipos_documento_gde_pulled_at:$userId';
  static String movimientosPulledAtKey(String userId) =>
      'banco_movimientos_pulled_at:$userId';

  Future<BancoSyncResult> run(String userId) async {
    var uploaded = 0;
    var failed = 0;
    var downloaded = 0;
    var again = false;
    String? message;

    // 1. Tipos de documento.
    for (final t in await _repo.unsyncedTipos(userId)) {
      try {
        await _api.upsertTipoDocumento(RemoteTipoDocumento.fromLocal(t));
        uploaded++;
        if (!await _repo.markTipoSynced(t.id, t.revision)) again = true;
      } on RemoteRejectedException catch (e) {
        final texto = 'Tipo de documento ${t.codigo}: ${e.message}';
        await _repo.markTipoError(t.id, t.revision, texto);
        failed++;
        message = texto;
      }
    }

    // 2. Movimientos.
    for (final m in await _repo.unsyncedMovimientos(userId)) {
      try {
        final warning = await _push(m);
        if (warning != null) {
          await _repo.markMovimientoError(m.id, m.revision, warning);
          failed++;
          message = warning;
        } else {
          uploaded++;
          if (!await _repo.markMovimientoSynced(m.id, m.revision)) {
            again = true;
          }
        }
      } on RemoteRejectedException catch (e) {
        await _repo.markMovimientoError(m.id, m.revision, e.message);
        failed++;
        message = e.message;
      }
    }

    // 3. Bajada.
    try {
      downloaded += await _pull(
        tiposPulledAtKey(userId),
        _api.fetchTiposChangedSince,
        (rows) => _repo.applyRemoteTipos(rows),
        (r) => r.updatedAt,
      );
      downloaded += await _pull(
        movimientosPulledAtKey(userId),
        _api.fetchMovimientosChangedSince,
        (rows) => _repo.applyRemoteMovimientos(rows),
        (r) => r.updatedAt,
      );
    } on RemoteRejectedException catch (e) {
      message = 'No se pudo bajar el banco de horas: ${e.message}';
    }

    return BancoSyncResult(
      uploaded: uploaded,
      failed: failed,
      downloaded: downloaded,
      again: again,
      message: message,
    );
  }

  Future<int> _pull<T>(
    String key,
    Future<List<T>> Function(DateTime? since) fetch,
    Future<void> Function(List<T> rows) apply,
    DateTime? Function(T row) updatedAt,
  ) async {
    final since = await _repo.readState(key);
    final rows = await fetch(since == null ? null : DateTime.parse(since));
    if (rows.isEmpty) return 0;
    await apply(rows);
    final last = rows
        .map(updatedAt)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
    if (last != null) {
      await _repo.writeState(key, last.toUtc().toIso8601String());
    }
    return rows.length;
  }

  /// Sube el adjunto si falta y después la fila. Devuelve un aviso si la
  /// fila se subió pero el adjunto ya no está en el dispositivo.
  Future<String?> _push(LocalMovimiento m) async {
    var path = m.adjuntoPath;
    String? warning;
    final localRef = m.adjuntoLocal;
    if (localRef != null && path == null) {
      final bytes = await _repo.readAdjunto(localRef);
      if (bytes == null) {
        warning =
            'No se encontró el adjunto en este dispositivo. '
            '${describirMovimiento(m)} se subió sin adjunto.';
      } else {
        final ext = adjuntoExtension(m);
        final p = adjuntoMovimientoPath(
          userId: m.userId,
          fecha: m.date,
          movimientoId: m.id,
          extension: ext,
        );
        await _api.uploadAdjunto(
          path: p,
          bytes: bytes,
          contentType: contentTypeForExtension(ext),
        );
        await _repo.setRemoteAdjuntoPath(m.id, p);
        path = p;
      }
    }
    await _api.upsertMovimiento(
      RemoteMovimiento.fromLocal(m, adjuntoPath: path),
    );
    return warning;
  }
}
