import 'package:asistente/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('canUsufruct', () {
    test('alcanza el saldo', () {
      expect(canUsufruct(480, 480), isTrue);
      expect(canUsufruct(600, 120), isTrue);
    });

    test('no alcanza el saldo', () {
      expect(canUsufruct(479, 480), isFalse);
      expect(canUsufruct(0, 60), isFalse);
      expect(canUsufruct(-120, 60), isFalse);
    });

    test('minutos no positivos no se pueden usufructuar', () {
      expect(canUsufruct(480, 0), isFalse);
    });
  });

  group('validateUsufruct', () {
    test('ok con saldo suficiente', () {
      final v = validateUsufruct(
        balanceBeforeMinutes: 600,
        minutes: 480,
        scope: UsufructScope.full,
        workdayMinutes: 480,
      );
      expect(v.isOk, isTrue);
      expect(v.status, UsufructValidationStatus.ok);
      expect(v.availableMinutes, 600);
    });

    test('saldo insuficiente informa el saldo disponible', () {
      final v = validateUsufruct(
        balanceBeforeMinutes: 90,
        minutes: 120,
        scope: UsufructScope.partial,
        workdayMinutes: 480,
      );
      expect(v.isOk, isFalse);
      expect(v.status, UsufructValidationStatus.insufficientBalance);
      expect(v.availableMinutes, 90);
      expect(v.requestedMinutes, 120);
      expect(v.expectedMinutes, isNull);
    });

    test('con saldo negativo por deuda no se puede usufructuar', () {
      final v = validateUsufruct(
        balanceBeforeMinutes: -1440,
        minutes: 60,
        scope: UsufructScope.partial,
        workdayMinutes: 480,
      );
      expect(v.status, UsufructValidationStatus.insufficientBalance);
      expect(formatMinutes(v.availableMinutes), '-24:00');
    });

    test('usufructo total distinto de la jornada vigente', () {
      final v = validateUsufruct(
        balanceBeforeMinutes: 2000,
        minutes: 480,
        scope: UsufructScope.full,
        workdayMinutes: 420,
      );
      expect(v.status, UsufructValidationStatus.fullDayMismatch);
      expect(v.expectedMinutes, 420);
    });

    test('minutos no positivos son inválidos', () {
      final v = validateUsufruct(
        balanceBeforeMinutes: 480,
        minutes: 0,
        scope: UsufructScope.partial,
        workdayMinutes: 480,
      );
      expect(v.status, UsufructValidationStatus.invalidMinutes);
    });
  });
}
