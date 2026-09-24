/// Fecha de calendario sin hora ni zona horaria.
///
/// Se usa en lugar de [DateTime] para que las fechas del dominio no dependan
/// de la zona horaria del dispositivo ni del horario de verano.
class CalendarDate implements Comparable<CalendarDate> {
  /// Crea una fecha. Lanza [ArgumentError] si la fecha no existe
  /// (por ejemplo, 31/02).
  factory CalendarDate(int year, int month, int day) {
    final utc = DateTime.utc(year, month, day);
    if (utc.year != year || utc.month != month || utc.day != day) {
      throw ArgumentError('Fecha inválida: $day/$month/$year');
    }
    return CalendarDate._(year, month, day);
  }

  const CalendarDate._(this.year, this.month, this.day);

  /// Toma solo año, mes y día de [dateTime] (en su propia zona horaria).
  factory CalendarDate.fromDateTime(DateTime dateTime) =>
      CalendarDate._(dateTime.year, dateTime.month, dateTime.day);

  final int year;
  final int month;
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);

  /// Día de la semana: 1 = lunes … 7 = domingo (igual que [DateTime.weekday]).
  int get weekday => _utc.weekday;

  /// `true` si es sábado o domingo.
  bool get isWeekend =>
      weekday == DateTime.saturday || weekday == DateTime.sunday;

  CalendarDate addDays(int days) =>
      CalendarDate.fromDateTime(_utc.add(Duration(days: days)));

  /// Cantidad de días del mes [month] del año [year].
  static int daysInMonth(int year, int month) =>
      DateTime.utc(year, month + 1, 0).day;

  bool isBefore(CalendarDate other) => compareTo(other) < 0;
  bool isAfter(CalendarDate other) => compareTo(other) > 0;

  @override
  int compareTo(CalendarDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is CalendarDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// Formato ISO `yyyy-MM-dd` (para depurar y serializar, no para la UI).
  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}
