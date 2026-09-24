import '../../core/format/formatters.dart';
import '../../domain/domain.dart';
import '../local/app_database.dart';

/// Texto de un tramo para los mensajes: `08:00–12:00` o `08:00–abierto`.
String describirTramo(int ingresoMin, int? egresoMin) =>
    '${formatClock(ingresoMin)}–'
    '${egresoMin == null ? 'abierto' : formatClock(egresoMin)}';

/// Motivo (sin punto final) por el que no se puede fichar en un día no
/// laborable: "Hoy es feriado: Día ficticio", "Hoy es sábado: no es día
/// laborable", "El 12/10/2026 es día no laborable: …".
String motivoDiaNoLaborable(NonWorkingDay dia, {required bool esHoy}) {
  final sujeto = esHoy ? 'Hoy' : 'El ${formatDate(dia.date)}';
  final h = dia.holiday;
  if (h != null) {
    final que = h.kind == HolidayKind.nonWorking
        ? 'día no laborable'
        : 'feriado';
    return h.name.isEmpty ? '$sujeto es $que' : '$sujeto es $que: ${h.name}';
  }
  return '$sujeto es ${nombreDiaSemana(dia.date)}: no es día laborable';
}

/// Valida un tramo nuevo o que se cierra contra los otros del mismo día.
///
/// Devuelve el motivo para mostrar al usuario, o `null` si es válido. La
/// superposición se decide con `firstOverlapping` / `recordsOverlap` de
/// `domain/`. La usan el repositorio (autoridad) y la UI (para avisar antes
/// de confirmar).
String? validarTramo({
  required CalendarDate fecha,
  required int ingresoMin,
  int? egresoMin,
  String? id,
  required Iterable<LocalFichada> otrosDelDia,
}) {
  if (egresoMin != null && egresoMin <= ingresoMin) {
    return 'El egreso tiene que ser posterior al ingreso '
        '(${formatClock(ingresoMin)}).';
  }
  final candidato = DailyRecord(
    id: id,
    date: fecha,
    checkInMinutes: ingresoMin,
    checkOutMinutes: egresoMin,
  );
  final otros = [
    for (final f in otrosDelDia)
      if (f.deletedAt == null)
        DailyRecord(
          id: f.id,
          date: parseIsoDate(f.fecha),
          checkInMinutes: f.ingresoMin,
          checkOutMinutes: f.egresoMin,
        ),
  ];
  final choca = firstOverlapping(candidato, otros);
  if (choca == null) return null;
  return 'El tramo ${describirTramo(ingresoMin, egresoMin)} se superpone con '
      'el tramo ${describirTramo(choca.checkInMinutes, choca.checkOutMinutes)}.';
}

/// Qué se hace con un tramo desde la vista mensual (carga a mano).
enum EdicionTramo {
  /// Tramo nuevo en un día pasado (ingreso y egreso a mano).
  alta,

  /// Cambiar las horas de un tramo que ya tiene egreso, o el ingreso de uno
  /// abierto.
  edicion,

  /// Cargar el egreso de un tramo abierto.
  cierre,
}

/// Valida un tramo cargado a mano desde la vista mensual (agregar, editar o
/// cerrar). Devuelve el motivo para mostrar, o `null` si es válido.
///
/// Además de [validarTramo] (egreso posterior al ingreso y sin
/// superposición):
/// - nada de fechas futuras;
/// - un tramo nuevo solo en un día pasado (hoy se ficha desde Fichar) y
///   siempre con egreso (un tramo abierto de un día pasado bloquearía las
///   fichadas siguientes);
/// - no se agrega ni se cambian horas en un día no laborable. Cerrar un
///   tramo abierto se permite siempre, igual que al fichar;
/// - no se agrega un tramo antes del [inicioControl] (la primera fichada):
///   correría el inicio y los días del medio pasarían a ser faltantes;
/// - hoy, ninguna hora posterior a [ahoraMin] (ver [validarHoraNoFutura]).
///
/// La usan el repositorio (autoridad) y la UI (para avisar antes de guardar).
String? validarTramoManual({
  required EdicionTramo accion,
  required CalendarDate fecha,
  required CalendarDate hoy,
  required int ingresoMin,
  int? egresoMin,
  String? id,
  required Iterable<LocalFichada> otrosDelDia,
  required Iterable<Holiday> feriados,
  CalendarDate? inicioControl,
  int? ahoraMin,
}) {
  if (ingresoMin < 0 || ingresoMin > 1439) {
    return 'La hora de ingreso no es válida.';
  }
  if (egresoMin != null && (egresoMin < 0 || egresoMin > 1439)) {
    return 'La hora de egreso no es válida.';
  }
  if (fecha.isAfter(hoy)) {
    return 'El ${formatDate(fecha)} todavía no llegó: no se cargan tramos '
        'a futuro.';
  }
  if (accion == EdicionTramo.alta && !fecha.isBefore(hoy)) {
    return 'Los tramos de hoy se cargan desde Fichar.';
  }
  if (accion == EdicionTramo.alta &&
      inicioControl != null &&
      fecha.isBefore(inicioControl)) {
    return 'El control empezó el ${formatDate(inicioControl)} (primera '
        'fichada). No se agregan tramos anteriores.';
  }
  if (ahoraMin != null) {
    final futura = validarHoraNoFutura(
      fecha: fecha,
      hoy: hoy,
      ahoraMin: ahoraMin,
      ingresoMin: ingresoMin,
      egresoMin: egresoMin,
    );
    if (futura != null) return futura;
  }
  if ((accion == EdicionTramo.alta || accion == EdicionTramo.cierre) &&
      egresoMin == null) {
    return 'Falta la hora de egreso.';
  }
  if (accion != EdicionTramo.cierre) {
    final noLaborable = nonWorkingDayFor(fecha, feriados);
    if (noLaborable != null) {
      return '${motivoDiaNoLaborable(noLaborable, esHoy: fecha == hoy)}. '
          '${accion == EdicionTramo.alta ? 'No se pueden agregar tramos' : 'No se pueden cambiar las horas'}.';
    }
  }
  return validarTramo(
    fecha: fecha,
    ingresoMin: ingresoMin,
    egresoMin: egresoMin,
    id: id,
    otrosDelDia: otrosDelDia,
  );
}

/// Hoy no se carga una hora posterior a la actual ([ahoraMin], minutos
/// desde las 00:00 del dispositivo), ni en el ingreso ni en el egreso.
/// Devuelve el motivo, o `null`. Los días anteriores no tienen tope.
String? validarHoraNoFutura({
  required CalendarDate fecha,
  required CalendarDate hoy,
  required int ahoraMin,
  required int ingresoMin,
  int? egresoMin,
}) {
  if (fecha != hoy) return null;
  final ahora = formatClock(ahoraMin);
  if (ingresoMin > ahoraMin) {
    return 'Son las $ahora: el ingreso (${formatClock(ingresoMin)}) no puede '
        'ser posterior a la hora actual.';
  }
  if (egresoMin != null && egresoMin > ahoraMin) {
    return 'Son las $ahora: el egreso (${formatClock(egresoMin)}) no puede '
        'ser posterior a la hora actual.';
  }
  return null;
}

/// Interpreta una hora del día escrita a mano: `8:05`, `08:05`, `0805` o
/// `8`. Devuelve los minutos desde las 00:00, o `null` si no es una hora
/// válida (no se adivina: `25:00`, `8:75`, `8.30` → `null`).
int? parseClock(String text) {
  final t = text.trim();
  final m =
      RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(t) ??
      RegExp(r'^(\d{2})(\d{2})$').firstMatch(t) ??
      RegExp(r'^(\d{1,2})()$').firstMatch(t);
  if (m == null) return null;
  final h = int.parse(m.group(1)!);
  final min = m.group(2)!.isEmpty ? 0 : int.parse(m.group(2)!);
  if (h > 23 || min > 59) return null;
  return h * 60 + min;
}
