import '../../core/format/formatters.dart';
import '../../domain/domain.dart';
import '../attachments/attachment.dart';
import '../local/app_database.dart';

extension LocalCursoX on LocalCurso {
  CourseStatus get status => CourseStatus.fromDbValue(estado);
  CalendarDate? get inicio =>
      fechaInicio == null ? null : parseIsoDate(fechaInicio!);
  CalendarDate? get fin => fechaFin == null ? null : parseIsoDate(fechaFin!);
  bool get isDeleted => deletedAt != null;

  /// Tiene certificado (en el dispositivo o ya subido).
  bool get tieneCertificado =>
      certificadoLocal != null || certificadoPath != null;

  /// El certificado es un PDF.
  bool get certificadoEsPdf =>
      extensionOf(certificadoLocal ?? certificadoPath) == 'pdf';

  /// Curso del dominio (créditos, filtros y avisos).
  Course toCourse() => Course(
    id: id,
    activity: actividad,
    status: status,
    code: codigo,
    portal: portal,
    startDate: inicio,
    endDate: fin,
    credits: creditos,
    gdeIfNumber: ifGde,
    hasCertificate: tieneCertificado,
  );

  /// Borrador para editar este curso, con los cambios que se indiquen (por
  /// ejemplo, el estado desde la tabla).
  CursoDraft toDraft({CourseStatus? estado}) => CursoDraft(
    id: id,
    actividad: actividad,
    codigo: codigo,
    portal: portal,
    fechaInicio: inicio,
    fechaFin: fin,
    creditos: creditos,
    estado: estado ?? status,
    ifGde: ifGde,
    observacion: observacion,
  );
}

/// Datos de un curso a guardar (alta o edición).
class CursoDraft {
  const CursoDraft({
    this.id,
    required this.actividad,
    this.codigo,
    this.portal,
    this.fechaInicio,
    this.fechaFin,
    this.creditos,
    this.estado = CourseStatus.enrolled,
    this.ifGde,
    this.observacion,
  });

  /// `null` = curso nuevo.
  final String? id;
  final String actividad;
  final String? codigo;
  final String? portal;
  final CalendarDate? fechaInicio;
  final CalendarDate? fechaFin;
  final int? creditos;
  final CourseStatus estado;
  final String? ifGde;
  final String? observacion;

  /// Motivo por el que no se puede guardar, o `null`.
  String? validar() => validateCourse(
    activity: actividad,
    startDate: fechaInicio,
    endDate: fechaFin,
    credits: creditos,
    status: estado,
  );
}

/// Referencia útil en los mensajes: el nombre de la actividad.
String describirCurso(LocalCurso c) => '"${c.actividad}"';

/// Extensión del certificado guardado en el dispositivo (para subirlo).
String certificadoExtension(LocalCurso c) =>
    extensionOf(c.certificadoLocal) ?? 'jpg';

/// Ruta del certificado en el bucket `certificados`:
/// `{user_id}/{yyyy}/{id}_certificado.{ext}`. [year] es el del curso (fin,
/// o inicio); sin fechas, el de la subida.
String certificadoCursoPath({
  required String userId,
  required int year,
  required String cursoId,
  required String extension,
}) =>
    '$userId/${year.toString().padLeft(4, '0')}/'
    '${cursoId}_certificado.$extension';
