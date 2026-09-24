import 'package:intl/intl.dart';

import '../../domain/domain.dart';

export '../../domain/time_format.dart' show formatMinutes;

/// Locale de toda la UI.
const appLocale = 'es_AR';

/// Hora del día (minutos desde las 00:00) como reloj: `8 * 60 + 2 → "08:02"`.
///
/// Para saldos y duraciones se usa [formatMinutes] (admite negativos).
String formatClock(int minutesOfDay) {
  final h = minutesOfDay ~/ 60;
  final m = minutesOfDay % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

/// Minutos desde la medianoche de [dateTime] (hora local del dispositivo).
int minutesOfDay(DateTime dateTime) => dateTime.hour * 60 + dateTime.minute;

DateTime _asDateTime(CalendarDate date) =>
    DateTime(date.year, date.month, date.day);

/// `dd/MM/yyyy`. Es numérico, así que no necesita los datos de locale de
/// `intl` (se puede usar en la capa de datos y en tests sin inicializarlos).
String formatDate(CalendarDate date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.year.toString().padLeft(4, '0')}';

/// `jueves 24/09/2026`.
String formatDateLong(CalendarDate date) =>
    DateFormat('EEEE dd/MM/yyyy', appLocale).format(_asDateTime(date));

/// Fecha ISO `yyyy-MM-dd` (columna `date` de Postgres y de la base local).
String toIsoDate(CalendarDate date) => date.toString();

/// Inversa de [toIsoDate].
CalendarDate parseIsoDate(String iso) {
  final parts = iso.split('-');
  return CalendarDate(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2].substring(0, 2)),
  );
}

const _diasSemana = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// Día de la semana en español: `sábado`. No necesita los datos de `intl`.
String nombreDiaSemana(CalendarDate date) => _diasSemana[date.weekday - 1];

/// Nombre del mes en español (`1 → enero`).
String nombreMes(int month) => _meses[month - 1];
