import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../banco/remote_banco.dart';
import 'fichadas_remote.dart';

/// Contrato con el backend para el banco de horas: tablas
/// `banco_horas_movimientos` y `tipos_documento_gde`, y el bucket privado
/// `comprobantes` para los adjuntos.
abstract interface class BancoRemote {
  /// Sube (o reemplaza) un adjunto en el bucket `comprobantes`.
  Future<void> uploadAdjunto({
    required String path,
    required Uint8List bytes,
    required String contentType,
  });

  /// Inserta o reemplaza la fila completa (gana el último que sincroniza).
  Future<void> upsertTipoDocumento(RemoteTipoDocumento tipo);

  Future<void> upsertMovimiento(RemoteMovimiento movimiento);

  /// Filas del usuario (incluidas las borradas) con `updated_at >= since`,
  /// ordenadas por `updated_at`. Con [since] `null`, todas.
  Future<List<RemoteTipoDocumento>> fetchTiposChangedSince(DateTime? since);

  Future<List<RemoteMovimiento>> fetchMovimientosChangedSince(DateTime? since);
}

class SupabaseBancoRemote implements BancoRemote {
  SupabaseBancoRemote(this._client);

  final SupabaseClient _client;

  static const bucket = 'comprobantes';
  static const _pageSize = 1000;

  @override
  Future<void> uploadAdjunto({
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
    archivo: 'el adjunto',
  );

  @override
  Future<void> upsertTipoDocumento(RemoteTipoDocumento tipo) =>
      guardSupabaseCall(
        () => _client
            .from('tipos_documento_gde')
            .upsert(tipo.toJson(), onConflict: 'id'),
      );

  @override
  Future<void> upsertMovimiento(RemoteMovimiento movimiento) =>
      guardSupabaseCall(
        () => _client
            .from('banco_horas_movimientos')
            .upsert(movimiento.toJson(), onConflict: 'id'),
      );

  @override
  Future<List<RemoteTipoDocumento>> fetchTiposChangedSince(DateTime? since) =>
      _fetch('tipos_documento_gde', since, RemoteTipoDocumento.fromJson);

  @override
  Future<List<RemoteMovimiento>> fetchMovimientosChangedSince(
    DateTime? since,
  ) => _fetch('banco_horas_movimientos', since, RemoteMovimiento.fromJson);

  Future<List<T>> _fetch<T>(
    String table,
    DateTime? since,
    T Function(Map<String, dynamic>) fromJson,
  ) => guardSupabaseCall(() async {
    final result = <T>[];
    var offset = 0;
    while (true) {
      var query = _client.from(table).select();
      if (since != null) {
        query = query.gte('updated_at', since.toUtc().toIso8601String());
      }
      final rows = await query
          .order('updated_at')
          .order('id')
          .range(offset, offset + _pageSize - 1);
      result.addAll(rows.map(fromJson));
      if (rows.length < _pageSize) return result;
      offset += _pageSize;
    }
  });
}
