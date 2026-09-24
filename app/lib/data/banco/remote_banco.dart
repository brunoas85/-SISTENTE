import '../local/app_database.dart';

DateTime? _parseTs(Object? value) =>
    value is String ? DateTime.parse(value) : null;

/// Fila de `public.tipos_documento_gde` tal como viaja a/desde Supabase.
class RemoteTipoDocumento {
  const RemoteTipoDocumento({
    required this.id,
    required this.userId,
    required this.codigo,
    this.descripcion,
    this.deletedAt,
    this.updatedAt,
  });

  factory RemoteTipoDocumento.fromLocal(LocalTipoDocumento t) =>
      RemoteTipoDocumento(
        id: t.id,
        userId: t.userId,
        codigo: t.codigo,
        descripcion: t.descripcion,
        deletedAt: t.deletedAt,
      );

  factory RemoteTipoDocumento.fromJson(Map<String, dynamic> json) =>
      RemoteTipoDocumento(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        codigo: json['codigo'] as String,
        descripcion: json['descripcion'] as String?,
        deletedAt: _parseTs(json['deleted_at']),
        updatedAt: _parseTs(json['updated_at']),
      );

  final String id;
  final String userId;
  final String codigo;
  final String? descripcion;
  final DateTime? deletedAt;

  /// Lo pone el trigger del servidor; no se envía.
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'codigo': codigo,
    'descripcion': descripcion,
    'deleted_at': deletedAt?.toUtc().toIso8601String(),
  };

  RemoteTipoDocumento withUpdatedAt(DateTime at) => RemoteTipoDocumento(
    id: id,
    userId: userId,
    codigo: codigo,
    descripcion: descripcion,
    deletedAt: deletedAt,
    updatedAt: at,
  );
}

/// Fila de `public.banco_horas_movimientos` tal como viaja a/desde Supabase.
class RemoteMovimiento {
  const RemoteMovimiento({
    required this.id,
    required this.userId,
    required this.tipo,
    required this.fecha,
    required this.minutos,
    this.alcance,
    this.estado = 'vigente',
    this.tipoDocumentoId,
    this.numeroGde,
    this.adjuntoPath,
    this.observacion,
    this.deletedAt,
    this.updatedAt,
  });

  /// Fila a subir. [adjuntoPath] reemplaza a la del registro local (la del
  /// adjunto recién subido).
  factory RemoteMovimiento.fromLocal(
    LocalMovimiento m, {
    String? adjuntoPath,
  }) => RemoteMovimiento(
    id: m.id,
    userId: m.userId,
    tipo: m.tipo,
    alcance: m.alcance,
    fecha: m.fecha,
    minutos: m.minutos,
    estado: m.estado,
    tipoDocumentoId: m.tipoDocumentoId,
    numeroGde: m.numeroGde,
    adjuntoPath: adjuntoPath ?? m.adjuntoPath,
    observacion: m.observacion,
    deletedAt: m.deletedAt,
  );

  factory RemoteMovimiento.fromJson(Map<String, dynamic> json) =>
      RemoteMovimiento(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        tipo: json['tipo'] as String,
        alcance: json['alcance'] as String?,
        fecha: json['fecha'] as String,
        minutos: json['minutos'] as int,
        estado: json['estado'] as String? ?? 'vigente',
        tipoDocumentoId: json['tipo_documento_id'] as String?,
        numeroGde: json['numero_gde'] as String?,
        adjuntoPath: json['adjunto_path'] as String?,
        observacion: json['observacion'] as String?,
        deletedAt: _parseTs(json['deleted_at']),
        updatedAt: _parseTs(json['updated_at']),
      );

  final String id;
  final String userId;

  /// `acumulacion` | `usufructo`.
  final String tipo;

  /// `total` | `parcial` (solo usufructos).
  final String? alcance;

  /// `yyyy-MM-dd`.
  final String fecha;
  final int minutos;

  /// `vigente` | `perdido`.
  final String estado;
  final String? tipoDocumentoId;
  final String? numeroGde;
  final String? adjuntoPath;
  final String? observacion;
  final DateTime? deletedAt;

  /// Lo pone el trigger del servidor; no se envía.
  final DateTime? updatedAt;

  /// Cuerpo del upsert. `created_at` y `updated_at` los maneja el servidor.
  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'tipo': tipo,
    'alcance': alcance,
    'fecha': fecha,
    'minutos': minutos,
    'estado': estado,
    'tipo_documento_id': tipoDocumentoId,
    'numero_gde': numeroGde,
    'adjunto_path': adjuntoPath,
    'observacion': observacion,
    'deleted_at': deletedAt?.toUtc().toIso8601String(),
  };

  RemoteMovimiento withUpdatedAt(DateTime at) => RemoteMovimiento(
    id: id,
    userId: userId,
    tipo: tipo,
    alcance: alcance,
    fecha: fecha,
    minutos: minutos,
    estado: estado,
    tipoDocumentoId: tipoDocumentoId,
    numeroGde: numeroGde,
    adjuntoPath: adjuntoPath,
    observacion: observacion,
    deletedAt: deletedAt,
    updatedAt: at,
  );
}
