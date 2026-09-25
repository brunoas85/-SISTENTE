import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../cursos/remote_curso.dart';
import 'fichadas_remote.dart';

/// Contrato con el backend para los cursos: tabla `public.cursos` y el
/// bucket privado `certificados`.
abstract interface class CursosRemote {
  /// Sube (o reemplaza) un certificado en el bucket `certificados`.
  Future<void> uploadCertificado({
    required String path,
    required Uint8List bytes,
    required String contentType,
  });

  /// URL firmada de corta duración ([expiresIn], 60 s por defecto) para ver
  /// un certificado del bucket privado. Nunca una URL pública.
  Future<String> signedCertificadoUrl(
    String path, {
    Duration expiresIn = const Duration(seconds: 60),
  });

  /// Inserta o reemplaza la fila completa (gana el último que sincroniza).
  Future<void> upsertCurso(RemoteCurso curso);

  /// Cursos del usuario (incluidos los borrados) con `updated_at >= since`,
  /// ordenados por `updated_at`. Con [since] `null`, todos.
  Future<List<RemoteCurso>> fetchCursosChangedSince(DateTime? since);
}

class SupabaseCursosRemote implements CursosRemote {
  SupabaseCursosRemote(this._client);

  final SupabaseClient _client;

  static const bucket = 'certificados';
  static const _pageSize = 1000;

  @override
  Future<void> uploadCertificado({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) => guardSupabaseCall(
    () => _client.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        ),
    archivo: 'el certificado',
  );

  @override
  Future<String> signedCertificadoUrl(
    String path, {
    Duration expiresIn = const Duration(seconds: 60),
  }) => guardSupabaseCall(
    () =>
        _client.storage.from(bucket).createSignedUrl(path, expiresIn.inSeconds),
    archivo: 'el certificado',
  );

  @override
  Future<void> upsertCurso(RemoteCurso curso) => guardSupabaseCall(
    () => _client.from('cursos').upsert(curso.toJson(), onConflict: 'id'),
  );

  @override
  Future<List<RemoteCurso>> fetchCursosChangedSince(DateTime? since) =>
      guardSupabaseCall(() async {
        final result = <RemoteCurso>[];
        var offset = 0;
        while (true) {
          var query = _client.from('cursos').select();
          if (since != null) {
            query = query.gte('updated_at', since.toUtc().toIso8601String());
          }
          final rows = await query
              .order('updated_at')
              .order('id')
              .range(offset, offset + _pageSize - 1);
          result.addAll(rows.map(RemoteCurso.fromJson));
          if (rows.length < _pageSize) return result;
          offset += _pageSize;
        }
      });
}
