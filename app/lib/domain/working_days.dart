import 'calendar_date.dart';
import 'models.dart';

/// Por qué un día no es laborable: fin de semana o feriado (incluidos los
/// no laborables turísticos). No se puede fichar esos días.
class NonWorkingDay {
  const NonWorkingDay._(this.date, this.holiday);

  final CalendarDate date;

  /// El feriado de ese día, si hay. Tiene prioridad sobre el fin de semana
  /// (un feriado que cae sábado se informa como feriado).
  final Holiday? holiday;

  bool get isHoliday => holiday != null;
  bool get isWeekend => date.isWeekend;

  @override
  bool operator ==(Object other) =>
      other is NonWorkingDay && other.date == date && other.holiday == holiday;

  @override
  int get hashCode => Object.hash(date, holiday);

  @override
  String toString() => 'NonWorkingDay($date, $holiday)';
}

/// Devuelve por qué [date] no es laborable, o `null` si es un día hábil.
NonWorkingDay? nonWorkingDayFor(CalendarDate date, Iterable<Holiday> holidays) {
  for (final h in holidays) {
    if (h.date == date) return NonWorkingDay._(date, h);
  }
  if (date.isWeekend) return NonWorkingDay._(date, null);
  return null;
}

/// Primer feriado con fecha igual o posterior a [from], o `null`.
Holiday? nextHoliday(Iterable<Holiday> holidays, CalendarDate from) {
  Holiday? next;
  for (final h in holidays) {
    if (h.date.isBefore(from)) continue;
    if (next == null || h.date.isBefore(next.date)) next = h;
  }
  return next;
}
