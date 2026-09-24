import 'package:asistente/domain/calendar_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarDate', () {
    test('rechaza fechas inexistentes', () {
      expect(() => CalendarDate(2026, 2, 29), throwsArgumentError);
      expect(() => CalendarDate(2026, 13, 1), throwsArgumentError);
      expect(CalendarDate(2028, 2, 29).day, 29);
    });

    test('igualdad, orden y hash', () {
      final a = CalendarDate(2026, 6, 1);
      expect(a, CalendarDate(2026, 6, 1));
      expect(a.hashCode, CalendarDate(2026, 6, 1).hashCode);
      expect(a.isBefore(CalendarDate(2026, 6, 2)), isTrue);
      expect(a.isAfter(CalendarDate(2026, 5, 31)), isTrue);
    });

    test('día de la semana y fin de semana', () {
      expect(CalendarDate(2026, 6, 1).weekday, DateTime.monday);
      expect(CalendarDate(2026, 6, 6).isWeekend, isTrue);
      expect(CalendarDate(2026, 6, 7).isWeekend, isTrue);
      expect(CalendarDate(2026, 6, 8).isWeekend, isFalse);
    });

    test('addDays cruza meses y años', () {
      expect(CalendarDate(2026, 1, 31).addDays(1), CalendarDate(2026, 2, 1));
      expect(CalendarDate(2026, 12, 31).addDays(1), CalendarDate(2027, 1, 1));
      expect(CalendarDate(2026, 3, 1).addDays(-1), CalendarDate(2026, 2, 28));
    });

    test('daysInMonth', () {
      expect(CalendarDate.daysInMonth(2026, 2), 28);
      expect(CalendarDate.daysInMonth(2028, 2), 29);
      expect(CalendarDate.daysInMonth(2026, 6), 30);
      expect(CalendarDate.daysInMonth(2026, 12), 31);
    });

    test('toString en ISO', () {
      expect(CalendarDate(2026, 6, 1).toString(), '2026-06-01');
    });
  });
}
