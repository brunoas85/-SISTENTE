import 'package:asistente/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

// Cursos ficticios.
Course curso({
  String id = 'c',
  String activity = 'Curso ficticio',
  CourseStatus status = CourseStatus.approved,
  String? code,
  String? portal,
  CalendarDate? start,
  CalendarDate? end,
  int? credits,
  String? ifNumber,
  bool certificate = false,
}) => Course(
  id: id,
  activity: activity,
  status: status,
  code: code,
  portal: portal,
  startDate: start,
  endDate: end,
  credits: credits,
  gdeIfNumber: ifNumber,
  hasCertificate: certificate,
);

void main() {
  group('año de un curso (decisión de Bruno, 2026-09-25)', () {
    test('es el de la fecha de fin', () {
      final c = curso(
        start: CalendarDate(2025, 12, 1),
        end: CalendarDate(2026, 2, 15),
      );
      expect(c.year, 2026);
    });

    test('sin fin, es el de la fecha de inicio', () {
      expect(curso(start: CalendarDate(2025, 11, 3)).year, 2025);
    });

    test('sin fechas no tiene año', () {
      expect(curso().year, isNull);
    });
  });

  group('approvedCredits', () {
    final cursos = [
      // Empieza en 2025 y termina en 2026: suma a 2026.
      curso(
        id: 'a',
        start: CalendarDate(2025, 12, 1),
        end: CalendarDate(2026, 2, 15),
        credits: 3,
      ),
      // Solo inicio en 2025: suma a 2025.
      curso(id: 'b', start: CalendarDate(2025, 5, 1), credits: 2),
      // Sin fechas: solo en "todos los años".
      curso(id: 'c', credits: 4),
      // No aprobados: no suman nunca.
      curso(
        id: 'd',
        status: CourseStatus.inProgress,
        end: CalendarDate(2026, 3, 1),
        credits: 10,
      ),
      curso(
        id: 'e',
        status: CourseStatus.abandoned,
        end: CalendarDate(2026, 3, 1),
        credits: 10,
      ),
      curso(
        id: 'f',
        status: CourseStatus.notAccepted,
        end: CalendarDate(2026, 3, 1),
        credits: 10,
      ),
      curso(
        id: 'g',
        status: CourseStatus.enrolled,
        end: CalendarDate(2026, 3, 1),
        credits: 10,
      ),
      // Aprobado sin créditos cargados: cuenta 0.
      curso(id: 'h', end: CalendarDate(2026, 6, 30)),
    ];

    test('por año de fin', () {
      expect(approvedCredits(cursos, year: 2026), 3);
    });

    test('por año de inicio si no tiene fin', () {
      expect(approvedCredits(cursos, year: 2025), 2);
    });

    test('todos los años incluye los que no tienen fechas', () {
      expect(approvedCredits(cursos), 9);
    });

    test('un año sin cursos da 0', () {
      expect(approvedCredits(cursos, year: 2024), 0);
      expect(approvedCredits(const []), 0);
    });

    test('solo suma los aprobados', () {
      final noAprobados = cursos.where(
        (c) => c.status != CourseStatus.approved,
      );
      expect(approvedCredits(noAprobados), 0);
    });

    test('los créditos son enteros', () {
      expect(approvedCredits(cursos), isA<int>());
    });
  });

  group('courseYears', () {
    test('años con cursos, del más nuevo al más viejo, más el actual', () {
      final years = courseYears([
        curso(end: CalendarDate(2024, 1, 1)),
        curso(start: CalendarDate(2025, 1, 1)),
        curso(end: CalendarDate(2024, 6, 1)),
        curso(),
      ], alwaysInclude: 2026);
      expect(years, [2026, 2025, 2024]);
    });

    test('sin cursos queda solo el año actual', () {
      expect(courseYears(const [], alwaysInclude: 2026), [2026]);
    });
  });

  group('CourseFilter', () {
    final cursos = [
      curso(
        id: 'gestion',
        activity: 'Gestión de áreas protegidas',
        code: 'IN-A3-00001',
        portal: 'INAP',
        end: CalendarDate(2026, 4, 1),
      ),
      curso(
        id: 'prevencion',
        activity: 'Prevención de riesgos',
        status: CourseStatus.inProgress,
        portal: 'srt',
        start: CalendarDate(2025, 8, 1),
      ),
      curso(id: 'sin-fechas', activity: 'Primeros auxilios'),
    ];
    List<String> ids(CourseFilter f) =>
        f.apply(cursos, (c) => c).map((c) => c.id).toList();

    test('sin filtros pasan todos', () {
      expect(ids(const CourseFilter()), [
        'gestion',
        'prevencion',
        'sin-fechas',
      ]);
    });

    test('por estado', () {
      expect(ids(const CourseFilter(status: CourseStatus.inProgress)), [
        'prevencion',
      ]);
    });

    test('por año usa el mismo criterio que el total (fin, o inicio)', () {
      expect(ids(const CourseFilter(year: 2026)), ['gestion']);
      expect(ids(const CourseFilter(year: 2025)), ['prevencion']);
      // Un curso sin fechas no aparece en ningún año.
      expect(ids(const CourseFilter(year: 2024)), isEmpty);
    });

    test('por portal, sin distinguir mayúsculas', () {
      expect(ids(const CourseFilter(portal: 'SRT')), ['prevencion']);
      expect(ids(const CourseFilter(portal: 'inap')), ['gestion']);
    });

    test('búsqueda en actividad y código, sin mayúsculas ni acentos', () {
      expect(ids(const CourseFilter(query: 'GESTION')), ['gestion']);
      expect(ids(const CourseFilter(query: 'prevención')), ['prevencion']);
      expect(ids(const CourseFilter(query: 'a3-00001')), ['gestion']);
      expect(ids(const CourseFilter(query: '   ')), hasLength(3));
      expect(ids(const CourseFilter(query: 'no existe')), isEmpty);
    });

    test('los filtros se combinan', () {
      expect(
        ids(const CourseFilter(status: CourseStatus.approved, query: 'riesgo')),
        isEmpty,
      );
      expect(
        ids(const CourseFilter(year: 2026, portal: 'INAP', query: 'áreas')),
        ['gestion'],
      );
    });
  });

  group('portales', () {
    test('las sugerencias suman los usados y los de siempre, sin repetir', () {
      expect(
        portalSuggestions(['inap', 'Capacitar', null, '  ', 'Capacitar']),
        ['Capacitar', 'inap', 'SEDRONAR', 'SRT'],
      );
    });

    test('para filtrar solo los usados', () {
      expect(
        usedCoursePortals([
          curso(portal: 'SRT'),
          curso(portal: 'inap'),
          curso(portal: 'INAP'),
          curso(portal: ' '),
          curso(),
        ]),
        ['inap', 'SRT'],
      );
    });
  });

  group('validateCourse', () {
    test('la actividad es obligatoria', () {
      expect(
        validateCourse(activity: '  '),
        'Cargá el nombre de la actividad.',
      );
    });

    test('créditos negativos no', () {
      expect(
        validateCourse(activity: 'Curso', credits: -1),
        'Los créditos no pueden ser negativos.',
      );
      expect(validateCourse(activity: 'Curso', credits: 0), isNull);
    });

    test('el fin no puede ser anterior al inicio', () {
      expect(
        validateCourse(
          activity: 'Curso',
          startDate: CalendarDate(2026, 5, 2),
          endDate: CalendarDate(2026, 5, 1),
        ),
        'La fecha de fin no puede ser anterior a la de inicio.',
      );
      expect(
        validateCourse(
          activity: 'Curso',
          startDate: CalendarDate(2026, 5, 1),
          endDate: CalendarDate(2026, 5, 1),
        ),
        isNull,
      );
    });
  });

  group('validateCourse: un aprobado necesita fecha (Bruno, 2026-09-25)', () {
    test('aprobado sin fechas: se rechaza', () {
      expect(
        validateCourse(activity: 'Curso', status: CourseStatus.approved),
        'Para marcarlo aprobado, cargá la fecha de fin.',
      );
    });

    test('aprobado con solo inicio o solo fin: se acepta', () {
      expect(
        validateCourse(
          activity: 'Curso',
          status: CourseStatus.approved,
          startDate: CalendarDate(2026, 3, 2),
        ),
        isNull,
      );
      expect(
        validateCourse(
          activity: 'Curso',
          status: CourseStatus.approved,
          endDate: CalendarDate(2026, 4, 30),
        ),
        isNull,
      );
    });

    test('los otros estados no necesitan fechas', () {
      for (final s in CourseStatus.values) {
        if (s == CourseStatus.approved) continue;
        expect(
          validateCourse(activity: 'Curso', status: s),
          isNull,
          reason: s.name,
        );
      }
    });
  });

  group('courseWarnings', () {
    test('aprobado sin certificado ni IF: los dos avisos', () {
      expect(courseWarnings(curso()), [
        CourseWarning.approvedWithoutCertificate,
        CourseWarning.approvedWithoutIf,
      ]);
    });

    test('un IF en blanco cuenta como que falta', () {
      expect(courseWarnings(curso(ifNumber: '  ', certificate: true)), [
        CourseWarning.approvedWithoutIf,
      ]);
    });

    test('aprobado completo: sin avisos', () {
      expect(
        courseWarnings(
          curso(ifNumber: 'IF-2026-00000001-APN-FICTICIO', certificate: true),
        ),
        isEmpty,
      );
    });

    test('los que no están aprobados no tienen avisos', () {
      for (final s in CourseStatus.values) {
        if (s == CourseStatus.approved) continue;
        expect(courseWarnings(curso(status: s)), isEmpty, reason: s.name);
      }
    });
  });

  test('CourseStatus: valores de la base y default del servidor', () {
    for (final s in CourseStatus.values) {
      expect(CourseStatus.fromDbValue(s.dbValue), s);
    }
    expect(CourseStatus.fromDbValue(null), CourseStatus.enrolled);
    expect(CourseStatus.fromDbValue('otro'), CourseStatus.enrolled);
  });
}
