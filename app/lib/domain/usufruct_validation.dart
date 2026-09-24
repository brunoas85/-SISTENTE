import 'models.dart';

/// Resultado de validar un usufructo nuevo antes de cargarlo.
enum UsufructValidationStatus {
  /// Se puede cargar.
  ok,

  /// Los minutos pedidos no son positivos.
  invalidMinutes,

  /// Es un usufructo total y los minutos no son iguales a la jornada vigente
  /// de ese día.
  fullDayMismatch,

  /// Los minutos pedidos superan el saldo disponible.
  insufficientBalance,
}

/// Resultado de [validateUsufruct].
class UsufructValidation {
  const UsufructValidation({
    required this.status,
    required this.availableMinutes,
    required this.requestedMinutes,
    this.expectedMinutes,
  });

  final UsufructValidationStatus status;

  /// Saldo del banco antes del usufructo (puede ser negativo).
  final int availableMinutes;

  /// Minutos que se quieren usufructuar.
  final int requestedMinutes;

  /// Para un usufructo total, la jornada vigente de ese día.
  final int? expectedMinutes;

  bool get isOk => status == UsufructValidationStatus.ok;

  @override
  String toString() => 'UsufructValidation(${status.name}, '
      'disponible: $availableMinutes, pedido: $requestedMinutes)';
}

/// `true` si se pueden usufructuar [minutes] con un saldo previo de
/// [balanceBeforeMinutes]. Nunca con saldo negativo ni por más del saldo.
bool canUsufruct(int balanceBeforeMinutes, int minutes) =>
    minutes > 0 && minutes <= balanceBeforeMinutes;

/// Valida un usufructo **nuevo** antes de cargarlo.
///
/// - [balanceBeforeMinutes]: saldo del banco sin este usufructo.
/// - [workdayMinutes]: jornada vigente en la fecha del usufructo; con
///   [scope] total, [minutes] tiene que ser igual (no se corrige en
///   silencio).
///
/// No se aplica a movimientos ya cargados: el saldo puede quedar negativo
/// por deuda.
UsufructValidation validateUsufruct({
  required int balanceBeforeMinutes,
  required int minutes,
  required UsufructScope scope,
  required int workdayMinutes,
}) {
  final isFull = scope == UsufructScope.full;
  UsufructValidation result(UsufructValidationStatus status) =>
      UsufructValidation(
        status: status,
        availableMinutes: balanceBeforeMinutes,
        requestedMinutes: minutes,
        expectedMinutes: isFull ? workdayMinutes : null,
      );

  if (minutes <= 0) return result(UsufructValidationStatus.invalidMinutes);
  if (isFull && minutes != workdayMinutes) {
    return result(UsufructValidationStatus.fullDayMismatch);
  }
  if (!canUsufruct(balanceBeforeMinutes, minutes)) {
    return result(UsufructValidationStatus.insufficientBalance);
  }
  return result(UsufructValidationStatus.ok);
}
