import 'package:asistente/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

int hm(int h, int m) => h * 60 + m;

void main() {
  DailyRecord rec(CalendarDate d, int inMin, [int? outMin]) =>
      DailyRecord(date: d, checkInMinutes: inMin, checkOutMinutes: outMin);

  // Semana ficticia: lunes 21/09/2026 … viernes 25/09/2026. Hoy: jueves 24.
  final lunes = CalendarDate(2026, 9, 21);
  final martes = CalendarDate(2026, 9, 22);
  final miercoles = CalendarDate(2026, 9, 23);
  final hoy = CalendarDate(2026, 9, 24);
  final viernes = CalendarDate(2026, 9, 25);
  final sabado = CalendarDate(2026, 9, 26);
  final lunesQueViene = CalendarDate(2026, 9, 28);

  group('bankControlStart', () {
    test('es la primera fichada', () {
      expect(bankControlStart([rec(martes, hm(8, 0), hm(16, 0))], hoy), martes);
    });

    test('sin fichadas es hoy (los días anteriores no son faltantes)', () {
      expect(bankControlStart(const [], hoy), hoy);
    });
  });

  group('calculateBankStatus', () {
    test('sin fichadas el control no empezó: saldo 0 y los movimientos '
        'quedan para revisar', () {
      final calc = buildBankCalculator(today: hoy);
      final acumulacion = BankMovement.accumulation(
        date: CalendarDate(2026, 9, 5),
        minutes: 240,
      );
      final s = calculateBankStatus(
        calculator: calc,
        movements: [
          acumulacion,
          BankMovement.usufruct(
            date: lunesQueViene,
            scope: UsufructScope.partial,
            minutes: 60,
          ),
        ],
      );
      expect(s.balanceMinutes, 0);
      expect(s.futureUsufructMinutes, 0);
      expect(s.availableMinutes, 0);
      // Sin fichadas el inicio es hoy: ningún día anterior es faltante.
      expect(s.current.missingDays, isEmpty);
      expect(s.current.movementsOutsideControl, [acumulacion]);
      expect(calc.countsMovementsOn(hoy), isFalse);
      expect(calc.countsMovementsOn(lunesQueViene), isFalse);
    });

    test('todo de cero: un movimiento anterior a la primera fichada no '
        'computa y el día queda para revisar', () {
      final records = [
        rec(martes, hm(8, 0), hm(16, 0)),
        rec(miercoles, hm(8, 0), hm(16, 0)),
      ];
      final calc = buildBankCalculator(today: hoy, records: records);
      final anterior = BankMovement.accumulation(
        date: CalendarDate(2026, 9, 19),
        minutes: 300,
      );
      final s = calculateBankStatus(
        calculator: calc,
        records: records,
        movements: [
          anterior,
          BankMovement.usufruct(
            date: lunes,
            scope: UsufructScope.full,
            minutes: 480,
          ),
          BankMovement.accumulation(date: martes, minutes: 60),
        ],
      );
      // Solo computa la acumulación del martes (inicio del control).
      expect(s.balanceMinutes, 60);
      expect(s.current.movementsOutsideControl, hasLength(2));
      final sabado19 = s.current.days.firstWhere(
        (d) => d.date == CalendarDate(2026, 9, 19),
      );
      expect(sabado19.needsReview, isTrue);
      expect(sabado19.accumulationMinutes, 0);
      expect(calc.countsMovementsOn(martes), isTrue);
      expect(calc.countsMovementsOn(lunes), isFalse);
    });

    test('los usufructos a futuro no restan del saldo actual pero sí del '
        'disponible', () {
      final records = [rec(lunes, hm(7, 0), hm(17, 0))]; // +2:00
      final calc = buildBankCalculator(
        today: hoy,
        records: [
          ...records,
          rec(martes, hm(8, 0), hm(16, 0)),
          rec(miercoles, hm(8, 0), hm(16, 0)),
        ],
      );
      final s = calculateBankStatus(
        calculator: calc,
        records: [
          ...records,
          rec(martes, hm(8, 0), hm(16, 0)),
          rec(miercoles, hm(8, 0), hm(16, 0)),
        ],
        movements: [
          BankMovement.accumulation(date: sabado, minutes: 300),
          BankMovement.usufruct(
            date: viernes,
            scope: UsufructScope.partial,
            minutes: 90,
          ),
        ],
      );
      expect(s.balanceMinutes, 120);
      expect(s.futureUsufructMinutes, 90);
      expect(s.futureAccumulationMinutes, 300);
      expect(s.availableMinutes, 30);
    });

    test('saldo negativo: tres días hábiles faltantes dan -24:00', () {
      final records = [rec(CalendarDate(2026, 9, 18), hm(8, 0), hm(16, 0))];
      final s = calculateBankStatus(
        calculator: buildBankCalculator(today: hoy, records: records),
        records: records,
      );
      expect(s.balanceMinutes, -1440);
      expect(formatMinutes(s.balanceMinutes), '-24:00');
      expect(s.current.missingDays.map((d) => d.date), [
        lunes,
        martes,
        miercoles,
      ]);
    });

    test('un movimiento perdido no computa', () {
      final records = [
        rec(lunes, hm(8, 0), hm(16, 0)),
        rec(martes, hm(8, 0), hm(16, 0)),
        rec(miercoles, hm(8, 0), hm(16, 0)),
      ];
      final s = calculateBankStatus(
        calculator: buildBankCalculator(today: hoy, records: records),
        records: records,
        movements: [
          BankMovement.accumulation(
            date: martes,
            minutes: 240,
            status: MovementStatus.lost,
          ),
          BankMovement.usufruct(
            date: miercoles,
            scope: UsufructScope.full,
            minutes: 480,
            status: MovementStatus.lost,
          ),
        ],
      );
      expect(s.balanceMinutes, 0);
      expect(s.current.lostAccumulationMinutes, 240);
      expect(s.current.lostUsufructMinutes, 480);
    });

    test('exige la fecha de hoy', () {
      expect(
        () => calculateBankStatus(calculator: DayCalculator()),
        throwsArgumentError,
      );
    });
  });

  group('usufructAvailableMinutes', () {
    final records = [
      rec(lunes, hm(7, 0), hm(17, 0)), // +2:00
      rec(martes, hm(7, 0), hm(17, 0)), // +2:00
      rec(miercoles, hm(8, 0), hm(16, 0)),
    ];
    final calc = buildBankCalculator(today: hoy, records: records);

    int disponible(
      BankMovement candidate, {
      List<BankMovement> movements = const [],
      String? replacingId,
    }) => usufructAvailableMinutes(
      calculator: calc,
      records: records,
      movements: movements,
      candidate: candidate,
      replacingId: replacingId,
    );

    BankMovement parcial(CalendarDate d, int min, {String? id}) =>
        BankMovement.usufruct(
          id: id,
          date: d,
          scope: UsufructScope.partial,
          minutes: min,
        );

    test('sin otros movimientos es el saldo actual', () {
      expect(disponible(parcial(viernes, 60)), 240);
    });

    test('descuenta los usufructos ya cargados a futuro', () {
      expect(
        disponible(
          parcial(viernes, 60),
          movements: [parcial(lunesQueViene, 180, id: 'futuro')],
        ),
        60,
      );
    });

    test('no cuenta las acumulaciones con fecha posterior a hoy', () {
      expect(
        disponible(
          parcial(viernes, 60),
          movements: [BankMovement.accumulation(date: sabado, minutes: 600)],
        ),
        240,
      );
    });

    test('al editar, ignora la versión anterior del mismo movimiento', () {
      expect(
        disponible(
          parcial(lunesQueViene, 200, id: 'editado'),
          movements: [parcial(lunesQueViene, 180, id: 'editado')],
          replacingId: 'editado',
        ),
        240,
      );
    });

    test('un usufructo sobre un día faltante no cuenta la deuda dos veces', () {
      // Viernes 18 sin fichada con el control ya iniciado: faltante (-8:00).
      final r = [
        rec(CalendarDate(2026, 9, 17), hm(8, 0), hm(16, 0)),
        ...records,
      ];
      final c = buildBankCalculator(today: hoy, records: r);
      final antes = calculateBankStatus(calculator: c, records: r);
      expect(antes.balanceMinutes, 240 - 480);
      final d = usufructAvailableMinutes(
        calculator: c,
        records: r,
        candidate: BankMovement.usufruct(
          date: CalendarDate(2026, 9, 18),
          scope: UsufructScope.full,
          minutes: 480,
        ),
      );
      // Sin la deuda del 18 (la cubre el usufructo) quedan las 4:00 a favor.
      expect(d, 240);
    });

    test('con validateUsufruct: bloquea si pide más que el disponible', () {
      final disp = disponible(
        parcial(viernes, 120),
        movements: [parcial(lunesQueViene, 180, id: 'futuro')],
      );
      final v = validateUsufruct(
        balanceBeforeMinutes: disp,
        minutes: 120,
        scope: UsufructScope.partial,
        workdayMinutes: 480,
      );
      expect(v.status, UsufructValidationStatus.insufficientBalance);
      expect(v.availableMinutes, 60);
      expect(v.requestedMinutes, 120);
    });
  });

  group('usufructo antes del inicio del control', () {
    test('no computa ni cubre deuda: el día queda para revisar', () {
      final c = DayCalculator(controlStart: miercoles, today: hoy);
      final d = c.calculate(
        lunes,
        movements: [
          BankMovement.usufruct(
            date: lunes,
            scope: UsufructScope.partial,
            minutes: 120,
          ),
        ],
      );
      expect(d.status, DayStatus.beforeControl);
      expect(d.debtMinutes, 0);
      expect(d.bankDeltaMinutes, 0);
      expect(d.outsideControlMovements, hasLength(1));
      expect(d.needsReview, isTrue);
    });
  });
}
