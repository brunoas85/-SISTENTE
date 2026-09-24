import 'package:asistente/domain/time_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatMinutes', () {
    test('formatea valores positivos, cero y negativos', () {
      expect(formatMinutes(480), '8:00');
      expect(formatMinutes(0), '0:00');
      expect(formatMinutes(-1440), '-24:00');
      expect(formatMinutes(-30), '-0:30');
    });

    test('rellena los minutos con dos dígitos', () {
      expect(formatMinutes(65), '1:05');
      expect(formatMinutes(-353), '-5:53');
      expect(formatMinutes(59), '0:59');
    });

    test('no tiene tope de horas (nunca "#####")', () {
      expect(formatMinutes(6000), '100:00');
      expect(formatMinutes(-6001), '-100:01');
    });
  });

  group('parseHoursMinutes', () {
    test('acepta H:MM, HH:MM y horas enteras', () {
      expect(parseHoursMinutes('2:30'), 150);
      expect(parseHoursMinutes('08:00'), 480);
      expect(parseHoursMinutes(' 0:45 '), 45);
      expect(parseHoursMinutes('3'), 180);
      expect(parseHoursMinutes('24:00'), 1440);
    });

    test('rechaza vacío, negativos y formatos ambiguos', () {
      expect(parseHoursMinutes(''), isNull);
      expect(parseHoursMinutes('-1:00'), isNull);
      expect(parseHoursMinutes('2:75'), isNull);
      expect(parseHoursMinutes('1,5'), isNull);
      expect(parseHoursMinutes('2:5'), isNull);
      expect(parseHoursMinutes('abc'), isNull);
    });

    test('es la inversa de formatMinutes para valores positivos', () {
      for (final m in [1, 59, 60, 150, 480, 1439]) {
        expect(parseHoursMinutes(formatMinutes(m)), m);
      }
    });
  });
}
