import 'package:asistente/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// Horas del día en minutos (datos ficticios).
int hm(int h, int m) => h * 60 + m;

void main() {
  // 01/06/2026 es lunes.
  final monday = CalendarDate(2026, 6, 1);
  final saturday = CalendarDate(2026, 6, 6);
  final holiday = CalendarDate(2026, 6, 15); // feriado ficticio
  final calc = DayCalculator(
    holidays: [Holiday(date: holiday, name: 'Feriado ficticio')],
  );

  DailyRecord rec(CalendarDate d, int inMin, [int? outMin]) =>
      DailyRecord(date: d, checkInMinutes: inMin, checkOutMinutes: outMin);

  group('workedMinutesOf', () {
    test('egreso - ingreso sin descuento de almuerzo', () {
      expect(workedMinutesOf(rec(monday, hm(8, 0), hm(16, 30))), 510);
    });

    test('sin egreso devuelve null', () {
      expect(workedMinutesOf(rec(monday, hm(8, 0))), isNull);
    });

    test('egreso anterior al ingreso devuelve null (nunca negativo)', () {
      expect(workedMinutesOf(rec(monday, hm(8, 0), hm(7, 0))), isNull);
      expect(workedMinutesOf(rec(monday, hm(8, 0), hm(8, 0))), isNull);
    });
  });

  group('DayCalculator.calculate', () {
    test('jornada exacta: sin deuda ni a favor', () {
      final d = calc.calculate(
        monday,
        records: [rec(monday, hm(8, 0), hm(16, 0))],
      );
      expect(d.status, DayStatus.worked);
      expect(d.workedMinutes, 480);
      expect(d.debtMinutes, 0);
      expect(d.creditMinutes, 0);
      expect(d.bankDeltaMinutes, 0);
    });

    test('trabajó de más: a favor', () {
      final d = calc.calculate(
        monday,
        records: [rec(monday, hm(7, 30), hm(17, 0))],
      );
      expect(d.workedMinutes, 570);
      expect(d.creditMinutes, 90);
      expect(d.debtMinutes, 0);
      expect(d.bankDeltaMinutes, 90);
    });

    test('trabajó de menos: deuda no cubierta', () {
      final d = calc.calculate(
        monday,
        records: [rec(monday, hm(8, 0), hm(15, 0))],
      );
      expect(d.debtMinutes, 60);
      expect(d.creditMinutes, 0);
      expect(d.uncoveredDebtMinutes, 60);
      expect(d.bankDeltaMinutes, -60);
    });

    test('usa la jornada vigente de la fecha', () {
      final c = DayCalculator(
        schedules: [
          WorkdaySchedule(validFrom: CalendarDate(2026, 6, 1), minutes: 420),
        ],
      );
      final d = c.calculate(
        monday,
        records: [rec(monday, hm(8, 0), hm(15, 0))],
      );
      expect(d.workdayMinutes, 420);
      expect(d.debtMinutes, 0);
    });

    test('usufructo parcial cubre solo esos minutos', () {
      // Salida temprana de 2 h con usufructo parcial de 1 h.
      final d = calc.calculate(
        monday,
        records: [rec(monday, hm(8, 0), hm(14, 0))],
        movements: [
          BankMovement.usufruct(
            date: monday,
            scope: UsufructScope.partial,
            minutes: 60,
          ),
        ],
      );
      expect(d.status, DayStatus.worked);
      expect(d.debtMinutes, 120);
      expect(d.coveredDebtMinutes, 60);
      expect(d.uncoveredDebtMinutes, 60);
      // -60 de deuda no cubierta y -60 del usufructo.
      expect(d.bankDeltaMinutes, -120);
    });

    test('usufructo parcial que cubre toda la deuda', () {
      final d = calc.calculate(
        monday,
        records: [rec(monday, hm(10, 0), hm(16, 0))],
        movements: [
          BankMovement.usufruct(
            date: monday,
            scope: UsufructScope.partial,
            minutes: 120,
          ),
        ],
      );
      expect(d.debtMinutes, 120);
      expect(d.coveredDebtMinutes, 120);
      expect(d.uncoveredDebtMinutes, 0);
      expect(d.bankDeltaMinutes, -120);
    });

    test('usufructo perdido no cubre la deuda ni descuenta', () {
      final d = calc.calculate(
        monday,
        records: [rec(monday, hm(8, 0), hm(14, 0))],
        movements: [
          BankMovement.usufruct(
            date: monday,
            scope: UsufructScope.partial,
            minutes: 120,
            status: MovementStatus.lost,
          ),
        ],
      );
      expect(d.coveredDebtMinutes, 0);
      expect(d.activeUsufructMinutes, 0);
      expect(d.lostUsufructMinutes, 120);
      expect(d.bankDeltaMinutes, -120); // solo la deuda
    });

    test('día hábil sin fichada es faltante y resta la jornada completa', () {
      final d = calc.calculate(monday);
      expect(d.status, DayStatus.missing);
      expect(d.debtMinutes, 480);
      expect(d.uncoveredDebtMinutes, 480);
      expect(d.bankDeltaMinutes, -480);
      expect(d.needsReview, isFalse);
    });

    test('faltante resta la jornada vigente de ese día', () {
      final c = DayCalculator(
        schedules: [
          WorkdaySchedule(validFrom: CalendarDate(2026, 6, 1), minutes: 420),
        ],
      );
      expect(c.calculate(monday).bankDeltaMinutes, -420);
    });

    test('usufructo total vigente cubre el día sin fichada: sin deuda', () {
      final d = calc.calculate(
        monday,
        movements: [
          BankMovement.usufruct(
            date: monday,
            scope: UsufructScope.full,
            minutes: 480,
          ),
        ],
      );
      expect(d.status, DayStatus.usufruct);
      expect(d.debtMinutes, 0);
      expect(d.bankDeltaMinutes, -480);
      expect(d.needsReview, isFalse);
    });

    test('usufructo perdido no cubre: el día sigue faltante', () {
      final d = calc.calculate(
        monday,
        movements: [
          BankMovement.usufruct(
            date: monday,
            scope: UsufructScope.full,
            minutes: 480,
            status: MovementStatus.lost,
          ),
        ],
      );
      expect(d.status, DayStatus.missing);
      expect(d.bankDeltaMinutes, -480);
      expect(d.lostUsufructMinutes, 480);
    });

    test(
      'usufructo parcial sin fichada cubre solo sus minutos y va a revisión',
      () {
        final d = calc.calculate(
          monday,
          movements: [
            BankMovement.usufruct(
              date: monday,
              scope: UsufructScope.partial,
              minutes: 120,
            ),
          ],
        );
        expect(d.status, DayStatus.missing);
        expect(d.debtMinutes, 480);
        expect(d.coveredDebtMinutes, 120);
        expect(d.uncoveredDebtMinutes, 360);
        expect(d.bankDeltaMinutes, -480); // -360 de deuda y -120 de usufructo
        expect(d.needsReview, isTrue);
      },
    );

    test('usufructo total distinto de la jornada queda para revisar', () {
      final d = calc.calculate(
        monday,
        movements: [
          BankMovement.usufruct(
            date: monday,
            scope: UsufructScope.full,
            minutes: 420,
          ),
        ],
      );
      expect(d.fullUsufructMismatch, isTrue);
      expect(d.needsReview, isTrue);
      // No se corrige en silencio: se computa lo cargado.
      expect(d.activeUsufructMinutes, 420);
    });

    test('usufructo total igual a la jornada vigente (no 480) es válido', () {
      final c = DayCalculator(
        schedules: [
          WorkdaySchedule(validFrom: CalendarDate(2026, 6, 1), minutes: 420),
        ],
      );
      final d = c.calculate(
        monday,
        movements: [
          BankMovement.usufruct(
            date: monday,
            scope: UsufructScope.full,
            minutes: 420,
          ),
        ],
      );
      expect(d.status, DayStatus.usufruct);
      expect(d.fullUsufructMismatch, isFalse);
      expect(d.needsReview, isFalse);
    });

    test('usufructo total perdido distinto de la jornada no se marca', () {
      final d = calc.calculate(
        monday,
        records: [rec(monday, hm(8, 0), hm(16, 0))],
        movements: [
          BankMovement.usufruct(
            date: monday,
            scope: UsufructScope.full,
            minutes: 300,
            status: MovementStatus.lost,
          ),
        ],
      );
      expect(d.fullUsufructMismatch, isFalse);
      expect(d.needsReview, isFalse);
    });

    test('acumulación perdida no suma', () {
      final d = calc.calculate(
        saturday,
        movements: [
          BankMovement.accumulation(date: saturday, minutes: 240),
          BankMovement.accumulation(
            date: saturday,
            minutes: 120,
            status: MovementStatus.lost,
          ),
        ],
      );
      expect(d.accumulationMinutes, 240);
      expect(d.lostAccumulationMinutes, 120);
      expect(d.bankDeltaMinutes, 240);
    });

    test('fin de semana y feriado sin fichada no son faltantes ni restan', () {
      expect(calc.calculate(saturday).status, DayStatus.nonWorkingDay);
      expect(calc.calculate(saturday).bankDeltaMinutes, 0);
      expect(calc.calculate(holiday).status, DayStatus.nonWorkingDay);
      expect(calc.calculate(holiday).bankDeltaMinutes, 0);
      expect(calc.isBusinessDay(holiday), isFalse);
    });

    test('día hábil futuro sin fichada no es faltante ni resta', () {
      final c = DayCalculator(today: CalendarDate(2026, 5, 29));
      final d = c.calculate(monday);
      expect(d.status, DayStatus.future);
      expect(d.debtMinutes, 0);
      expect(d.bankDeltaMinutes, 0);
    });

    group('firstOverlapping', () {
      final a = DailyRecord(
        id: 'a',
        date: monday,
        checkInMinutes: hm(8, 0),
        checkOutMinutes: hm(12, 0),
      );

      test('devuelve el tramo con el que choca', () {
        final nuevo = DailyRecord(date: monday, checkInMinutes: hm(11, 0));
        expect(firstOverlapping(nuevo, [a]), a);
      });

      test('tramos que solo se tocan no chocan', () {
        final nuevo = DailyRecord(date: monday, checkInMinutes: hm(12, 0));
        expect(firstOverlapping(nuevo, [a]), isNull);
      });

      test('un ingreso abierto antes de un tramo posterior choca', () {
        final nuevo = DailyRecord(date: monday, checkInMinutes: hm(7, 0));
        expect(firstOverlapping(nuevo, [a]), a);
      });

      test('ignora el mismo tramo y los de otra fecha', () {
        final editado = DailyRecord(
          id: 'a',
          date: monday,
          checkInMinutes: hm(8, 0),
          checkOutMinutes: hm(13, 0),
        );
        final otroDia = DailyRecord(
          date: monday.addDays(1),
          checkInMinutes: hm(8, 0),
          checkOutMinutes: hm(12, 0),
        );
        expect(firstOverlapping(editado, [a, otroDia]), isNull);
      });
    });

    group('el día de hoy no resta hasta que termina', () {
      final c = DayCalculator(today: monday);

      test('sin fichada: estado today, sin deuda ni faltante', () {
        final d = c.calculate(monday);
        expect(d.status, DayStatus.today);
        expect(d.debtMinutes, 0);
        expect(d.provisionalDebtMinutes, 0);
        expect(d.bankDeltaMinutes, 0);
        expect(d.needsReview, isFalse);
      });

      test('ayer sin fichada sí es faltante', () {
        final c2 = DayCalculator(today: monday.addDays(1));
        expect(c2.calculate(monday).status, DayStatus.missing);
        expect(c2.calculate(monday).bankDeltaMinutes, -480);
      });

      test(
        'con tramos cerrados que no llegan a la jornada: la deuda no resta',
        () {
          final d = c.calculate(
            monday,
            records: [rec(monday, hm(8, 0), hm(12, 0))],
          );
          expect(d.status, DayStatus.worked);
          expect(d.workedMinutes, 240);
          expect(d.debtMinutes, 0);
          expect(d.provisionalDebtMinutes, 240);
          expect(d.bankDeltaMinutes, 0);
        },
      );

      test('lo a favor de hoy sí computa', () {
        final d = c.calculate(
          monday,
          records: [rec(monday, hm(7, 0), hm(16, 30))],
        );
        expect(d.creditMinutes, 90);
        expect(d.provisionalDebtMinutes, 0);
        expect(d.bankDeltaMinutes, 90);
      });

      test('un usufructo de hoy descuenta igual (como a futuro)', () {
        final d = c.calculate(
          monday,
          movements: [
            BankMovement.usufruct(
              date: monday,
              scope: UsufructScope.partial,
              minutes: 120,
            ),
          ],
        );
        expect(d.status, DayStatus.usufruct);
        expect(d.debtMinutes, 0);
        expect(d.bankDeltaMinutes, -120);
      });

      test('el saldo hasta hoy no incluye la deuda de hoy', () {
        final b = calculateBankBalance(
          calculator: c,
          records: [rec(monday, hm(8, 0), hm(10, 0))],
        );
        expect(b.balanceMinutes, 0);
        expect(b.missingDays, isEmpty);
      });
    });

    test('fichada en fin de semana: todo lo trabajado es a favor', () {
      final d = calc.calculate(
        saturday,
        records: [rec(saturday, hm(9, 0), hm(13, 0))],
      );
      expect(d.status, DayStatus.worked);
      expect(d.isBusinessDay, isFalse);
      expect(d.workedMinutes, 240);
      expect(d.debtMinutes, 0);
      expect(d.creditMinutes, 240);
      expect(d.bankDeltaMinutes, 240);
      expect(d.needsReview, isFalse);
    });

    test('fichada en feriado: todo lo trabajado es a favor, sin deuda', () {
      final d = calc.calculate(
        holiday,
        records: [rec(holiday, hm(10, 0), hm(12, 0))],
      );
      expect(d.status, DayStatus.worked);
      expect(d.creditMinutes, 120);
      expect(d.debtMinutes, 0);
      expect(d.needsReview, isFalse);
    });

    test('egreso anterior al ingreso es inválido y no computa', () {
      final d = calc.calculate(
        monday,
        records: [rec(monday, hm(16, 0), hm(8, 0))],
      );
      expect(d.status, DayStatus.invalid);
      expect(d.workedMinutes, isNull);
      expect(d.bankDeltaMinutes, 0);
      expect(d.needsReview, isTrue);
    });

    test('egreso inválido en uno de varios tramos invalida el día', () {
      final d = calc.calculate(
        monday,
        records: [
          rec(monday, hm(8, 0), hm(12, 0)),
          rec(monday, hm(14, 0), hm(13, 0)),
        ],
      );
      expect(d.status, DayStatus.invalid);
      expect(d.bankDeltaMinutes, 0);
    });

    test('ignora registros y movimientos de otras fechas', () {
      final tuesday = monday.addDays(1);
      final d = calc.calculate(
        monday,
        records: [rec(tuesday, hm(8, 0), hm(16, 0))],
        movements: [BankMovement.accumulation(date: tuesday, minutes: 60)],
      );
      expect(d.status, DayStatus.missing);
      expect(d.accumulationMinutes, 0);
    });
  });

  group('varios tramos por día', () {
    test('tramos que no se superponen se suman', () {
      final d = calc.calculate(
        monday,
        records: [
          rec(monday, hm(13, 0), hm(17, 30)),
          rec(monday, hm(7, 30), hm(12, 0)),
        ],
      );
      expect(d.status, DayStatus.worked);
      expect(d.workedMinutes, 270 + 270);
      expect(d.creditMinutes, 60);
      expect(d.records, hasLength(2));
    });

    test('tramos que solo se tocan no se superponen', () {
      final d = calc.calculate(
        monday,
        records: [
          rec(monday, hm(8, 0), hm(12, 0)),
          rec(monday, hm(12, 0), hm(16, 0)),
        ],
      );
      expect(d.status, DayStatus.worked);
      expect(d.workedMinutes, 480);
    });

    test('tramos superpuestos: conflicto, no computa y va a revisión', () {
      final d = calc.calculate(
        monday,
        records: [
          rec(monday, hm(8, 0), hm(12, 0)),
          rec(monday, hm(11, 0), hm(16, 0)),
        ],
      );
      expect(d.status, DayStatus.conflict);
      expect(d.workedMinutes, isNull);
      expect(d.bankDeltaMinutes, 0);
      expect(d.needsReview, isTrue);
    });

    test('un tramo abierto deja el día abierto', () {
      final d = calc.calculate(
        monday,
        records: [rec(monday, hm(8, 0), hm(12, 0)), rec(monday, hm(13, 0))],
      );
      expect(d.status, DayStatus.open);
      expect(d.workedMinutes, isNull);
      expect(d.bankDeltaMinutes, 0);
      expect(d.needsReview, isFalse);
    });

    test('un tramo abierto que empieza dentro de otro es conflicto', () {
      final d = calc.calculate(
        monday,
        records: [rec(monday, hm(8, 0), hm(12, 0)), rec(monday, hm(10, 0))],
      );
      expect(d.status, DayStatus.conflict);
    });

    test('recordsOverlap', () {
      expect(recordsOverlap([]), isFalse);
      expect(recordsOverlap([rec(monday, hm(8, 0))]), isFalse);
      expect(
        recordsOverlap([rec(monday, hm(8, 0)), rec(monday, hm(9, 0))]),
        isTrue,
      );
    });
  });
  group('inicio del control (primera fichada con la app)', () {
    final tuesday = CalendarDate(2026, 6, 2);
    final records = [rec(tuesday, hm(8, 0), hm(16, 0))];
    final c = DayCalculator(controlStart: controlStartFrom(records));

    test('controlStartFrom devuelve la primera fecha fichada', () {
      expect(controlStartFrom(records), tuesday);
      expect(controlStartFrom(const []), isNull);
    });

    test(
      'día hábil anterior al inicio sin fichada no es faltante ni resta',
      () {
        final d = c.calculate(monday);
        expect(d.status, DayStatus.beforeControl);
        expect(d.debtMinutes, 0);
        expect(d.bankDeltaMinutes, 0);
      },
    );

    test('desde el inicio, un día hábil sin fichada es faltante', () {
      final d = c.calculate(CalendarDate(2026, 6, 3));
      expect(d.status, DayStatus.missing);
      expect(d.bankDeltaMinutes, -480);
    });

    test('el resumen mensual no resta los días anteriores al inicio', () {
      final s = buildMonthlySummary(
        year: 2026,
        month: 6,
        calculator: DayCalculator(
          controlStart: tuesday,
          today: CalendarDate(2026, 6, 4),
        ),
        records: records,
      );
      // 01/06 antes del inicio, 02/06 jornada exacta, 03/06 faltante y
      // 04/06 es hoy (todavía no es faltante).
      expect(s.missingDays.map((d) => d.date), [CalendarDate(2026, 6, 3)]);
      expect(s.bankDeltaMinutes, -480);
    });
  });
}
