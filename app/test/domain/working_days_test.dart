import 'package:asistente/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Feriados ficticios (no son el calendario oficial).
  final fixed = Holiday(
    date: CalendarDate(2026, 7, 9),
    name: 'Feriado ficticio A',
  );
  final bridge = Holiday(
    date: CalendarDate(2026, 7, 10),
    name: 'Puente ficticio',
    kind: HolidayKind.nonWorking,
  );
  final onSaturday = Holiday(
    date: CalendarDate(2026, 8, 15),
    name: 'Feriado ficticio en sábado',
    kind: HolidayKind.movable,
  );
  final holidays = [fixed, bridge, onSaturday];

  group('nonWorkingDayFor', () {
    test('día hábil: null', () {
      expect(nonWorkingDayFor(CalendarDate(2026, 7, 8), holidays), isNull);
    });

    test('sábado y domingo no son laborables', () {
      final sat = nonWorkingDayFor(CalendarDate(2026, 7, 11), holidays)!;
      expect(sat.isWeekend, isTrue);
      expect(sat.isHoliday, isFalse);
      final sun = nonWorkingDayFor(CalendarDate(2026, 7, 12), holidays)!;
      expect(sun.isWeekend, isTrue);
    });

    test('feriado y no laborable turístico no son laborables', () {
      expect(
        nonWorkingDayFor(CalendarDate(2026, 7, 9), holidays)!.holiday,
        fixed,
      );
      expect(
        nonWorkingDayFor(CalendarDate(2026, 7, 10), holidays)!.holiday!.kind,
        HolidayKind.nonWorking,
      );
    });

    test('un feriado en sábado se informa como feriado', () {
      final d = nonWorkingDayFor(CalendarDate(2026, 8, 15), holidays)!;
      expect(d.isHoliday, isTrue);
      expect(d.isWeekend, isTrue);
      expect(d.holiday, onSaturday);
    });
  });

  group('nextHoliday', () {
    test('el primero igual o posterior a la fecha', () {
      expect(nextHoliday(holidays, CalendarDate(2026, 7, 1)), fixed);
      expect(nextHoliday(holidays, CalendarDate(2026, 7, 9)), fixed);
      expect(nextHoliday(holidays, CalendarDate(2026, 7, 11)), onSaturday);
    });

    test('sin feriados posteriores: null', () {
      expect(nextHoliday(holidays, CalendarDate(2026, 12, 1)), isNull);
      expect(nextHoliday(const [], CalendarDate(2026, 1, 1)), isNull);
    });
  });

  group('HolidayKind', () {
    test('valores de la base', () {
      expect(HolidayKind.fromDbValue('inamovible'), HolidayKind.fixed);
      expect(HolidayKind.fromDbValue('trasladable'), HolidayKind.movable);
      expect(HolidayKind.fromDbValue('no_laborable'), HolidayKind.nonWorking);
      expect(HolidayKind.fromDbValue(null), HolidayKind.fixed);
    });
  });
}
