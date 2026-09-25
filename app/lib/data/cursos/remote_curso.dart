import '../local/app_database.dart';

DateTime? _parseTs(Object? value) =>
    value is String ? DateTime.parse(value) : null;

/// Fila de `public.cursos` tal como viaja a/desde Supabase.
class RemoteCurso {
  const RemoteCurso({
    required this.id,
    required this.userId,
    required this.actividad,
    this.codigo,
    this.portal,
    this.fechaInicio,
    this.fechaFin,
    this.creditos,
    this.estado = 'inscripto',
    this.ifGde,
    this.certificadoPath,
    this.observacion,
    this.deletedAt,
    this.updatedAt,
  });

  /// Fila a subir. [certificadoPath] reemplaza a la del registro local (la
  /// del certificado recién subido).
  factory RemoteCurso.fromLocal(LocalCurso c, {String? certificadoPath}) =>
      RemoteCurso(
        id: c.id,
        userId: c.userId,
        actividad: c.actividad,
        codigo: c.codigo,
        portal: c.portal,
        fechaInicio: c.fechaInicio,
        fechaFin: c.fechaFin,
        creditos: c.creditos,
        estado: c.estado,
        ifGde: c.ifGde,
        certificadoPath: certificadoPath ?? c.certificadoPath,
        observacion: c.observacion,
        deletedAt: c.deletedAt,
      );

  factory RemoteCurso.fromJson(Map<String, dynamic> json) => RemoteCurso(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    actividad: json['actividad'] as String,
    codigo: json['codigo'] as String?,
    portal: json['portal'] as String?,
    fechaInicio: json['fecha_inicio'] as String?,
    fechaFin: json['fecha_fin'] as String?,
    creditos: (json['creditos'] as num?)?.toInt(),
    estado: json['estado'] as String? ?? 'inscripto',
    ifGde: json['if_gde'] as String?,
    certificadoPath: json['certificado_path'] as String?,
    observacion: json['observacion'] as String?,
    deletedAt: _parseTs(json['deleted_at']),
    updatedAt: _parseTs(json['updated_at']),
  );

  final String id;
  final String userId;
  final String actividad;
  final String? codigo;
  final String? portal;

  /// `yyyy-MM-dd`.
  final String? fechaInicio;
  final String? fechaFin;
  final int? creditos;

  /// Valor de `curso_estado`.
  final String estado;
  final String? ifGde;
  final String? certificadoPath;
  final String? observacion;
  final DateTime? deletedAt;

  /// Lo pone el trigger del servidor; no se envía.
  final DateTime? updatedAt;

  /// Cuerpo del upsert. `created_at` y `updated_at` los maneja el servidor.
  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'actividad': actividad,
    'codigo': codigo,
    'portal': portal,
    'fecha_inicio': fechaInicio,
    'fecha_fin': fechaFin,
    'creditos': creditos,
    'estado': estado,
    'if_gde': ifGde,
    'certificado_path': certificadoPath,
    'observacion': observacion,
    'deleted_at': deletedAt?.toUtc().toIso8601String(),
  };

  RemoteCurso withUpdatedAt(DateTime at) => RemoteCurso(
    id: id,
    userId: userId,
    actividad: actividad,
    codigo: codigo,
    portal: portal,
    fechaInicio: fechaInicio,
    fechaFin: fechaFin,
    creditos: creditos,
    estado: estado,
    ifGde: ifGde,
    certificadoPath: certificadoPath,
    observacion: observacion,
    deletedAt: deletedAt,
    updatedAt: at,
  );
}
