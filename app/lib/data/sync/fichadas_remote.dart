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
    final rows = await _client.from('feriados').select('fecha, nombre');
    return [
      for (final r in rows)
        RemoteFeriado(
          fecha: r['fecha'] as String,
          nombre: r['nombre'] as String,
        ),
    ];
  });

  /// Traduce los errores de Supabase a los dos casos que entiende el sync.
  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PostgrestException catch (e) {
      final status = int.tryParse(e.code ?? '');
      if (status != null && status >= 500) {
        throw RemoteUnavailableException(
          'El servidor no responde (${e.code}).',
        );
      }
      throw RemoteRejectedException(_postgrestMessage(e));
    } on StorageException catch (e) {
      final status = int.tryParse(e.statusCode ?? '');
      if (status != null && status >= 400 && status < 500) {
        throw RemoteRejectedException('No se pudo subir la foto: ${e.message}');
      }
      throw RemoteUnavailableException(
        'No se pudo subir la foto: ${e.message}',
      );
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

  static String _postgrestMessage(PostgrestException e) {
    switch (e.code) {
      case '23514':
        return 'El servidor rechazó la fichada por una regla de datos '
            '(${e.message}).';
      case '42501':
        return 'Sin permiso para guardar esta fichada.';
      case 'PGRST301':
      case 'PGRST303':
        return 'La sesión venció. Cerrá sesión y volvé a entrar.';
      default:
        return 'El servidor rechazó la fichada: ${e.message}';
    }
  }
}
