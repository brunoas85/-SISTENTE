import 'package:asistente/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

int hm(int h, int m) => h * 60 + m;

void main() {
  DailyRecord rec(CalendarDate d, int inMin, [int? outMin]) =>
      DailyRecord(date: d, checkInMinutes: inMin, checkOutMinutes: outMin);

  // Junio 2026: el 1 es lunes, tiene 22 días hábiles sin feriados.
  final fakeHoliday = Holiday(
    date: CalendarDate(2026, 6, 15),
    name: 'Feriado ficticio',
  );

  group('buildMonthlySummary', () {
    test('mes vacío: todos los días hábiles son faltantes y restan', () {
      final s = buildMonthlySummary(
        year: 2026,
        month: 6,
        calculator: DayCalculator(),
      );
      expect(s.days.length, 30);
      expect(s.businessDayCount, 22);
      expect(s.missingDays.length, 22);
      expect(s.debtMinutes, 22 * 480);
      expect(s.bankDeltaMinutes, -22 * 480);
    });

    test('los feriados recibidos por parámetro no son faltantes', () {
      final s = buildMonthlySummary(
        year: 2026,
        month: 6,
        calculator: DayCalculator(holidays: [fakeHoliday]),
      );
      expect(s.businessDayCount, 21);
      expect(s.missingDays.length, 21);
      expect(
        s.missingDays.map((d) => d.date),
        isNot(contains(CalendarDate(2026, 6, 15))),
      );
      expect(s.bankDeltaMinutes, -21 * 480);
    });

    test('un día no laborable (feriado puente) por parámetro no es hábil', () {
      // Viernes 12/06 ficticio como día no laborable, junto al feriado.
      final bridge = Holiday(
        date: CalendarDate(2026, 6, 12),
        name: 'Día no laborable ficticio',
      );
      final s = buildMonthlySummary(
        year: 2026,
        month: 6,
        calculator: DayCalculator(holidays: [fakeHoliday, bridge]),
      );
      final friday = s.days.firstWhere((d) => d.date.day == 12);
      expect(friday.isBusinessDay, isFalse);
      expect(friday.status, DayStatus.nonWorkingDay);
      expect(friday.bankDeltaMinutes, 0);
      expect(s.businessDayCount, 20);
      expect(s.bankDeltaMinutes, -20 * 480);
    });

    test('filtra por año + mes, no solo por nombre del mes', () {
      final s = buildMonthlySummary(
        year: 2026,
        month: 6,
        calculator: DayCalculator(),
        records: [
          rec(CalendarDate(2025, 6, 2), hm(7, 0), hm(17, 0)), // otro año
          rec(CalendarDate(2026, 6, 2), hm(7, 0), hm(16, 0)),
        ],
        movements: [
          BankMovement.accumulation(
            date: CalendarDate(2025, 6, 7),
            minutes: 600,
          ),
        ],
      );
      expect(s.creditMinutes, 60);
      expect(s.accumulationMinutes, 0);
      expect(s.missingDays.length, 21);
      expect(s.bankDeltaMinutes, 60 - 21 * 480);
    });

    test('totales del mes y un estado por día', () {
      final s = buildMonthlySummary(
        year: 2026,
        month: 6,
        calculator: DayCalculator(
          holidays: [fakeHoliday],
          today: CalendarDate(2026, 6, 10),
        ),
        records: [
          rec(CalendarDate(2026, 6, 1), hm(8, 0), hm(17, 0)), // +60
          rec(CalendarDate(2026, 6, 2), hm(8, 0), hm(15, 0)), // deuda 60
          rec(CalendarDate(2026, 6, 3), hm(8, 0)), // abierto
          rec(
            CalendarDate(2026, 6, 6),
            hm(9, 0),
            hm(12, 0),
          ), // sábado: no computa
        ],
        movements: [
          BankMovement.usufruct(
            date: CalendarDate(2026, 6, 5),
            scope: UsufructScope.full,
            minutes: 480,
          ),
        ],
      );
      DayStatus st(int day) =>
          s.days.firstWhere((d) => d.date.day == day).status;
      expect(st(1), DayStatus.worked);
      expect(st(2), DayStatus.worked);
      expect(st(3), DayStatus.open);
      expect(st(4), DayStatus.missing);
      expect(st(5), DayStatus.usufruct);
      expect(st(6), DayStatus.nonWorkingDayRecords);
      expect(st(7), DayStatus.nonWorkingDay);
      expect(st(8), DayStatus.missing);
      expect(st(10), DayStatus.today); // hoy: todavía no es faltante
      expect(st(11), DayStatus.future);
      expect(st(15), DayStatus.nonWorkingDay);

      expect(s.workedMinutes, 540 + 420);
      expect(s.creditMinutes, 60);
      expect(s.missingDays.map((d) => d.date.day), [4, 8, 9]);
      expect(s.debtMinutes, 60 + 3 * 480);
      expect(s.uncoveredDebtMinutes, 60 + 3 * 480);
      expect(s.activeUsufructMinutes, 480);
      expect(s.bankDeltaMinutes, 60 - (60 + 3 * 480) - 480);
      expect(s.openDays.single.date.day, 3);
      expect(s.daysNeedingReview.map((d) => d.date.day), [6]);
    });
    group('bankUntil', () {
      // Septiembre 2026, hoy jueves 24. Datos ficticios.
      final hoy = CalendarDate(2026, 9, 24);
      final calc = DayCalculator(
        today: hoy,
        controlStart: CalendarDate(2026, 9, 1),
      );
      final records = [
        for (
          var d = CalendarDate(2026, 9, 1);
          !d.isAfter(hoy);
          d = d.addDays(1)
        )
          if (!d.isWeekend) rec(d, hm(8, 0), hm(16, 30)),
      ];
      final futuro = BankMovement.usufruct(
        date: CalendarDate(2026, 9, 28),
        scope: UsufructScope.full,
        minutes: 480,
      );

      test('corta la variación del banco en hoy y deja todos los días', () {
        final s = buildMonthlySummary(
          year: 2026,
          month: 9,
          calculator: calc,
          records: records,
          movements: [futuro],
          bankUntil: hoy,
        );
        expect(s.days.length, 30);
        // 18 días hábiles del 1 al 24, cada uno +0:30.
        expect(s.creditMinutes, 18 * 30);
        expect(s.activeUsufructMinutes, 0);
        expect(s.bankDeltaMinutes, 18 * 30);
        // El día del usufructo futuro se ve igual con su estado.
        final d28 = s.days.firstWhere((d) => d.date == futuro.date);
        expect(d28.status, DayStatus.usufruct);
      });

      test('sin bankUntil, el usufructo futuro resta en el mes', () {
        final s = buildMonthlySummary(
          year: 2026,
          month: 9,
          calculator: calc,
          records: records,
          movements: [futuro],
        );
        expect(s.bankDeltaMinutes, 18 * 30 - 480);
      });

      test('un mes posterior a bankUntil no mueve el banco', () {
        final s = buildMonthlySummary(
          year: 2026,
          month: 10,
          calculator: calc,
          movements: [
            BankMovement.usufruct(
              date: CalendarDate(2026, 10, 5),
              scope: UsufructScope.full,
              minutes: 480,
            ),
          ],
          bankUntil: hoy,
        );
        expect(s.bankDeltaMinutes, 0);
        expect(s.days.length, 31);
        expect(s.missingDays, isEmpty);
      });

      test('un mes anterior a bankUntil se calcula completo', () {
        final s = buildMonthlySummary(
          year: 2026,
          month: 8,
          calculator: DayCalculator(today: hoy),
          bankUntil: hoy,
        );
        expect(s.missingDays.length, 21);
        expect(s.bankDeltaMinutes, -21 * 480);
      });
    });
  });
}
