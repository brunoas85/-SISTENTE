import '../attachments/attachment.dart';
import '../cursos/curso.dart';
import '../cursos/cursos_repository.dart';
import '../cursos/remote_curso.dart';
import '../local/app_database.dart';
import 'banco_sync.dart' show SectionSyncResult;
import 'cursos_remote.dart';
import 'fichadas_remote.dart';

/// Sincroniza los cursos, fila por fila.
///
/// 1. Sube los cursos pendientes: primero el certificado (si falta subirlo)
///    a `certificados/{user_id}/{yyyy}/{id}_certificado.{ext}` y después el
///    upsert de la fila.
/// 2. Baja los cambios con cursor por `updated_at`, sin pisar lo que falta
///    subir.
///
/// Sin red lanza [RemoteUnavailableException] y lo que falta queda
/// pendiente. Un rechazo deja esa fila en error y sigue con las demás.
class CursosSync {
  CursosSync({
    required CursosRepository repository,
    required CursosRemote remote,
    DateTime Function()? clock,
  }) : _repo = repository,
       _api = remote,
       _clock = clock ?? DateTime.now;

  final CursosRepository _repo;
  final CursosRemote _api;
  final DateTime Function() _clock;

  static String pulledAtKey(String userId) => 'cursos_pulled_at:$userId';

  Future<SectionSyncResult> run(String userId) async {
    var uploaded = 0;
    var failed = 0;
    var downloaded = 0;
    var again = false;
    String? message;

    for (final c in await _repo.unsyncedCursos(userId)) {
      try {
        final warning = await _push(c);
        if (warning != null) {
          await _repo.markCursoError(c.id, c.revision, warning);
          failed++;
          message = warning;
        } else {
          uploaded++;
          if (!await _repo.markCursoSynced(c.id, c.revision)) again = true;
        }
      } on RemoteRejectedException catch (e) {
        final texto = 'Curso ${describirCurso(c)}: ${e.message}';
        await _repo.markCursoError(c.id, c.revision, texto);
        failed++;
        message = texto;
      }
    }

    try {
      final key = pulledAtKey(userId);
      final since = await _repo.readState(key);
      final rows = await _api.fetchCursosChangedSince(
        since == null ? null : DateTime.parse(since),
      );
      if (rows.isNotEmpty) {
        await _repo.applyRemoteCursos(rows);
        downloaded = rows.length;
        final last = rows
            .map((r) => r.updatedAt)
            .whereType<DateTime>()
            .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
        if (last != null) {
          await _repo.writeState(key, last.toUtc().toIso8601String());
        }
      }
    } on RemoteRejectedException catch (e) {
      message = 'No se pudieron bajar los cursos: ${e.message}';
    }

    return SectionSyncResult(
      uploaded: uploaded,
      failed: failed,
      downloaded: downloaded,
      again: again,
      message: message,
    );
  }

  /// Sube el certificado si falta y después la fila. Devuelve un aviso si
  /// la fila se subió pero el certificado ya no está en el dispositivo.
  Future<String?> _push(LocalCurso c) async {
    var path = c.certificadoPath;
    String? warning;
    final localRef = c.certificadoLocal;
    // Un curso borrado no necesita subir el certificado.
    if (localRef != null && path == null && !c.isDeleted) {
      final bytes = await _repo.readCertificado(localRef);
      if (bytes == null) {
        warning =
            'No se encontró el certificado en este dispositivo. El curso '
            '${describirCurso(c)} se subió sin certificado.';
      } else if (bytes.length > attachmentMaxBytes) {
        // No debería pasar (se controla al adjuntarlo), pero el bucket lo
        // rechazaría igual.
        warning =
            'El certificado de ${describirCurso(c)} supera los 10 MB: el '
            'curso se subió sin certificado.';
      } else {
        final ext = certificadoExtension(c);
        final p = certificadoCursoPath(
          userId: c.userId,
          year: c.toCourse().year ?? _clock().year,
          cursoId: c.id,
          extension: ext,
        );
        await _api.uploadCertificado(
          path: p,
          bytes: bytes,
          contentType: contentTypeForExtension(ext),
        );
        await _repo.setRemoteCertificadoPath(c.id, p);
        path = p;
      }
    }
    await _api.upsertCurso(RemoteCurso.fromLocal(c, certificadoPath: path));
    return warning;
  }
}
