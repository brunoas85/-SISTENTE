import 'bank_balance.dart';
import 'calendar_date.dart';
import 'day_calculation.dart';
import 'models.dart';

/// Resumen de un mes concreto (año + mes, nunca solo el nombre del mes).
class MonthlySummary {
  const MonthlySummary({
    required this.year,
    required this.month,
    required this.days,
    required this.bank,
  });

  final int year;
  final int month;

  /// Todos los días del mes, del 1 al último, cada uno con un solo estado.
  final List<DayResult> days;

  /// Movimientos del banco del mes (desglose y variación del saldo).
  final BankBalance bank;

  /// Σ trabajado de los días que computan.
  int get workedMinutes => days
      .where((d) => d.status == DayStatus.worked)
      .fold(0, (sum, d) => sum + (d.workedMinutes ?? 0));

  /// Σ deuda (cubierta y no cubierta), incluida la de los días faltantes.
  int get debtMinutes => days.fold(0, (sum, d) => sum + d.debtMinutes);

  /// Σ deuda cubierta por usufructos.
  int get coveredDebtMinutes =>
      days.fold(0, (sum, d) => sum + d.coveredDebtMinutes);

  int get uncoveredDebtMinutes => bank.uncoveredDebtMinutes;
  int get creditMinutes => bank.creditMinutes;
  int get accumulationMinutes => bank.accumulationMinutes;
  int get activeUsufructMinutes => bank.activeUsufructMinutes;
  int get lostUsufructMinutes => bank.lostUsufructMinutes;
  int get lostAccumulationMinutes => bank.lostAccumulationMinutes;

  /// Variación del saldo del banco en el mes (puede ser negativa).
  int get bankDeltaMinutes => bank.balanceMinutes;

  List<DayResult> _withStatus(DayStatus s) =>
      days.where((d) => d.status == s).toList();

  /// Días hábiles sin fichada ni usufructo que los cubra (restan la jornada).
  List<DayResult> get missingDays => _withStatus(DayStatus.missing);
  List<DayResult> get openDays => _withStatus(DayStatus.open);
  List<DayResult> get conflictDays => _withStatus(DayStatus.conflict);
  List<DayResult> get daysNeedingReview =>
      days.where((d) => d.needsReview).toList();

  /// Cantidad de días hábiles del mes (lun–vie, sin feriados).
  int get businessDayCount => days.where((d) => d.isBusinessDay).length;
}

/// Arma el resumen de [year]/[month]. Los registros y movimientos de otros
/// meses se ignoran.
MonthlySummary buildMonthlySummary({
  required int year,
  required int month,
  required DayCalculator calculator,
  Iterable<DailyRecord> records = const [],
  Iterable<BankMovement> movements = const [],
}) {
  final first = CalendarDate(year, month, 1);
  final last = CalendarDate(year, month, CalendarDate.daysInMonth(year, month));

  final monthRecords =
      records.where((r) => r.date.year == year && r.date.month == month);
  final monthMovements =
      movements.where((m) => m.date.year == year && m.date.month == month);

  final recordsByDate = <CalendarDate, List<DailyRecord>>{};
  for (final r in monthRecords) {
    (recordsByDate[r.date] ??= []).add(r);
  }
  final movementsByDate = <CalendarDate, List<BankMovement>>{};
  for (final m in monthMovements) {
    (movementsByDate[m.date] ??= []).add(m);
  }

  final days = <DayResult>[];
  for (var d = first; !d.isAfter(last); d = d.addDays(1)) {
    days.add(
      calculator.calculate(
        d,
        records: recordsByDate[d] ?? const [],
        movements: movementsByDate[d] ?? const [],
      ),
    );
  }

  return MonthlySummary(
    year: year,
    month: month,
    days: List.unmodifiable(days),
    bank: calculateBankBalance(
      calculator: calculator,
      records: monthRecords,
      movements: monthMovements,
      from: first,
      to: last,
    ),
  );
}
