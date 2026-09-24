import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../fichadas/remote_fichada.dart';

/// No hay red o el servidor no responde: se reintenta más tarde y la fila
/// sigue *pendiente*.
class RemoteUnavailableException implements Exception {
  const RemoteUnavailableException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// El servidor respondió y rechazó el pedido (regla, permiso, sesión): la
/// fila queda en *error* con este mensaje.
class RemoteRejectedException implements Exception {
  const RemoteRejectedException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Al servidor le falta una columna o tabla que la app espera (por ejemplo,
/// `profiles.agrupamiento` antes de aplicar la migración). Es un rechazo,
/// pero lo local se conserva pendiente y se reintenta en la próxima pasada.
class RemoteSchemaMissingException extends RemoteRejectedException {
  const RemoteSchemaMissingException(super.message);
}

/// Contrato con el backend que usa la cola de sincronización.
abstract interface class FichadasRemote {
  /// Sube (o reemplaza) una foto en el bucket `comprobantes`.
  Future<void> uploadPhoto({required String path, required Uint8List bytes});

  /// Inserta o reemplaza la fila completa (gana el último que sincroniza).
  Future<void> upsertFichada(RemoteFichada fichada);

  /// Fichadas del usuario (incluidas las borradas) con `updated_at >= since`,
  /// ordenadas por `updated_at`. Con [since] `null`, todas.
  Future<List<RemoteFichada>> fetchFichadasChangedSince(DateTime? since);

  Future<List<RemoteFeriado>> fetchFeriados();

  /// Perfil del usuario con sesión, o `null` si todavía no tiene fila.
  Future<RemotePerfil?> fetchPerfil(String userId);

  /// Guarda `profiles.agrupamiento` del usuario (crea la fila si falta).
  Future<void> saveAgrupamiento(String userId, String? agrupamiento);
}

class SupabaseFichadasRemote implements FichadasRemote {
  SupabaseFichadasRemote(this._client);

  final SupabaseClient _client;

  static const bucket = 'comprobantes';
  static const _pageSize = 1000;

  @override
  Future<void> uploadPhoto({required String path, required Uint8List bytes}) =>
      _guard(
        () => _client.storage
            .from(bucket)
            .uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            ),
      );

  @override
  Future<void> upsertFichada(RemoteFichada fichada) => _guard(
    () => _client.from('fichadas').upsert(fichada.toJson(), onConflict: 'id'),
  );

  @override
  Future<List<RemoteFichada>> fetchFichadasChangedSince(DateTime? since) =>
      _guard(() async {
        final result = <RemoteFichada>[];
        var offset = 0;
        while (true) {
          var query = _client.from('fichadas').select();
          if (since != null) {
            query = query.gte('updated_at', since.toUtc().toIso8601String());
          }
          final rows = await query
              .order('updated_at')
              .order('id')
              .range(offset, offset + _pageSize - 1);
          result.addAll(rows.map(RemoteFichada.fromJson));
          if (rows.length < _pageSize) return result;
          offset += _pageSize;
        }
      });

  @override
  Future<List<RemoteFeriado>> fetchFeriados() => _guard(() async {
    final rows = await _client.from('feriados').select('fecha, nombre, tipo');
    return [
      for (final r in rows)
        RemoteFeriado(
          fecha: r['fecha'] as String,
          nombre: r['nombre'] as String,
          tipo: r['tipo'] as String? ?? 'inamovible',
        ),
    ];
  });

  @override
  Future<RemotePerfil?> fetchPerfil(String userId) => _guard(() async {
    final row = await _client
        .from('profiles')
        .select('user_id, agrupamiento')
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;
    return RemotePerfil(
      userId: row['user_id'] as String,
      agrupamiento: row['agrupamiento'] as String?,
    );
  });

  @override
  Future<void> saveAgrupamiento(String userId, String? agrupamiento) => _guard(
    () => _client.from('profiles').upsert({
      'user_id': userId,
      'agrupamiento': agrupamiento,
    }, onConflict: 'user_id'),
  );

  Future<T> _guard<T>(Future<T> Function() call) => guardSupabaseCall(call);
}

/// Traduce los errores de Supabase a los dos casos que entiende el sync.
/// [archivo] nombra lo que se sube a Storage en los mensajes ("la foto",
/// "el adjunto").
Future<T> guardSupabaseCall<T>(
  Future<T> Function() call, {
  String archivo = 'la foto',
}) async {
  try {
    return await call();
  } on PostgrestException catch (e) {
    if (_schemaMissingCodes.contains(e.code)) {
      throw RemoteSchemaMissingException(
        'El servidor todavía no tiene los cambios de esquema (${e.message}).',
      );
    }
    final status = int.tryParse(e.code ?? '');
    if (status != null && status >= 500) {
      throw RemoteUnavailableException('El servidor no responde (${e.code}).');
    }
    throw RemoteRejectedException(_postgrestMessage(e));
  } on StorageException catch (e) {
    final status = int.tryParse(e.statusCode ?? '');
    if (status != null && status >= 400 && status < 500) {
      throw RemoteRejectedException('No se pudo subir $archivo: ${e.message}');
    }
    throw RemoteUnavailableException('No se pudo subir $archivo: ${e.message}');
  } on AuthRetryableFetchException catch (e) {
    throw RemoteUnavailableException(e.message);
  } on AuthException {
    throw const RemoteRejectedException(
      'La sesión venció. Cerrá sesión y volvé a entrar.',
    );
  } catch (e) {
    // Sin red: SocketException, ClientException, timeouts, etc.
    throw RemoteUnavailableException(e.toString());
  }
}

/// Columna, tabla o tipo inexistente (Postgres y caché de PostgREST).
const _schemaMissingCodes = {'42703', '42P01', '42704', 'PGRST204', 'PGRST205'};

String _postgrestMessage(PostgrestException e) {
  switch (e.code) {
    case '23514':
      return 'El servidor rechazó el cambio por una regla de datos '
          '(${e.message}).';
    case '23505':
      return 'Ya existe un registro con esos datos (${e.message}).';
    case '23503':
      return 'Falta un dato relacionado en el servidor (${e.message}).';
    case '42501':
      return 'Sin permiso para guardar este cambio.';
    case 'PGRST301':
    case 'PGRST303':
      return 'La sesión venció. Cerrá sesión y volvé a entrar.';
    default:
      return 'El servidor rechazó el cambio: ${e.message}';
  }
}
