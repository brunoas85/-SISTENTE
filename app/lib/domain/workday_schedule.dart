import 'agrupamiento.dart';
import 'calendar_date.dart';
import 'models.dart';

/// Resuelve la jornada vigente para una fecha a partir de una lista de
/// vigencias.
///
/// Prioridad: una vigencia de `jornadas` que cubra la fecha; si no hay, la
/// jornada del [Agrupamiento] (8 h administrativo, 7 h guardaparque y
/// guardaparque de apoyo); si no hay agrupamiento, 480 min.
class WorkdayScheduleResolver {
  /// Lanza [ArgumentError] si hay dos vigencias con la misma fecha de inicio
  /// y distinta cantidad de minutos (no se adivina cuál vale).
  ///
  /// [defaultMinutes], si se indica, reemplaza al default del
  /// [agrupamiento].
  WorkdayScheduleResolver(
    Iterable<WorkdaySchedule> schedules, {
    Agrupamiento? agrupamiento,
    int? defaultMinutes,
  }) : defaultMinutes =
           defaultMinutes ?? workdayMinutesForAgrupamiento(agrupamiento),
       _schedules = _sortAndValidate(schedules);

  /// Jornada cuando no hay vigencia para la fecha.
  final int defaultMinutes;
  final List<WorkdaySchedule> _schedules;

  static List<WorkdaySchedule> _sortAndValidate(
    Iterable<WorkdaySchedule> schedules,
  ) {
    final byDate = <CalendarDate, WorkdaySchedule>{};
    for (final s in schedules) {
      final existing = byDate[s.validFrom];
      if (existing != null && existing.minutes != s.minutes) {
        throw ArgumentError(
          'Hay dos jornadas distintas con vigencia desde ${s.validFrom}',
        );
      }
      byDate[s.validFrom] = s;
    }
    return byDate.values.toList()
      ..sort((a, b) => a.validFrom.compareTo(b.validFrom));
  }

  /// Minutos de jornada vigentes en [date]: la última vigencia con
  /// `validFrom <= date`, o [defaultMinutes] si no hay ninguna.
  int minutesFor(CalendarDate date) {
    var result = defaultMinutes;
    for (final s in _schedules) {
      if (s.validFrom.isAfter(date)) break;
      result = s.minutes;
    }
    return result;
  }
}

/// Atajo para obtener la jornada vigente en [date].
int workdayMinutesFor(
  CalendarDate date,
  Iterable<WorkdaySchedule> schedules, {
  Agrupamiento? agrupamiento,
  int? defaultMinutes,
}) => WorkdayScheduleResolver(
  schedules,
  agrupamiento: agrupamiento,
  defaultMinutes: defaultMinutes,
).minutesFor(date);
