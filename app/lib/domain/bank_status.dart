import 'agrupamiento.dart';
import 'bank_balance.dart';
import 'calendar_date.dart';
import 'day_calculation.dart';
import 'models.dart';

/// Inicio del control para el banco: la primera fichada o, si todavía no
/// hay ninguna, [today] (así ningún día anterior es faltante). Sin fichadas
/// el control no empezó: [buildBankCalculator] no computa ningún movimiento
/// manual ("todo de cero").
CalendarDate bankControlStart(
  Iterable<DailyRecord> records,
  CalendarDate today,
) => controlStartFrom(records) ?? today;

/// Calculador que usan el saldo de Fichar, la pantalla Banco y la validación
/// de usufructos: jornada por agrupamiento, feriados, hoy e inicio del
/// control ([bankControlStart]). "Todo de cero": el saldo arranca en 0 en la
/// primera fichada; los movimientos anteriores (o todos, si todavía no hay
/// fichadas) no computan y quedan para revisar.
DayCalculator buildBankCalculator({
  required CalendarDate today,
  Iterable<DailyRecord> records = const [],
  Iterable<Holiday> holidays = const [],
  Agrupamiento? agrupamiento,
  Iterable<WorkdaySchedule> schedules = const [],
}) => DayCalculator(
  schedules: schedules,
  holidays: holidays,
  today: today,
  controlStart: bankControlStart(records, today),
  controlStarted: controlStartFrom(records) != null,
  agrupamiento: agrupamiento,
);

/// Estado del banco a una fecha: el saldo actual (hasta hoy inclusive) y lo
/// que ya está cargado a futuro.
class BankStatus {
  const BankStatus({
    required this.current,
    required this.futureUsufructMinutes,
    required this.futureAccumulationMinutes,
  });

  /// Saldo y desglose hasta hoy inclusive.
  final BankBalance current;

  /// Σ usufructos vigentes con fecha posterior a hoy. Todavía no restan del
  /// saldo actual, pero ya comprometen horas del banco.
  final int futureUsufructMinutes;

  /// Σ acumulaciones vigentes con fecha posterior a hoy. No suman al saldo
  /// actual ni al disponible hasta que llegue la fecha.
  final int futureAccumulationMinutes;

  /// Saldo actual (puede ser negativo).
  int get balanceMinutes => current.balanceMinutes;

  /// Lo que queda para usufructos nuevos: el saldo actual menos los
  /// usufructos ya cargados a futuro.
  int get availableMinutes => current.balanceMinutes - futureUsufructMinutes;
}

/// Calcula el [BankStatus] con el calculador de [buildBankCalculator]
/// (`calculator.today` es obligatorio).
BankStatus calculateBankStatus({
  required DayCalculator calculator,
  Iterable<DailyRecord> records = const [],
  Iterable<BankMovement> movements = const [],
}) {
  final today = calculator.today;
  if (today == null) {
    throw ArgumentError('El calculador necesita la fecha de hoy.');
  }
  var futureUsufruct = 0;
  var futureAccumulation = 0;
  for (final m in movements) {
    if (!m.date.isAfter(today) || !calculator.countsMovementsOn(m.date)) {
      continue;
    }
    if (m.isActiveUsufruct) futureUsufruct += m.minutes;
    if (m.isActiveAccumulation) futureAccumulation += m.minutes;
  }
  return BankStatus(
    current: calculateBankBalance(
      calculator: calculator,
      records: records,
      movements: movements,
      to: today,
    ),
    futureUsufructMinutes: futureUsufruct,
    futureAccumulationMinutes: futureAccumulation,
  );
}

/// Saldo disponible para cargar el usufructo [candidate] (el valor que va
/// como `balanceBeforeMinutes` en `validateUsufruct`).
///
/// - Incluye los usufructos ya cargados a futuro (decisión de Bruno): lo
///   comprometido no se puede volver a usar.
/// - No incluye las acumulaciones con fecha posterior a hoy.
/// - Se ignora el movimiento con id [replacingId] (el que se está editando).
/// - Si [candidate] cubre deuda de su día (por ej. un usufructo cargado
///   después de un día faltante), esa deuda no se cuenta dos veces: se
///   calcula el saldo con el usufructo cargado y se le suman sus minutos.
///
/// Con `calculator.today` obligatorio.
int usufructAvailableMinutes({
  required DayCalculator calculator,
  required BankMovement candidate,
  Iterable<DailyRecord> records = const [],
  Iterable<BankMovement> movements = const [],
  String? replacingId,
}) {
  final today = calculator.today;
  if (today == null) {
    throw ArgumentError('El calculador necesita la fecha de hoy.');
  }
  final others = [
    for (final m in movements)
      if (!(replacingId != null && m.id == replacingId) &&
          !(m.isAccumulation && m.date.isAfter(today)))
        m,
  ];
  final active = candidate.isActive
      ? candidate
      : BankMovement.usufruct(
          id: candidate.id,
          date: candidate.date,
          scope: candidate.scope ?? UsufructScope.partial,
          minutes: candidate.minutes,
        );
  final withCandidate = calculateBankBalance(
    calculator: calculator,
    records: records,
    movements: [...others, active],
  );
  return withCandidate.balanceMinutes + active.minutes;
}
