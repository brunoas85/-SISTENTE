import 'calendar_date.dart';

/// Minutos de la jornada por defecto (8 h) cuando no hay agrupamiento
/// elegido ni vigencia en `jornadas`.
const int defaultWorkdayMinutes = 480;

/// Tramo de asistencia: una fichada de ingreso y, opcionalmente, de egreso.
///
/// Un día puede tener varios tramos (por ej. salir y volver); el trabajado
/// del día es la suma de los tramos. Las horas se guardan como minutos desde
/// la medianoche (`0..1439`). Un tramo sin egreso está *abierto* y el día no
/// computa.
class DailyRecord {
  const DailyRecord({
    this.id,
    required this.date,
    required this.checkInMinutes,
    this.checkOutMinutes,
  }) : assert(checkInMinutes >= 0 && checkInMinutes < 1440),
       assert(
         checkOutMinutes == null ||
             (checkOutMinutes >= 0 && checkOutMinutes < 1440),
       );

  final String? id;
  final CalendarDate date;

  /// Hora de ingreso en minutos desde la medianoche.
  final int checkInMinutes;

  /// Hora de egreso en minutos desde la medianoche, o `null` si está abierto.
  final int? checkOutMinutes;

  bool get isOpen => checkOutMinutes == null;

  @override
  bool operator ==(Object other) =>
      other is DailyRecord &&
      other.id == id &&
      other.date == date &&
      other.checkInMinutes == checkInMinutes &&
      other.checkOutMinutes == checkOutMinutes;

  @override
  int get hashCode => Object.hash(id, date, checkInMinutes, checkOutMinutes);

  @override
  String toString() =>
      'DailyRecord($date, in: $checkInMinutes, out: $checkOutMinutes)';
}

/// Jornada (en minutos) vigente a partir de [validFrom], inclusive, hasta la
/// siguiente vigencia.
class WorkdaySchedule {
  const WorkdaySchedule({required this.validFrom, required this.minutes})
    : assert(minutes >= 0);

  final CalendarDate validFrom;
  final int minutes;

  @override
  bool operator ==(Object other) =>
      other is WorkdaySchedule &&
      other.validFrom == validFrom &&
      other.minutes == minutes;

  @override
  int get hashCode => Object.hash(validFrom, minutes);

  @override
  String toString() => 'WorkdaySchedule(desde $validFrom, $minutes min)';
}

/// Tipo de feriado nacional (columna `feriados.tipo`).
enum HolidayKind {
  /// Feriado inamovible.
  fixed('inamovible'),

  /// Feriado trasladable.
  movable('trasladable'),

  /// Día no laborable con fines turísticos (puente).
  nonWorking('no_laborable');

  const HolidayKind(this.dbValue);

  /// Valor en la base (`inamovible`, `trasladable`, `no_laborable`).
  final String dbValue;

  /// Tipo con ese valor de la base, o [HolidayKind.fixed] si no se conoce.
  static HolidayKind fromDbValue(String? value) {
    for (final k in values) {
      if (k.dbValue == value) return k;
    }
    return fixed;
  }
}

/// Feriado nacional (o día no laborable) recibido desde afuera: el dominio
/// no tiene feriados hardcodeados. Cualquiera de los tipos hace que el día
/// no sea laborable.
class Holiday {
  const Holiday({
    required this.date,
    this.name = '',
    this.kind = HolidayKind.fixed,
  });

  final CalendarDate date;
  final String name;
  final HolidayKind kind;

  @override
  bool operator ==(Object other) =>
      other is Holiday &&
      other.date == date &&
      other.name == name &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(date, name, kind);

  @override
  String toString() => 'Holiday($date, $name, ${kind.dbValue})';
}

enum BankMovementType {
  /// Horas fuera de jornada cargadas a mano (por ej. sábados). Suma al banco.
  accumulation,

  /// Uso de horas del banco. Resta al banco si está vigente.
  usufruct,
}

enum UsufructScope {
  /// Jornada completa.
  full,

  /// Parcial: salida temprana, llegada tarde, etc.
  partial,
}

/// Estado de un movimiento manual del banco (acumulación o usufructo).
enum MovementStatus {
  /// Computa en el saldo. Un usufructo vigente además cubre la deuda de ese
  /// día.
  active,

  /// Solo historial: no computa en el saldo (ni suma ni descuenta) y un
  /// usufructo perdido no cubre deuda. Se marca a mano: no hay vencimiento
  /// automático.
  lost,
}

/// Movimiento manual del banco de horas.
///
/// El a favor y la deuda diarios **no** son movimientos: se derivan de las
/// fichadas para no cargarlos dos veces.
class BankMovement {
  const BankMovement._({
    this.id,
    required this.date,
    required this.type,
    required this.minutes,
    this.scope,
    this.status = MovementStatus.active,
    this.gdeDocumentTypeCode,
    this.gdeNumber,
  }) : assert(minutes >= 0);

  /// Acumulación manual de [minutes] (suma al banco si está vigente).
  const BankMovement.accumulation({
    String? id,
    required CalendarDate date,
    required int minutes,
    MovementStatus status = MovementStatus.active,
    String? gdeDocumentTypeCode,
    String? gdeNumber,
  }) : this._(
         id: id,
         date: date,
         type: BankMovementType.accumulation,
         minutes: minutes,
         status: status,
         gdeDocumentTypeCode: gdeDocumentTypeCode,
         gdeNumber: gdeNumber,
       );

  /// Usufructo de [minutes]. Para uno de jornada completa, [minutes] tiene
  /// que ser igual a la jornada vigente de ese día (normalmente 480); si no,
  /// el día queda para revisar (no se corrige en silencio).
  const BankMovement.usufruct({
    String? id,
    required CalendarDate date,
    required UsufructScope scope,
    required int minutes,
    MovementStatus status = MovementStatus.active,
    String? gdeDocumentTypeCode,
    String? gdeNumber,
  }) : this._(
         id: id,
         date: date,
         type: BankMovementType.usufruct,
         minutes: minutes,
         scope: scope,
         status: status,
         gdeDocumentTypeCode: gdeDocumentTypeCode,
         gdeNumber: gdeNumber,
       );

  final String? id;
  final CalendarDate date;
  final BankMovementType type;
  final int minutes;

  /// Solo para usufructos.
  final UsufructScope? scope;

  /// Vigente o perdido (acumulaciones y usufructos).
  final MovementStatus status;

  /// Código del tipo de documento GDE (catálogo editable, ej. `FSOLI`).
  final String? gdeDocumentTypeCode;

  /// Número GDE.
  final String? gdeNumber;

  bool get isAccumulation => type == BankMovementType.accumulation;
  bool get isUsufruct => type == BankMovementType.usufruct;
  bool get isActive => status == MovementStatus.active;
  bool get isLost => status == MovementStatus.lost;
  bool get isActiveAccumulation => isAccumulation && isActive;
  bool get isLostAccumulation => isAccumulation && isLost;
  bool get isActiveUsufruct => isUsufruct && isActive;
  bool get isLostUsufruct => isUsufruct && isLost;
  bool get isFullUsufruct => isUsufruct && scope == UsufructScope.full;

  @override
  bool operator ==(Object other) =>
      other is BankMovement &&
      other.id == id &&
      other.date == date &&
      other.type == type &&
      other.minutes == minutes &&
      other.scope == scope &&
      other.status == status &&
      other.gdeDocumentTypeCode == gdeDocumentTypeCode &&
      other.gdeNumber == gdeNumber;

  @override
  int get hashCode => Object.hash(
    id,
    date,
    type,
    minutes,
    scope,
    status,
    gdeDocumentTypeCode,
    gdeNumber,
  );

  @override
  String toString() =>
      'BankMovement($date, ${type.name}, $minutes min, ${status.name})';
}
