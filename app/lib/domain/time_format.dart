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
