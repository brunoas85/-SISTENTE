// Casos raros de la planilla `control asistencia.v2.xlsx`. Un test por caso.
// Todos los datos son ficticios.
import 'package:asistente/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

int hm(int h, int m) => h * 60 + m;

void main() {
  final monday = CalendarDate(2026, 6, 1); // lunes
  final calc = DayCalculator();
  // Para los resúmenes mensuales: "hoy" es el lunes, así el resto del mes es
  // futuro y no genera deuda por faltante.
  final calcToday = DayCalculator(today: monday);

  test('egreso vacío: queda abierto, no da -5:53 trabajadas ni 13:53 de deuda',
      () {
    final record = DailyRecord(date: monday, checkInMinutes: hm(5, 53));
    final day = calc.calculate(monday, records: [record]);

    expect(day.status, DayStatus.open);
    expect(day.workedMinutes, isNull);
    expect(day.debtMinutes, 0);
    expect(day.creditMinutes, 0);
    expect(day.bankDeltaMinutes, 0);

    final balance = calculateBankBalance(calculator: calc, records: [record]);
    expect(balance.balanceMinutes, 0);
    expect(formatMinutes(balance.balanceMinutes), isNot('-13:53'));
    expect(balance.openDays, hasLength(1));

    // Tampoco cuenta como faltante: el día tiene fichada.
    final summary = buildMonthlySummary(
      year: 2026,
      month: 6,
      calculator: calcToday,
      records: [record],
    );
    expect(summary.missingDays.map((d) => d.date), isNot(contains(monday)));
    expect(summary.debtMinutes, 0);
  });

  test('saldo negativo: se calcula y se muestra como -24:00', () {
    final balance = calculateBankBalance(
      calculator: calc,
      movements: [
        for (var i = 0; i < 3; i++)
          BankMovement.usufruct(
            date: monday.addDays(i),
            scope: UsufructScope.full,
            minutes: 480,
          ),
      ],
    );
    expect(balance.balanceMinutes, -1440);
    expect(formatMinutes(balance.balanceMinutes), '-24:00');
  });

  group('día duplicado', () {
    test('dos tramos que no se superponen se suman', () {
      final records = [
        DailyRecord(
          id: 'a',
          date: monday,
          checkInMinutes: hm(7, 0),
          checkOutMinutes: hm(12, 0),
        ),
        DailyRecord(
          id: 'b',
          date: monday,
          checkInMinutes: hm(13, 0),
          checkOutMinutes: hm(17, 0),
        ),
      ];
      final day = calc.calculate(monday, records: records);
      expect(day.status, DayStatus.worked);
      expect(day.records, hasLength(2));
      expect(day.workedMinutes, 300 + 240);
      expect(day.bankDeltaMinutes, 60);
      expect(day.needsReview, isFalse);

      final balance = calculateBankBalance(calculator: calc, records: records);
      expect(balance.balanceMinutes, 60);
      expect(balance.conflicts, isEmpty);

      final summary = buildMonthlySummary(
        year: 2026,
        month: 6,
        calculator: calcToday,
        records: records,
      );
      expect(summary.workedMinutes, 540);
      expect(summary.bankDeltaMinutes, 60);
    });

    test('dos tramos que se superponen dan conflicto y no se suman', () {
      final records = [
        DailyRecord(
          id: 'a',
          date: monday,
          checkInMinutes: hm(7, 0),
          checkOutMinutes: hm(17, 0),
        ),
        DailyRecord(
          id: 'b',
          date: monday,
          checkInMinutes: hm(8, 0),
          checkOutMinutes: hm(16, 0),
        ),
      ];
      final day = calc.calculate(monday, records: records);
      expect(day.status, DayStatus.conflict);
      expect(day.records, hasLength(2));
      expect(day.workedMinutes, isNull);
      expect(day.bankDeltaMinutes, 0);
      expect(day.needsReview, isTrue);

      final balance = calculateBankBalance(calculator: calc, records: records);
      expect(balance.balanceMinutes, 0); // ni +120 ni doble jornada
      expect(balance.conflicts.single.date, monday);

      final summary = buildMonthlySummary(
        year: 2026,
        month: 6,
        calculator: calcToday,
        records: records,
      );
      expect(summary.conflictDays.single.date, monday);
      expect(summary.workedMinutes, 0);
      expect(summary.missingDays.map((d) => d.date), isNot(contains(monday)));
    });
  });

  test('01/06: un día con usufructo no cuenta además como deuda', () {
    final usufruct = BankMovement.usufruct(
      date: monday,
      scope: UsufructScope.full,
      minutes: 480,
      gdeDocumentTypeCode: 'FSOLI',
    );

    final day = calc.calculate(monday, movements: [usufruct]);
    expect(day.status, DayStatus.usufruct);
    expect(day.debtMinutes, 0);
    expect(day.bankDeltaMinutes, -480); // no -960

    final summary = buildMonthlySummary(
      year: 2026,
      month: 6,
      calculator: calcToday,
      movements: [usufruct],
    );
    expect(summary.debtMinutes, 0);
    expect(summary.bankDeltaMinutes, -480);
    expect(summary.missingDays.map((d) => d.date), isNot(contains(monday)));
  });

  test('01/06 con fichada casi vacía y usufructo completo: -8:00, no -16:00',
      () {
    // Variante: el día tiene una fichada que da deuda completa.
    final day = calc.calculate(
      monday,
      records: [
        DailyRecord(
          date: monday,
          checkInMinutes: hm(8, 0),
          checkOutMinutes: hm(8, 1),
        ),
      ],
      movements: [
        BankMovement.usufruct(
          date: monday,
          scope: UsufructScope.full,
          minutes: 480,
        ),
      ],
    );
    expect(day.debtMinutes, 479);
    expect(day.coveredDebtMinutes, 479);
    expect(day.uncoveredDebtMinutes, 0);
    expect(formatMinutes(day.bankDeltaMinutes), '-8:00');
  });
}
