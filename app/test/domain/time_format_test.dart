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
}
