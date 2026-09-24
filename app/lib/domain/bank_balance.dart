import 'calendar_date.dart';
import 'day_calculation.dart';
import 'models.dart';

/// Saldo del banco de horas y su desglose. Todo en minutos; el saldo puede
/// ser negativo.
class BankBalance {
  const BankBalance({
    required this.creditMinutes,
    required this.accumulationMinutes,
    required this.uncoveredDebtMinutes,
    required this.activeUsufructMinutes,
    required this.lostUsufructMinutes,
    required this.lostAccumulationMinutes,
    required this.days,
  });

  /// Σ a favor diario (derivado de las fichadas).
  final int creditMinutes;

  /// Σ acumulaciones manuales vigentes.
  final int accumulationMinutes;

  /// Σ deuda diaria no cubierta por usufructos (incluye la jornada completa
  /// de los días faltantes).
  final int uncoveredDebtMinutes;

  /// Σ usufructos vigentes.
  final int activeUsufructMinutes;

  /// Σ usufructos perdidos (solo informativo: no descuenta).
  final int lostUsufructMinutes;

  /// Σ acumulaciones perdidas (solo informativo: no suman).
  final int lostAccumulationMinutes;

  /// Días que entraron en el cálculo, ordenados: todos los del rango más los
  /// que tienen fichadas o movimientos.
  final List<DayResult> days;

  /// `Σ a_favor + Σ acumulación - Σ deuda no cubierta - Σ usufructo vigente`.
  int get balanceMinutes =>
      creditMinutes +
      accumulationMinutes -
      uncoveredDebtMinutes -
      activeUsufructMinutes;

  /// Días con tramos superpuestos (no se sumaron).
  List<DayResult> get conflicts =>
      days.where((d) => d.status == DayStatus.conflict).toList();

  /// Días con registro abierto (no computan).
  List<DayResult> get openDays =>
      days.where((d) => d.status == DayStatus.open).toList();

  /// Días hábiles faltantes (restan la jornada, salvo cobertura parcial).
  List<DayResult> get missingDays =>
      days.where((d) => d.status == DayStatus.missing).toList();

  /// Movimientos que no computan por tener fecha anterior al inicio del
  /// control (o por no haber fichadas todavía). Quedan para revisar.
  List<BankMovement> get movementsOutsideControl => [
    for (final d in days) ...d.outsideControlMovements,
  ];

  /// Días que necesitan revisión manual (ver [DayResult.needsReview]).
  List<DayResult> get daysNeedingReview =>
      days.where((d) => d.needsReview).toList();
}

/// Calcula el saldo del banco con los [records] y [movements] dados.
///
/// Se recorren todos los días de `[from, to]` (inclusive), porque un día
/// hábil sin fichada ni usufructo resta la jornada completa:
/// - si falta [from], se empieza en la primera fecha con datos;
/// - si falta [to], se termina en `calculator.today` o, si tampoco hay, en
///   la última fecha con datos.
///
/// Las fechas con datos posteriores al final (por ej. un usufructo a futuro)
/// también se incluyen, siempre que no pasen de [to]. Los días abiertos, en
/// conflicto o inválidos no suman ni restan por fichadas (sí cuentan sus
/// movimientos manuales) y quedan listados en [BankBalance.days].
BankBalance calculateBankBalance({
  required DayCalculator calculator,
  Iterable<DailyRecord> records = const [],
  Iterable<BankMovement> movements = const [],
  CalendarDate? from,
  CalendarDate? to,
}) {
  bool inRange(CalendarDate d) =>
      (from == null || !d.isBefore(from)) && (to == null || !d.isAfter(to));

  final recordsByDate = <CalendarDate, List<DailyRecord>>{};
  for (final r in records) {
    if (inRange(r.date)) (recordsByDate[r.date] ??= []).add(r);
  }
  final movementsByDate = <CalendarDate, List<BankMovement>>{};
  for (final m in movements) {
    if (inRange(m.date)) (movementsByDate[m.date] ??= []).add(m);
  }

  final dataDates = {...recordsByDate.keys, ...movementsByDate.keys}.toList()
    ..sort();
  final dateSet = {...dataDates};
  final start = from ?? (dataDates.isEmpty ? null : dataDates.first);
  final end =
      to ?? calculator.today ?? (dataDates.isEmpty ? null : dataDates.last);
  if (start != null && end != null) {
    for (var d = start; !d.isAfter(end); d = d.addDays(1)) {
      dateSet.add(d);
    }
  }
  final dates = dateSet.toList()..sort();

  var credit = 0;
  var accumulation = 0;
  var uncoveredDebt = 0;
  var activeUsufruct = 0;
  var lostUsufruct = 0;
  var lostAccumulation = 0;
  final days = <DayResult>[];
  for (final date in dates) {
    final day = calculator.calculate(
      date,
      records: recordsByDate[date] ?? const [],
      movements: movementsByDate[date] ?? const [],
    );
    days.add(day);
    credit += day.creditMinutes;
    accumulation += day.accumulationMinutes;
    uncoveredDebt += day.uncoveredDebtMinutes;
    activeUsufruct += day.activeUsufructMinutes;
    lostUsufruct += day.lostUsufructMinutes;
    lostAccumulation += day.lostAccumulationMinutes;
  }

  return BankBalance(
    creditMinutes: credit,
    accumulationMinutes: accumulation,
    uncoveredDebtMinutes: uncoveredDebt,
    activeUsufructMinutes: activeUsufruct,
    lostUsufructMinutes: lostUsufruct,
    lostAccumulationMinutes: lostAccumulation,
    days: List.unmodifiable(days),
  );
}
