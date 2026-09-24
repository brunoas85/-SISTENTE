import 'package:asistente/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

int hm(int h, int m) => h * 60 + m;

void main() {
  final calc = DayCalculator();
  DailyRecord rec(CalendarDate d, int inMin, [int? outMin]) =>
      DailyRecord(date: d, checkInMinutes: inMin, checkOutMinutes: outMin);

  group('calculateBankBalance', () {
    test('sin datos el saldo es 0', () {
      final b = calculateBankBalance(calculator: calc);
      expect(b.balanceMinutes, 0);
      expect(b.days, isEmpty);
    });

    test(
      'Σ a favor + Σ acumulación - Σ deuda no cubierta - Σ usufructo vigente',
      () {
        final b = calculateBankBalance(
          calculator: calc,
          records: [
            rec(CalendarDate(2026, 6, 1), hm(7, 0), hm(17, 0)), // +120
            rec(CalendarDate(2026, 6, 2), hm(8, 0), hm(15, 30)), // deuda 30
            rec(CalendarDate(2026, 6, 3), hm(8, 0), hm(14, 0)), // deuda 120
            rec(CalendarDate(2026, 6, 4), hm(8, 0), hm(16, 0)), // 0
            rec(CalendarDate(2026, 6, 5), hm(8, 0), hm(16, 0)), // 0
          ],
          movements: [
            BankMovement.accumulation(
              date: CalendarDate(2026, 6, 6),
              minutes: 240,
            ),
            BankMovement.usufruct(
              date: CalendarDate(2026, 6, 3),
              scope: UsufructScope.partial,
              minutes: 120,
            ),
          ],
        );
        expect(b.creditMinutes, 120);
        expect(b.accumulationMinutes, 240);
        expect(b.uncoveredDebtMinutes, 30);
        expect(b.activeUsufructMinutes, 120);
        expect(b.balanceMinutes, 120 + 240 - 30 - 120);
      },
    );

    test('movimientos perdidos (acumulación o usufructo) no computan', () {
      final b = calculateBankBalance(
        calculator: calc,
        movements: [
          BankMovement.accumulation(
            date: CalendarDate(2026, 6, 6),
            minutes: 480,
          ),
          BankMovement.accumulation(
            date: CalendarDate(2026, 6, 7),
            minutes: 300,
            status: MovementStatus.lost,
          ),
          BankMovement.usufruct(
            date: CalendarDate(2026, 6, 8),
            scope: UsufructScope.full,
            minutes: 480,
            status: MovementStatus.lost,
          ),
        ],
      );
      expect(b.accumulationMinutes, 480);
      expect(b.lostAccumulationMinutes, 300);
      expect(b.lostUsufructMinutes, 480);
      expect(b.activeUsufructMinutes, 0);
      // El usufructo perdido no cubre el lunes 08/06: queda faltante.
      expect(b.missingDays.single.date, CalendarDate(2026, 6, 8));
      expect(b.balanceMinutes, 480 - 480);
    });

    test('filtra por rango de fechas inclusive', () {
      final b = calculateBankBalance(
        calculator: calc,
        records: [
          rec(CalendarDate(2026, 5, 29), hm(7, 0), hm(17, 0)), // fuera
          rec(CalendarDate(2026, 6, 1), hm(7, 0), hm(16, 0)), // +60
          rec(CalendarDate(2026, 6, 2), hm(7, 0), hm(16, 0)), // +60
          rec(CalendarDate(2026, 6, 3), hm(7, 0), hm(17, 0)), // fuera
        ],
        from: CalendarDate(2026, 6, 1),
        to: CalendarDate(2026, 6, 2),
      );
      expect(b.days.map((d) => d.date), [
        CalendarDate(2026, 6, 1),
        CalendarDate(2026, 6, 2),
      ]);
      expect(b.balanceMinutes, 120);
    });

    test('los días hábiles faltantes del rango restan la jornada', () {
      // Lunes 01/06 a domingo 07/06: solo se fichó el lunes.
      final b = calculateBankBalance(
        calculator: calc,
        records: [rec(CalendarDate(2026, 6, 1), hm(8, 0), hm(16, 0))],
        from: CalendarDate(2026, 6, 1),
        to: CalendarDate(2026, 6, 7),
      );
      expect(b.days, hasLength(7));
      expect(b.missingDays.map((d) => d.date.day), [2, 3, 4, 5]);
      expect(b.uncoveredDebtMinutes, 4 * 480);
      expect(b.balanceMinutes, -1920);
      expect(formatMinutes(b.balanceMinutes), '-32:00');
    });

    test('sin rango: de la primera fecha con datos hasta hoy', () {
      final c = DayCalculator(today: CalendarDate(2026, 6, 3));
      final b = calculateBankBalance(
        calculator: c,
        records: [rec(CalendarDate(2026, 6, 1), hm(8, 0), hm(16, 0))],
        movements: [
          // Usufructo a futuro: se incluye y descuenta.
          BankMovement.usufruct(
            date: CalendarDate(2026, 6, 10),
            scope: UsufructScope.full,
            minutes: 480,
          ),
        ],
      );
      // 02/06 faltante; 03/06 es hoy (no resta todavía); del 04/06 al 09/06
      // no se recorren.
      expect(b.missingDays.map((d) => d.date.day), [2]);
      expect(b.days.map((d) => d.date.day), [1, 2, 3, 10]);
      expect(b.balanceMinutes, -480 - 480);
    });

    test('los días futuros del rango no restan', () {
      final c = DayCalculator(today: CalendarDate(2026, 6, 2));
      final b = calculateBankBalance(
        calculator: c,
        from: CalendarDate(2026, 6, 1),
        to: CalendarDate(2026, 6, 5),
      );
      // 01/06 faltante; 02/06 es hoy; del 03 al 05 son futuros.
      expect(b.missingDays.map((d) => d.date.day), [1]);
      expect(b.balanceMinutes, -480);
    });

    test('registro abierto no computa pero queda listado', () {
      final b = calculateBankBalance(
        calculator: calc,
        records: [rec(CalendarDate(2026, 6, 1), hm(8, 0))],
      );
      expect(b.balanceMinutes, 0);
      expect(b.openDays.single.date, CalendarDate(2026, 6, 1));
    });
  });
}
