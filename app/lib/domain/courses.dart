// Cursos de capacitación: créditos, filtros y avisos (Dart puro).
//
// Criterio del año de un curso (decisión de Bruno, 2026-09-25): un curso se
// asigna al año de su `fecha_fin`; si no tiene, al de su `fecha_inicio`;
// sin ninguna de las dos no tiene año (solo aparece en "Todos los años" y
// no suma a ningún año). Los créditos cumplidos de un año son la suma de
// los créditos de los cursos `aprobado` de ese año. El mismo criterio se
// usa para filtrar la lista por año, así el total de arriba y la lista
// filtrada coinciden.
import 'calendar_date.dart';

/// Estado de un curso (enum `curso_estado` de Postgres).
enum CourseStatus {
  enrolled('inscripto', 'Inscripto'),
  inProgress('en_curso', 'En curso'),
  approved('aprobado', 'Aprobado'),
  notAccepted('no_aceptado', 'No aceptado'),
  abandoned('abandonado', 'Abandonado');

  const CourseStatus(this.dbValue, this.label);

  /// Valor en la base.
  final String dbValue;

  /// Texto para la UI.
  final String label;

  /// Estado con ese valor, o [enrolled] (el default del servidor) si no se
  /// conoce.
  static CourseStatus fromDbValue(String? value) {
    for (final s in values) {
      if (s.dbValue == value) return s;
    }
    return enrolled;
  }
}

/// Portales que se sugieren siempre, aunque todavía no haya cursos.
const defaultCoursePortals = ['INAP', 'SEDRONAR', 'SRT'];

/// Curso para los cálculos. Los créditos son enteros; `null` = sin cargar
/// (cuenta como 0).
class Course {
  const Course({
    required this.id,
    required this.activity,
    required this.status,
    this.code,
    this.portal,
    this.startDate,
    this.endDate,
    this.credits,
    this.gdeIfNumber,
    this.hasCertificate = false,
  });

  final String id;
  final String activity;
  final CourseStatus status;
  final String? code;
  final String? portal;
  final CalendarDate? startDate;
  final CalendarDate? endDate;
  final int? credits;
  final String? gdeIfNumber;
  final bool hasCertificate;

  /// Año del curso: el de [endDate]; si no hay, el de [startDate]; si no,
  /// `null` (ver el criterio al principio del archivo).
  int? get year => endDate?.year ?? startDate?.year;
}

/// Créditos cumplidos: suma de los créditos de los cursos aprobados. Con
/// [year], solo los de ese año (ver [Course.year]).
int approvedCredits(Iterable<Course> courses, {int? year}) {
  var total = 0;
  for (final c in courses) {
    if (c.status != CourseStatus.approved) continue;
    if (year != null && c.year != year) continue;
    total += c.credits ?? 0;
  }
  return total;
}

/// Años con algún curso, del más nuevo al más viejo, más [alwaysInclude]
/// (por ejemplo, el año actual).
List<int> courseYears(Iterable<Course> courses, {int? alwaysInclude}) {
  final years = <int>{?alwaysInclude};
  for (final c in courses) {
    final y = c.year;
    if (y != null) years.add(y);
  }
  return years.toList()..sort((a, b) => b.compareTo(a));
}

/// Pasa a minúsculas y saca los acentos, para buscar sin distinguir
/// "Gestión" de "gestion".
String foldForSearch(String s) {
  const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const to = 'aaaaaeeeeiiiiooooouuuunc';
  final lower = s.toLowerCase();
  final out = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    final i = from.indexOf(ch);
    out.write(i < 0 ? ch : to[i]);
  }
  return out.toString();
}

/// Filtros de la lista de cursos. `null` (o texto vacío) = sin filtrar.
class CourseFilter {
  const CourseFilter({this.status, this.year, this.portal, this.query = ''});

  final CourseStatus? status;
  final int? year;

  /// Se compara sin distinguir mayúsculas.
  final String? portal;

  /// Busca en la actividad y el código (sin distinguir mayúsculas ni
  /// acentos).
  final String query;

  bool matches(Course c) {
    if (status != null && c.status != status) return false;
    if (year != null && c.year != year) return false;
    final p = portal;
    if (p != null && (c.portal ?? '').toUpperCase() != p.toUpperCase()) {
      return false;
    }
    final q = foldForSearch(query.trim());
    if (q.isEmpty) return true;
    return foldForSearch(c.activity).contains(q) ||
        foldForSearch(c.code ?? '').contains(q);
  }

  List<T> apply<T>(Iterable<T> items, Course Function(T) toCourse) => [
    for (final i in items)
      if (matches(toCourse(i))) i,
  ];
}

/// Sugerencias para el campo portal: los ya usados más [defaultCoursePortals],
/// sin repetir (sin distinguir mayúsculas; gana cómo se escribió primero en
/// los usados) y en orden alfabético.
List<String> portalSuggestions(Iterable<String?> used) {
  final byKey = <String, String>{};
  for (final p in [...used, ...defaultCoursePortals]) {
    final t = p?.trim();
    if (t == null || t.isEmpty) continue;
    byKey.putIfAbsent(t.toUpperCase(), () => t);
  }
  return byKey.values.toList()
    ..sort((a, b) => a.toUpperCase().compareTo(b.toUpperCase()));
}

/// Portales usados en [courses] (para filtrar la lista), sin repetir (sin
/// distinguir mayúsculas; gana cómo se escribió primero) y en orden
/// alfabético. A diferencia de [portalSuggestions], no agrega los portales
/// por defecto: filtrar por un portal sin cursos no sirve.
List<String> usedCoursePortals(Iterable<Course> courses) {
  final byKey = <String, String>{};
  for (final c in courses) {
    final t = c.portal?.trim();
    if (t == null || t.isEmpty) continue;
    byKey.putIfAbsent(t.toUpperCase(), () => t);
  }
  return byKey.values.toList()
    ..sort((a, b) => a.toUpperCase().compareTo(b.toUpperCase()));
}

/// Motivo por el que un curso no se puede guardar, o `null`. Es lo mismo
/// que controla el servidor (actividad no vacía, créditos ≥ 0, fin ≥
/// inicio y, si está aprobado, al menos una fecha).
///
/// Un curso aprobado tiene que tener fecha (decisión de Bruno, 2026-09-25):
/// sin fecha no tendría año y sus créditos no sumarían en ninguno.
String? validateCourse({
  required String activity,
  CalendarDate? startDate,
  CalendarDate? endDate,
  int? credits,
  CourseStatus? status,
}) {
  if (activity.trim().isEmpty) return 'Cargá el nombre de la actividad.';
  if (status == CourseStatus.approved && startDate == null && endDate == null) {
    return 'Para marcarlo aprobado, cargá la fecha de fin.';
  }
  if (credits != null && credits < 0) {
    return 'Los créditos no pueden ser negativos.';
  }
  if (startDate != null && endDate != null && endDate.isBefore(startDate)) {
    return 'La fecha de fin no puede ser anterior a la de inicio.';
  }
  return null;
}

/// Avisos suaves de un curso: no impiden guardar.
enum CourseWarning {
  approvedWithoutCertificate('Aprobado sin certificado'),
  approvedWithoutIf('Aprobado sin IF');

  const CourseWarning(this.label);
  final String label;
}

/// Avisos de [c]: un curso aprobado debería tener certificado y número de
/// IF de GDE.
List<CourseWarning> courseWarnings(Course c) => [
  if (c.status == CourseStatus.approved && !c.hasCertificate)
    CourseWarning.approvedWithoutCertificate,
  if (c.status == CourseStatus.approved &&
      (c.gdeIfNumber == null || c.gdeIfNumber!.trim().isEmpty))
    CourseWarning.approvedWithoutIf,
];
