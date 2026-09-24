// Movimientos manuales del banco de horas.
//
// Decisiones neutras mientras Bruno no defina otra cosa (ver el informe del
// 24/09/2026):
// - Un usufructo de varios días se carga uno por día (un movimiento por
//   fecha, cada uno validado contra el saldo).
// - No se distingue salida temprana de llegada tarde: alcanza con el tipo de
//   documento GDE que lo respalda.
// - Un usufructo parcial mayor que la deuda del día descuenta completo (lo
//   que sobra no vuelve al banco).
//
// Confirmado por Bruno (24/09/2026):
// - Un usufructo parcial tiene que ser menor que la jornada, y no se cargan
//   dos usufructos que se pisen el mismo día (un día tiene un solo estado).
// - El saldo se controla siempre: cualquier edición de un usufructo vigente,
//   aunque sea solo del respaldo, se vuelve a validar.
// - No se cargan acumulaciones con fecha futura.
// - Marcar como perdida o borrar una acumulación no se bloquea aunque el
//   saldo quede negativo.
// - "Todo de cero": el saldo arranca en 0 en el inicio del control (la
//   primera fichada). No se cargan movimientos anteriores; si llega alguno
//   (sync, importación) no computa y queda para revisar.
import '../../core/format/formatters.dart';
import '../../domain/domain.dart';
import '../attachments/attachment.dart';
import '../local/app_database.dart';

/// Los tres tipos de movimiento que se cargan a mano.
enum TipoMovimiento {
  /// Horas fuera de jornada (por ej. un sábado). Suma al banco.
  acumulacion('acumulacion', null, 'Acumulación'),

  /// Jornada completa: los minutos son la jornada vigente de ese día.
  usufructoTotal('usufructo', 'total', 'Usufructo total'),

  /// Parte de la jornada (salida temprana, llegada tarde, …).
  usufructoParcial('usufructo', 'parcial', 'Usufructo parcial');

  const TipoMovimiento(this.tipoDb, this.alcanceDb, this.label);

  /// Valor de `movimiento_tipo`.
  final String tipoDb;

  /// Valor de `usufructo_alcance` (`null` en acumulaciones).
  final String? alcanceDb;

  /// Texto para la UI.
  final String label;

  bool get esUsufructo => this != acumulacion;

  UsufructScope? get scope => switch (this) {
    acumulacion => null,
    usufructoTotal => UsufructScope.full,
    usufructoParcial => UsufructScope.partial,
  };

  /// Tipo a partir de las columnas `tipo` y `alcance`. Un usufructo sin
  /// alcance (no debería pasar por el CHECK) se toma como parcial.
  static TipoMovimiento fromDb(String tipo, String? alcance) {
    if (tipo != 'usufructo') return acumulacion;
    return alcance == 'total' ? usufructoTotal : usufructoParcial;
  }
}

const estadoVigente = 'vigente';
const estadoPerdido = 'perdido';

extension LocalMovimientoX on LocalMovimiento {
  CalendarDate get date => parseIsoDate(fecha);
  TipoMovimiento get kind => TipoMovimiento.fromDb(tipo, alcance);
  bool get perdido => estado == estadoPerdido;
  bool get isDeleted => deletedAt != null;

  /// Tiene adjunto (en el dispositivo o ya subido).
  bool get tieneAdjunto => adjuntoLocal != null || adjuntoPath != null;

  /// El adjunto es un PDF.
  bool get adjuntoEsPdf => extensionOf(adjuntoLocal ?? adjuntoPath) == 'pdf';

  /// Movimiento del dominio para calcular saldos.
  BankMovement toBankMovement({String? codigoDocumento}) {
    final status = perdido ? MovementStatus.lost : MovementStatus.active;
    final k = kind;
    if (k == TipoMovimiento.acumulacion) {
      return BankMovement.accumulation(
        id: id,
        date: date,
        minutes: minutos,
        status: status,
        gdeDocumentTypeCode: codigoDocumento,
        gdeNumber: numeroGde,
      );
    }
    return BankMovement.usufruct(
      id: id,
      date: date,
      scope: k.scope!,
      minutes: minutos,
      status: status,
      gdeDocumentTypeCode: codigoDocumento,
      gdeNumber: numeroGde,
    );
  }
}

extension LocalTipoDocumentoX on LocalTipoDocumento {
  bool get isDeleted => deletedAt != null;
}

/// Datos de un movimiento a guardar (alta o edición).
class MovimientoDraft {
  const MovimientoDraft({
    this.id,
    required this.tipo,
    required this.fecha,
    this.minutos,
    this.tipoDocumentoId,
    this.numeroGde,
    this.observacion,
  });

  /// `null` = movimiento nuevo.
  final String? id;
  final TipoMovimiento tipo;
  final CalendarDate fecha;

  /// Minutos cargados a mano. En un usufructo total se ignoran: valen los
  /// de la jornada vigente de ese día.
  final int? minutos;
  final String? tipoDocumentoId;
  final String? numeroGde;
  final String? observacion;
}

/// Qué hacer con el adjunto al guardar.
sealed class CambioAdjunto {
  const CambioAdjunto();
}

/// Dejar el adjunto como está.
class MantenerAdjunto extends CambioAdjunto {
  const MantenerAdjunto();
}

/// Quitar el adjunto.
class QuitarAdjunto extends CambioAdjunto {
  const QuitarAdjunto();
}

/// Reemplazar (o agregar) el adjunto.
class NuevoAdjunto extends CambioAdjunto {
  const NuevoAdjunto(this.archivo);
  final PreparedAttachment archivo;
}

/// Lo que hace falta para validar un movimiento contra el banco.
class BancoContexto {
  const BancoContexto({
    required this.calculator,
    required this.records,
    required this.movimientos,
    required this.holidays,
  });

  /// Calculador de `buildBankCalculator` (con hoy).
  final DayCalculator calculator;

  /// Fichadas activas.
  final List<DailyRecord> records;

  /// Movimientos activos (sin los borrados).
  final List<LocalMovimiento> movimientos;
  final List<Holiday> holidays;
}

/// Minutos con los que se guarda [draft]: la jornada vigente del día para
/// un usufructo total; si no, los cargados.
int? minutosEfectivos(MovimientoDraft draft, DayCalculator calculator) =>
    draft.tipo == TipoMovimiento.usufructoTotal
    ? calculator.workdayMinutesFor(draft.fecha)
    : draft.minutos;

/// Mensaje cuando el saldo no alcanza para un usufructo.
String mensajeSaldoInsuficiente(int disponible, int pedido) =>
    'Saldo disponible ${formatMinutes(disponible)}, '
    'pedís ${formatMinutes(pedido)}.';

/// Motivo por el que no se puede cargar un movimiento en [fecha] según el
/// inicio del control ("todo de cero"), o `null`.
///
/// - Sin fichadas el control todavía no empezó: no se cargan movimientos
///   (el saldo arranca en 0 con la primera fichada).
/// - Con fichadas, no se cargan movimientos anteriores a la primera.
String? motivoFueraDelControl(CalendarDate fecha, BancoContexto contexto) {
  final inicio = controlStartFrom(contexto.records);
  if (inicio == null) {
    return 'El banco arranca en 0 con tu primera fichada. Fichá al menos una '
        'vez antes de cargar movimientos.';
  }
  if (fecha.isBefore(inicio)) {
    return 'El control empezó el ${formatDate(inicio)} (tu primera fichada) y '
        'el saldo arranca en 0 ese día. No se cargan movimientos con fecha '
        'anterior.';
  }
  return null;
}

/// Valida un movimiento antes de guardarlo. Devuelve el motivo para el
/// usuario, o `null` si se puede guardar. La usan el repositorio (autoridad)
/// y la UI (para avisar antes de guardar).
///
/// [original] es el movimiento que se edita (o `null` si es nuevo).
/// - "Todo de cero": no se cargan movimientos antes del inicio del control
///   (ver [motivoFueraDelControl]).
/// - No se cargan acumulaciones con fecha futura.
/// - Un usufructo vigente se valida **siempre** contra el saldo disponible
///   (incluidos los usufructos ya cargados a futuro), también al editar
///   solo el respaldo; el propio movimiento no se cuenta dos veces. Un
///   usufructo perdido no computa, así que no se valida contra el saldo.
String? validarMovimiento({
  required MovimientoDraft draft,
  required BancoContexto contexto,
  LocalMovimiento? original,
}) {
  final calc = contexto.calculator;
  final minutos = minutosEfectivos(draft, calc);
  final jornada = calc.workdayMinutesFor(draft.fecha);

  final fueraDelControl = motivoFueraDelControl(draft.fecha, contexto);
  if (fueraDelControl != null) return fueraDelControl;
  final hoy = calc.today;
  if (draft.tipo == TipoMovimiento.acumulacion &&
      hoy != null &&
      draft.fecha.isAfter(hoy)) {
    return 'No se cargan acumulaciones con fecha futura: cargala el día que '
        'hiciste las horas o después (hoy es ${formatDate(hoy)}).';
  }
  if (draft.tipo.esUsufructo) {
    final noLaborable = nonWorkingDayFor(draft.fecha, contexto.holidays);
    if (noLaborable != null) {
      return '${motivoDiaNoLaborableBanco(noLaborable)}. '
          'El usufructo se carga solo en día hábil.';
    }
  }
  if (minutos == null || minutos <= 0) {
    return 'Cargá las horas en formato H:MM (por ejemplo 2:30).';
  }
  if (minutos > 1440) return 'Un movimiento no puede superar 24:00.';
  if (draft.tipo == TipoMovimiento.usufructoParcial && minutos >= jornada) {
    return 'Un usufructo parcial tiene que ser menor que la jornada '
        '(${formatMinutes(jornada)}). Para el día completo elegí usufructo '
        'total.';
  }

  final vigente = original == null || !original.perdido;
  if (!draft.tipo.esUsufructo || !vigente) return null;

  // Un día tiene un solo estado: no se cargan dos usufructos que se pisen.
  final mismoDia = [
    for (final m in contexto.movimientos)
      if (m.id != draft.id &&
          !m.isDeleted &&
          !m.perdido &&
          m.kind.esUsufructo &&
          m.fecha == toIsoDate(draft.fecha))
        m,
  ];
  if (draft.tipo == TipoMovimiento.usufructoTotal && mismoDia.isNotEmpty) {
    return 'Ya hay un usufructo cargado el ${formatDate(draft.fecha)}.';
  }
  if (mismoDia.any((m) => m.kind == TipoMovimiento.usufructoTotal)) {
    return 'El ${formatDate(draft.fecha)} ya tiene un usufructo total.';
  }

  // El saldo se controla siempre (Bruno, 24/09/2026).
  return validarSaldoUsufructo(
    contexto: contexto,
    id: draft.id,
    tipo: draft.tipo,
    fecha: draft.fecha,
    minutos: minutos,
  );
}

/// Valida contra el saldo disponible un usufructo vigente de [minutos] en
/// [fecha] (nuevo, editado o que vuelve a vigente). Devuelve
/// "Saldo disponible X, pedís Y." si no alcanza.
String? validarSaldoUsufructo({
  required BancoContexto contexto,
  required String? id,
  required TipoMovimiento tipo,
  required CalendarDate fecha,
  required int minutos,
}) {
  final calc = contexto.calculator;
  final jornada = calc.workdayMinutesFor(fecha);
  final disponible = usufructAvailableMinutes(
    calculator: calc,
    records: contexto.records,
    movements: [for (final m in contexto.movimientos) m.toBankMovement()],
    candidate: BankMovement.usufruct(
      id: id,
      date: fecha,
      scope: tipo.scope!,
      minutes: minutos,
    ),
    replacingId: id,
  );
  final v = validateUsufruct(
    balanceBeforeMinutes: disponible,
    minutes: minutos,
    scope: tipo.scope!,
    workdayMinutes: jornada,
  );
  return switch (v.status) {
    UsufructValidationStatus.ok => null,
    UsufructValidationStatus.insufficientBalance => mensajeSaldoInsuficiente(
      v.availableMinutes,
      v.requestedMinutes,
    ),
    UsufructValidationStatus.invalidMinutes =>
      'Cargá las horas en formato H:MM (por ejemplo 2:30).',
    UsufructValidationStatus.fullDayMismatch =>
      'Un usufructo total tiene que ser la jornada de ese día '
          '(${formatMinutes(jornada)}).',
  };
}

/// "El 26/09/2026 es sábado", "El 12/10/2026 es feriado: …" (sin punto).
String motivoDiaNoLaborableBanco(NonWorkingDay dia) {
  final sujeto = 'El ${formatDate(dia.date)}';
  final h = dia.holiday;
  if (h != null) {
    final que = h.kind == HolidayKind.nonWorking
        ? 'día no laborable'
        : 'feriado';
    return h.name.isEmpty ? '$sujeto es $que' : '$sujeto es $que: ${h.name}';
  }
  return '$sujeto es ${nombreDiaSemana(dia.date)}';
}

/// Valida el código de un tipo de documento GDE: no vacío y único por
/// usuario sin distinguir mayúsculas (entre los activos, sin contar [id]).
String? validarCodigoTipo({
  required String codigo,
  String? id,
  required Iterable<LocalTipoDocumento> existentes,
}) {
  final c = codigo.trim();
  if (c.isEmpty) return 'Cargá el código (por ejemplo, el que usa GDE).';
  final repetido = existentes.any(
    (t) =>
        t.id != id && !t.isDeleted && t.codigo.toUpperCase() == c.toUpperCase(),
  );
  if (repetido) return 'Ya hay un tipo de documento con el código $c.';
  return null;
}
