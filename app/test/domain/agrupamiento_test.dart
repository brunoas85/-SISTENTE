import 'package:asistente/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// Horas del día en minutos (datos ficticios).
int hm(int h, int m) => h * 60 + m;

void main() {
  // 01/06/2026 es lunes.
  final monday = CalendarDate(2026, 6, 1);

  DailyRecord rec(CalendarDate d, int inMin, int outMin) =>
      DailyRecord(date: d, checkInMinutes: inMin, checkOutMinutes: outMin);

  group('Agrupamiento', () {
    test('jornada: administrativo 8 h, guardaparque y de apoyo 7 h', () {
      expect(Agrupamiento.administrativo.workdayMinutes, 480);
      expect(Agrupamiento.guardaparque.workdayMinutes, 420);
      expect(Agrupamiento.guardaparqueApoyo.workdayMinutes, 420);
    });

    test('sin agrupamiento elegido la jornada es 480', () {
      expect(workdayMinutesForAgrupamiento(null), 480);
    });

    test('valores de la base', () {
      expect(Agrupamiento.values.map((a) => a.dbValue), [
        'administrativo',
        'guardaparque',
        'guardaparque_apoyo',
      ]);
      expect(
        Agrupamiento.fromDbValue('guardaparque_apoyo'),
        Agrupamiento.guardaparqueApoyo,
      );
      expect(Agrupamiento.fromDbValue(null), isNull);
      expect(Agrupamiento.fromDbValue('otro'), isNull);
    });
  });

  group('Resolver con agrupamiento', () {
    test('sin vigencias usa la jornada del agrupamiento', () {
      final r = WorkdayScheduleResolver(
        const [],
        agrupamiento: Agrupamiento.guardaparque,
      );
      expect(r.minutesFor(monday), 420);
      expect(
        workdayMinutesFor(
          monday,
          const [],
          agrupamiento: Agrupamiento.administrativo,
        ),
        480,
      );
    });

    test('una vigencia en jornadas tiene prioridad sobre el agrupamiento', () {
      final r = WorkdayScheduleResolver([
        WorkdaySchedule(validFrom: CalendarDate(2026, 7, 1), minutes: 360),
      ], agrupamiento: Agrupamiento.guardaparqueApoyo);
      expect(r.minutesFor(CalendarDate(2026, 6, 30)), 420);
      expect(r.minutesFor(CalendarDate(2026, 7, 1)), 360);
    });

    test('un default explícito reemplaza al del agrupamiento', () {
      final r = WorkdayScheduleResolver(
        const [],
        agrupamiento: Agrupamiento.guardaparque,
        defaultMinutes: 450,
      );
      expect(r.minutesFor(monday), 450);
    });
  });

  group('DayCalculator con jornada de 7 h', () {
    final calc = DayCalculator(agrupamiento: Agrupamiento.guardaparque);

    test('7 h exactas: ni a favor ni deuda', () {
      final d = calc.calculate(
        monday,
        records: [rec(monday, hm(8, 0), hm(15, 0))],
      );
      expect(d.workdayMinutes, 420);
      expect(d.workedMinutes, 420);
      expect(d.creditMinutes, 0);
      expect(d.debtMinutes, 0);
      expect(d.bankDeltaMinutes, 0);
    });

    test('un minuto de más: 1 min a favor', () {
      final d = calc.calculate(
        monday,
        records: [rec(monday, hm(8, 0), hm(15, 1))],
      );
      expect(d.creditMinutes, 1);
      expect(d.debtMinutes, 0);
    });

    test('un minuto de menos: 1 min de deuda', () {
      final d = calc.calculate(
        monday,
        records: [rec(monday, hm(8, 0), hm(14, 59))],
      );
      expect(d.creditMinutes, 0);
      expect(d.debtMinutes, 1);
      expect(d.bankDeltaMinutes, -1);
    });

    test('8 h con jornada de 7 h: 1:00 a favor', () {
      final d = calc.calculate(
        monday,
        records: [rec(monday, hm(8, 0), hm(16, 0))],
      );
      expect(d.creditMinutes, 60);
    });

    test('día faltante resta la jornada de 7 h', () {
      final c = DayCalculator(
        agrupamiento: Agrupamiento.guardaparqueApoyo,
        today: CalendarDate(2026, 6, 3),
      );
      final d = c.calculate(monday);
      expect(d.status, DayStatus.missing);
      expect(d.debtMinutes, 420);
    });

    test('hoy: la deuda provisoria usa la jornada de 7 h', () {
      final c = DayCalculator(
        agrupamiento: Agrupamiento.guardaparque,
        today: monday,
      );
      final d = c.calculate(
        monday,
        records: [rec(monday, hm(8, 0), hm(12, 0))],
      );
      expect(d.provisionalDebtMinutes, 180);
      expect(d.debtMinutes, 0);
    });

    test('administrativo: 8 h exactas sin a favor ni deuda', () {
      final c = DayCalculator(agrupamiento: Agrupamiento.administrativo);
      final d = c.calculate(
        monday,
        records: [rec(monday, hm(8, 0), hm(16, 0))],
      );
      expect(d.creditMinutes, 0);
      expect(d.debtMinutes, 0);
    });
  });
}
