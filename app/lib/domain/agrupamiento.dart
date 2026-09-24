import 'models.dart';

/// Agrupamiento del agente (columna `profiles.agrupamiento`). Define la
/// jornada por defecto cuando no hay una vigencia en `jornadas`.
enum Agrupamiento {
  /// Administrativo: 8 h.
  administrativo('administrativo', 480),

  /// Guardaparque: 7 h.
  guardaparque('guardaparque', 420),

  /// Guardaparque de apoyo: 7 h.
  guardaparqueApoyo('guardaparque_apoyo', 420);

  const Agrupamiento(this.dbValue, this.workdayMinutes);

  /// Valor del enum `agrupamiento` en Postgres.
  final String dbValue;

  /// Jornada por defecto del agrupamiento, en minutos.
  final int workdayMinutes;

  /// Agrupamiento con ese valor de la base, o `null` si es `null` o no se
  /// conoce (no se adivina).
  static Agrupamiento? fromDbValue(String? value) {
    for (final a in values) {
      if (a.dbValue == value) return a;
    }
    return null;
  }
}

/// Jornada por defecto para [agrupamiento]: la del agrupamiento, o
/// [defaultWorkdayMinutes] (480) si todavía no se eligió.
int workdayMinutesForAgrupamiento(Agrupamiento? agrupamiento) =>
    agrupamiento?.workdayMinutes ?? defaultWorkdayMinutes;
