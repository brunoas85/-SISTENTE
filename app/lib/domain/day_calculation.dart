import 'agrupamiento.dart';
import 'calendar_date.dart';
import 'models.dart';
import 'workday_schedule.dart';

/// Estado único de un día. Un día tiene un solo estado: nunca es a la vez
/// deuda y usufructo.
enum DayStatus {
  /// Día hábil con uno o más tramos completos que no se superponen: computa
  /// la suma de los tramos. Deuda y a favor contra la jornada; la deuda
  /// puede estar cubierta (total o parcialmente) por un usufructo vigente.
  worked,

  /// Fin de semana, feriado o no laborable turístico con fichadas (por
  /// ejemplo, importadas). Esos días no se ficha: las fichadas no computan
  /// (ni a favor ni deuda) y el día queda para revisar. Las horas de un
  /// sábado se cargan como acumulación manual.
  nonWorkingDayRecords,

  /// Algún tramo no tiene egreso. No computa.
  open,

  /// Algún tramo tiene el egreso anterior o igual al ingreso. No computa y
  /// hay que revisarlo.
  invalid,

  /// Hay tramos que se superponen. No computa (no se suman en silencio) y
  /// hay que revisarlo.
  conflict,

  /// Sin fichada y con un usufructo vigente que lo cubre. No genera deuda.
  usufruct,

  /// Día hábil pasado (anterior a "hoy") sin fichada ni usufructo que lo
  /// cubra del todo. Genera deuda igual a la jornada vigente, menos lo que cubra un
  /// usufructo parcial.
  missing,

  /// Fin de semana, feriado o día no laborable sin fichada.
  nonWorkingDay,

  /// Día hábil posterior a "hoy" sin fichada: todavía no es faltante ni
  /// genera deuda.
  future,

  /// Día hábil de hoy sin fichada: el día todavía no terminó, así que no es
  /// faltante ni genera deuda.
  today,

  /// Día hábil anterior al inicio del control (la primera fichada con la
  /// app) sin fichada: no es faltante ni genera deuda.
  beforeControl,
}

/// Resultado del cálculo de un día.
class DayResult {
  const DayResult({
    required this.date,
    required this.status,
    required this.workdayMinutes,
    required this.isBusinessDay,
    this.records = const [],
    this.workedMinutes,
    this.debtMinutes = 0,
    this.creditMinutes = 0,
    this.coveredDebtMinutes = 0,
    this.activeUsufructMinutes = 0,
    this.lostUsufructMinutes = 0,
    this.accumulationMinutes = 0,
    this.lostAccumulationMinutes = 0,
    this.fullUsufructMismatch = false,
    this.provisionalDebtMinutes = 0,
    this.outsideControlMovements = const [],
  });

  final CalendarDate date;
  final DayStatus status;

  /// Jornada vigente ese día.
  final int workdayMinutes;

  /// Lunes a viernes y no feriado/no laborable.
  final bool isBusinessDay;

  /// Tramos del día.
  final List<DailyRecord> records;

  /// Σ tramos, o `null` si no se puede calcular (sin fichada, abierto,
  /// inválido o en conflicto).
  final int? workedMinutes;

  /// Deuda del día: `max(jornada - trabajado, 0)` en día hábil trabajado, o
  /// la jornada completa en un día [DayStatus.missing]. Un día
  /// [DayStatus.usufruct] no tiene deuda.
  final int debtMinutes;

  /// A favor del día: `max(trabajado - jornada, 0)` en día hábil. Las
  /// fichadas de un día no laborable no generan a favor.
  final int creditMinutes;

  /// Parte de la deuda cubierta por usufructos vigentes del día.
  final int coveredDebtMinutes;

  /// Minutos de usufructo vigente con fecha de este día.
  final int activeUsufructMinutes;

  /// Minutos de usufructo perdido con fecha de este día (solo historial).
  final int lostUsufructMinutes;

  /// Minutos de acumulación vigente con fecha de este día.
  final int accumulationMinutes;

  /// Minutos de acumulación perdida con fecha de este día (solo historial).
  final int lostAccumulationMinutes;

  /// Hay un usufructo total vigente cuyos minutos no son iguales a la
  /// jornada vigente del día. Se computa tal como se cargó, pero queda para
  /// revisar.
  final bool fullUsufructMismatch;

  /// Solo para hoy: la deuda que habría si el día terminara ahora
  /// (`max(jornada - trabajado, 0)`). Es informativa: **no** resta del banco
  /// hasta que el día termina. Lo a favor de hoy sí computa.
  final int provisionalDebtMinutes;

  /// Movimientos manuales con fecha anterior al inicio del control (o
  /// cargados cuando todavía no hay fichadas). "Todo de cero": no computan
  /// (ni vigentes ni perdidos) y el día queda para revisar.
  final List<BankMovement> outsideControlMovements;

  /// Deuda que resta del banco.
  int get uncoveredDebtMinutes => debtMinutes - coveredDebtMinutes;

  /// Efecto de este día sobre el saldo del banco.
  int get bankDeltaMinutes =>
      creditMinutes +
      accumulationMinutes -
      uncoveredDebtMinutes -
      activeUsufructMinutes;

  /// El día necesita revisión manual: tramos superpuestos o inválidos,
  /// fichadas en un día no laborable, un usufructo total distinto de la
  /// jornada, o un día sin fichada cubierto solo en parte por usufructos.
  bool get needsReview =>
      status == DayStatus.conflict ||
      status == DayStatus.nonWorkingDayRecords ||
      status == DayStatus.invalid ||
      fullUsufructMismatch ||
      outsideControlMovements.isNotEmpty ||
      (status == DayStatus.missing && coveredDebtMinutes > 0);
}

/// Calcula el trabajado de un tramo: `egreso - ingreso`.
///
/// Devuelve `null` si el tramo está abierto (sin egreso) o si el egreso no
/// es posterior al ingreso. Nunca devuelve un valor negativo.
int? workedMinutesOf(DailyRecord record) {
  final out = record.checkOutMinutes;
  if (out == null) return null;
  if (out <= record.checkInMinutes) return null;
  return out - record.checkInMinutes;
}

/// `true` si algún par de [records] se superpone. Un tramo abierto se
/// considera abierto hasta el final del día. Tramos que solo se tocan
/// (uno termina 12:00 y el otro empieza 12:00) no se superponen.
bool recordsOverlap(Iterable<DailyRecord> records) {
  final sorted = records.toList()
    ..sort((a, b) => a.checkInMinutes.compareTo(b.checkInMinutes));
  for (var i = 1; i < sorted.length; i++) {
    final prev = sorted[i - 1];
    final prevEnd = prev.checkOutMinutes ?? 1440;
    if (sorted[i].checkInMinutes < prevEnd) return true;
  }
  return false;
}

/// Primer tramo de [others] que se superpone con [candidate] según
/// [recordsOverlap], o `null` si no choca con ninguno. Se ignora el tramo
/// con el mismo `id` que [candidate] (el que se está editando) y los de otra
/// fecha.
DailyRecord? firstOverlapping(
  DailyRecord candidate,
  Iterable<DailyRecord> others,
) {
  for (final other in others) {
    if (other.date != candidate.date) continue;
    if (candidate.id != null && other.id == candidate.id) continue;
    if (recordsOverlap([other, candidate])) return other;
  }
  return null;
}

/// Calcula el estado y los minutos de cada día.
/// Inicio del control: la fecha de la primera fichada, o `null` si todavía
/// no hay ninguna.
CalendarDate? controlStartFrom(Iterable<DailyRecord> records) {
  CalendarDate? first;
  for (final r in records) {
    if (first == null || r.date.isBefore(first)) first = r.date;
  }
  return first;
}

class DayCalculator {
  /// La jornada de cada día sale de [schedules] (vigencias de `jornadas`);
  /// sin vigencia, del [agrupamiento] (8 h o 7 h) o, si no hay, 480 min.
  /// [defaultWorkdayMinutes], si se indica, reemplaza al del agrupamiento.
  DayCalculator({
    Iterable<WorkdaySchedule> schedules = const [],
    Iterable<Holiday> holidays = const [],
    this.today,
    this.controlStart,
    this.controlStarted = true,
    Agrupamiento? agrupamiento,
    int? defaultWorkdayMinutes,
  }) : _schedules = WorkdayScheduleResolver(
         schedules,
         agrupamiento: agrupamiento,
         defaultMinutes: defaultWorkdayMinutes,
       ),
       _holidays = {for (final h in holidays) h.date};

  final WorkdayScheduleResolver _schedules;
  final Set<CalendarDate> _holidays;

  /// Si se indica, los días hábiles posteriores sin fichada son
  /// [DayStatus.future] (sin deuda) en vez de [DayStatus.missing]. El día de
  /// hoy no genera deuda hasta que termina: sin fichada es
  /// [DayStatus.today], y con tramos cerrados su deuda queda en
  /// [DayResult.provisionalDebtMinutes] sin restar (lo a favor sí computa).
  final CalendarDate? today;

  /// Inicio del control: el día en que se empieza a fichar con la app (ver
  /// [controlStartFrom]). Los días hábiles anteriores sin fichada son
  /// [DayStatus.beforeControl] (sin deuda) en vez de [DayStatus.missing].
  ///
  /// "Todo de cero": los movimientos manuales con fecha anterior no computan
  /// (quedan en [DayResult.outsideControlMovements] para revisar).
  final CalendarDate? controlStart;

  /// `false` si el control todavía no empezó (no hay ninguna fichada):
  /// ningún movimiento manual computa. [controlStart] puede ser igual "hoy"
  /// para que los días anteriores no sean faltantes.
  final bool controlStarted;

  /// `true` si un movimiento manual con fecha [date] computa en el saldo.
  bool countsMovementsOn(CalendarDate date) {
    if (!controlStarted) return false;
    final start = controlStart;
    return start == null || !date.isBefore(start);
  }

  /// Feriado o día no laborable (según la lista recibida).
  bool isHoliday(CalendarDate date) => _holidays.contains(date);

  bool isBusinessDay(CalendarDate date) =>
      !date.isWeekend && !_holidays.contains(date);

  int workdayMinutesFor(CalendarDate date) => _schedules.minutesFor(date);

  /// Calcula el día [date]. Los [records] y [movements] que no son de esa
  /// fecha se ignoran.
  DayResult calculate(
    CalendarDate date, {
    Iterable<DailyRecord> records = const [],
    Iterable<BankMovement> movements = const [],
  }) {
    final dayRecords = records.where((r) => r.date == date).toList();
    final allDayMovements = movements.where((m) => m.date == date).toList();
    final counts = countsMovementsOn(date);
    final dayMovements = counts ? allDayMovements : const <BankMovement>[];
    final outside = counts ? const <BankMovement>[] : allDayMovements;

    final workday = workdayMinutesFor(date);
    final business = isBusinessDay(date);

    var activeUsufruct = 0;
    var lostUsufruct = 0;
    var accumulation = 0;
    var lostAccumulation = 0;
    var fullMismatch = false;
    for (final m in dayMovements) {
      if (m.isActiveAccumulation) {
        accumulation += m.minutes;
      } else if (m.isLostAccumulation) {
        lostAccumulation += m.minutes;
      } else if (m.isActiveUsufruct) {
        activeUsufruct += m.minutes;
        if (m.isFullUsufruct && m.minutes != workday) fullMismatch = true;
      } else if (m.isLostUsufruct) {
        lostUsufruct += m.minutes;
      }
    }

    DayResult result(
      DayStatus status, {
      int? worked,
      int debt = 0,
      int credit = 0,
      int provisionalDebt = 0,
    }) {
      final covered = debt < activeUsufruct ? debt : activeUsufruct;
      return DayResult(
        date: date,
        status: status,
        workdayMinutes: workday,
        isBusinessDay: business,
        records: List.unmodifiable(dayRecords),
        workedMinutes: worked,
        debtMinutes: debt,
        creditMinutes: credit,
        coveredDebtMinutes: covered,
        activeUsufructMinutes: activeUsufruct,
        lostUsufructMinutes: lostUsufruct,
        accumulationMinutes: accumulation,
        lostAccumulationMinutes: lostAccumulation,
        fullUsufructMismatch: fullMismatch,
        provisionalDebtMinutes: provisionalDebt,
        outsideControlMovements: List.unmodifiable(outside),
      );
    }

    // Hoy todavía no terminó: no genera deuda ni es faltante.
    final isToday = today != null && date == today;

    if (dayRecords.isNotEmpty) {
      // Día no laborable: no se ficha. Si llegan fichadas (importadas, de
      // otra versión), no computan y quedan para revisar.
      if (!business) return result(DayStatus.nonWorkingDayRecords);
      final complete = dayRecords.where((r) => !r.isOpen);
      if (complete.any((r) => workedMinutesOf(r) == null)) {
        return result(DayStatus.invalid);
      }
      if (recordsOverlap(dayRecords)) return result(DayStatus.conflict);
      if (dayRecords.any((r) => r.isOpen)) return result(DayStatus.open);

      final worked = dayRecords.fold(0, (sum, r) => sum + workedMinutesOf(r)!);
      // A favor: solo lo que excede la jornada, al minuto.
      final debt = workday > worked ? workday - worked : 0;
      return result(
        DayStatus.worked,
        worked: worked,
        // La deuda de hoy no resta hasta que termine el día; lo a favor sí.
        debt: isToday ? 0 : debt,
        provisionalDebt: isToday ? debt : 0,
        credit: worked > workday ? worked - workday : 0,
      );
    }

    // Sin fichada.
    final hasUsufruct = activeUsufruct > 0;
    if (!business) {
      return result(hasUsufruct ? DayStatus.usufruct : DayStatus.nonWorkingDay);
    }
    final t = today;
    if (t != null && date.isAfter(t)) {
      return result(hasUsufruct ? DayStatus.usufruct : DayStatus.future);
    }
    if (isToday) {
      return result(hasUsufruct ? DayStatus.usufruct : DayStatus.today);
    }
    final start = controlStart;
    if (start != null && date.isBefore(start)) {
      // Antes del inicio del control no hay deuda, y sus movimientos no
      // computan ("todo de cero").
      return result(DayStatus.beforeControl);
    }
    // Día hábil pasado sin fichada: si un usufructo vigente lo cubre, no hay
    // deuda. Si no, la jornada completa es deuda, menos lo que cubra un
    // usufructo parcial.
    if (hasUsufruct && activeUsufruct >= workday) {
      return result(DayStatus.usufruct);
    }
    return result(DayStatus.missing, debt: workday);
  }
}
