import '../../core/format/formatters.dart';
import '../../domain/domain.dart';
import '../local/app_database.dart';

/// Texto de un tramo para los mensajes: `08:00–12:00` o `08:00–abierto`.
String describirTramo(int ingresoMin, int? egresoMin) =>
    '${formatClock(ingresoMin)}–'
    '${egresoMin == null ? 'abierto' : formatClock(egresoMin)}';

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
