import 'package:asistente/domain/calendar_date.dart';
import 'package:asistente/domain/models.dart';
import 'package:asistente/domain/workday_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Jornada vigente', () {
    test('sin vigencias usa 480 min por defecto', () {
      expect(workdayMinutesFor(CalendarDate(2026, 6, 1), const []), 480);
    });

    test('toma la última vigencia con inicio <= fecha', () {
      final schedules = [
        WorkdaySchedule(validFrom: CalendarDate(2026, 7, 1), minutes: 420),
        WorkdaySchedule(validFrom: CalendarDate(2026, 1, 1), minutes: 480),
        WorkdaySchedule(validFrom: CalendarDate(2026, 10, 1), minutes: 360),
      ];
      final resolver = WorkdayScheduleResolver(schedules);
      expect(resolver.minutesFor(CalendarDate(2025, 12, 31)), 480); // defecto
      expect(resolver.minutesFor(CalendarDate(2026, 6, 30)), 480);
      expect(resolver.minutesFor(CalendarDate(2026, 7, 1)), 420); // inclusive
      expect(resolver.minutesFor(CalendarDate(2026, 9, 30)), 420);
      expect(resolver.minutesFor(CalendarDate(2026, 10, 1)), 360);
      expect(resolver.minutesFor(CalendarDate(2030, 1, 1)), 360);
    });

    test('antes de la primera vigencia usa el valor por defecto configurado',
        () {
      final resolver = WorkdayScheduleResolver(
        [WorkdaySchedule(validFrom: CalendarDate(2026, 7, 1), minutes: 420)],
        defaultMinutes: 450,
      );
      expect(resolver.minutesFor(CalendarDate(2026, 6, 30)), 450);
    });

    test('dos vigencias distintas el mismo día es un error', () {
      expect(
        () => WorkdayScheduleResolver([
          WorkdaySchedule(validFrom: CalendarDate(2026, 7, 1), minutes: 420),
          WorkdaySchedule(validFrom: CalendarDate(2026, 7, 1), minutes: 480),
        ]),
        throwsArgumentError,
      );
    });

    test('una vigencia repetida idéntica no es error', () {
      final resolver = WorkdayScheduleResolver([
        WorkdaySchedule(validFrom: CalendarDate(2026, 7, 1), minutes: 420),
        WorkdaySchedule(validFrom: CalendarDate(2026, 7, 1), minutes: 420),
      ]);
      expect(resolver.minutesFor(CalendarDate(2026, 7, 2)), 420);
    });
  });
}
