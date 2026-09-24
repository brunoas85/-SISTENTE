/// Formatea una cantidad de minutos como `H:MM` con signo.
///
/// ```
/// formatMinutes(-1440) // "-24:00"
/// formatMinutes(480)   // "8:00"
/// formatMinutes(0)     // "0:00"
/// formatMinutes(-30)   // "-0:30"
/// ```
///
/// Las horas no tienen tope (100 h → `100:00`), así que nunca aparece el
/// `#####` de Excel con saldos negativos.
String formatMinutes(int minutes) {
  final sign = minutes < 0 ? '-' : '';
  final abs = minutes.abs();
  final hours = abs ~/ 60;
  final mins = abs % 60;
  return '$sign$hours:${mins.toString().padLeft(2, '0')}';
}

/// Interpreta una duración escrita a mano como `H:MM` y devuelve los minutos.
///
/// ```
/// parseHoursMinutes('2:30')  // 150
/// parseHoursMinutes('08:00') // 480
/// parseHoursMinutes('3')     // 180 (horas enteras)
/// parseHoursMinutes('0:45')  // 45
/// ```
///
/// Devuelve `null` si el texto está vacío, es negativo o no tiene el formato
/// (por ej. `2:75`, `1,5`, `-1:00`): no se adivina.
int? parseHoursMinutes(String text) {
  final t = text.trim();
  final match = RegExp(r'^(\d{1,3})(?::(\d{2}))?$').firstMatch(t);
  if (match == null) return null;
  final hours = int.parse(match.group(1)!);
  final mins = match.group(2) == null ? 0 : int.parse(match.group(2)!);
  if (mins >= 60) return null;
  return hours * 60 + mins;
}
