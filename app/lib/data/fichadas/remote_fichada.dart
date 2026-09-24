import '../local/app_database.dart';

/// Fila de `public.fichadas` tal como viaja a/desde Supabase.
class RemoteFichada {
  const RemoteFichada({
    required this.id,
    required this.userId,
    required this.fecha,
    required this.ingresoMin,
    this.egresoMin,
    this.ingresoOriginalMin,
    this.egresoOriginalMin,
    this.editado = false,
    this.fotoIngresoPath,
    this.fotoEgresoPath,
    this.observacion,
    this.deletedAt,
    this.updatedAt,
  });

  factory RemoteFichada.fromLocal(LocalFichada f) => RemoteFichada(
    id: f.id,
    userId: f.userId,
    fecha: f.fecha,
    ingresoMin: f.ingresoMin,
    egresoMin: f.egresoMin,
    ingresoOriginalMin: f.ingresoOriginalMin,
    egresoOriginalMin: f.egresoOriginalMin,
    editado: f.editado,
    fotoIngresoPath: f.fotoIngresoPath,
    fotoEgresoPath: f.fotoEgresoPath,
    observacion: f.observacion,
    deletedAt: f.deletedAt,
  );

  factory RemoteFichada.fromJson(Map<String, dynamic> json) => RemoteFichada(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    fecha: json['fecha'] as String,
    ingresoMin: json['ingreso_min'] as int,
    egresoMin: json['egreso_min'] as int?,
    ingresoOriginalMin: json['ingreso_original_min'] as int?,
    egresoOriginalMin: json['egreso_original_min'] as int?,
    editado: json['editado'] as bool? ?? false,
    fotoIngresoPath: json['foto_ingreso_path'] as String?,
    fotoEgresoPath: json['foto_egreso_path'] as String?,
    observacion: json['observacion'] as String?,
    deletedAt: _parseTs(json['deleted_at']),
    updatedAt: _parseTs(json['updated_at']),
  );

  final String id;
  final String userId;

  /// `yyyy-MM-dd`.
  final String fecha;
  final int ingresoMin;
  final int? egresoMin;
  final int? ingresoOriginalMin;
  final int? egresoOriginalMin;
  final bool editado;
  final String? fotoIngresoPath;
  final String? fotoEgresoPath;
  final String? observacion;
  final DateTime? deletedAt;

  /// Lo pone el trigger del servidor; no se envía.
  final DateTime? updatedAt;

  /// Cuerpo del upsert. `created_at` y `updated_at` los maneja el servidor.
  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'fecha': fecha,
    'ingreso_min': ingresoMin,
    'egreso_min': egresoMin,
    'ingreso_original_min': ingresoOriginalMin,
    'egreso_original_min': egresoOriginalMin,
    'editado': editado,
    'foto_ingreso_path': fotoIngresoPath,
    'foto_egreso_path': fotoEgresoPath,
    'observacion': observacion,
    'deleted_at': deletedAt?.toUtc().toIso8601String(),
  };

  static DateTime? _parseTs(Object? value) =>
      value is String ? DateTime.parse(value) : null;
}

/// Fila de `public.feriados`.
class RemoteFeriado {
  const RemoteFeriado({required this.fecha, required this.nombre});

  /// `yyyy-MM-dd`.
  final String fecha;
  final String nombre;
}
