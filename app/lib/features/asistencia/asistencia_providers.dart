import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/auth/auth_providers.dart';
import '../../data/fichadas/fichadas_repository.dart';
import '../../data/local/app_database.dart';
import '../../data/providers.dart';
import '../../domain/domain.dart';
import '../perfil/perfil_providers.dart';

part 'asistencia_providers.g.dart';

/// Fecha de hoy según el dispositivo. Se invalida al volver a primer plano.
@riverpod
CalendarDate today(Ref ref) =>
    CalendarDate.fromDateTime(ref.watch(clockProvider)());

/// Todas las fichadas activas del usuario (desde la base local).
@riverpod
Stream<List<LocalFichada>> misFichadas(Ref ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  return ref.watch(fichadasRepositoryProvider).watchAll(userId);
}

/// Feriados guardados en el dispositivo.
@riverpod
Stream<List<Holiday>> feriadosLocales(Ref ref) =>
    ref.watch(fichadasRepositoryProvider).watchHolidays();

/// Fichadas sin sincronizar (pendientes o con error).
@riverpod
Stream<int> pendientesCount(Ref ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(0);
  return ref.watch(fichadasRepositoryProvider).watchUnsyncedCount(userId);
}

/// Lo que muestra la pantalla Fichar. Todos los cálculos salen de `domain/`.
class ResumenFichar {
  const ResumenFichar({
    required this.hoy,
    required this.tramos,
    required this.dia,
    required this.saldoMesMinutes,
    required this.saldoTotalMinutes,
    required this.abiertasAnteriores,
    this.todas = const [],
    this.diaNoLaborable,
    this.agrupamiento,
  });

  final CalendarDate hoy;

  /// Tramos de hoy, por hora de ingreso.
  final List<LocalFichada> tramos;

  /// Cálculo del día de hoy.
  final DayResult dia;

  /// Variación del banco en el mes de hoy (solo fichadas).
  final int saldoMesMinutes;

  /// Saldo del banco desde el inicio del control hasta hoy (solo fichadas).
  final int saldoTotalMinutes;

  /// Tramos de días anteriores que quedaron sin egreso.
  final List<LocalFichada> abiertasAnteriores;

  /// Todas las fichadas activas.
  final List<LocalFichada> todas;

  /// Si hoy no es laborable (fin de semana o feriado), por qué. Esos días no
  /// se puede fichar ingreso.
  final NonWorkingDay? diaNoLaborable;

  /// Agrupamiento del perfil (`null` si no se eligió: jornada de 480).
  final Agrupamiento? agrupamiento;

  /// Jornada de hoy en minutos.
  int get jornadaMinutes => dia.workdayMinutes;

  /// El botón principal está bloqueado: hoy no es laborable y no hay un
  /// tramo abierto que cerrar.
  bool get fichadaBloqueada =>
      diaNoLaborable != null && proximaAccion == AccionFichar.ingreso;

  /// Tramo abierto de hoy, si hay.
  LocalFichada? get abierto {
    for (final t in tramos) {
      if (t.isOpen) return t;
    }
    return null;
  }

  /// Tramo de un día anterior que hay que cerrar antes de volver a fichar
  /// (el más viejo), o `null`.
  LocalFichada? get pendienteDeCierre =>
      abiertasAnteriores.isEmpty ? null : abiertasAnteriores.first;

  /// El próximo paso del botón principal.
  AccionFichar get proximaAccion {
    if (pendienteDeCierre != null) return AccionFichar.cerrarAnterior;
    return abierto == null ? AccionFichar.ingreso : AccionFichar.egreso;
  }

  /// Tramos activos de [fecha] (para validar superposiciones).
  List<LocalFichada> tramosDe(CalendarDate fecha) => [
    for (final f in todas)
      if (f.date == fecha) f,
  ];
}

/// Qué hace el botón principal de Fichar.
enum AccionFichar {
  ingreso,
  egreso,

  /// Cerrar el tramo que quedó abierto en un día anterior.
  cerrarAnterior;

  TipoFichada get tipo =>
      this == ingreso ? TipoFichada.ingreso : TipoFichada.egreso;
}

/// Arma el [ResumenFichar] con el calculador de `domain/`.
///
/// La jornada sale del [agrupamiento] (8 h o 7 h; 480 si no hay). Todavía
/// no incluye los movimientos manuales del banco (acumulaciones y
/// usufructos) ni las vigencias de `jornadas`, que no se bajan al
/// dispositivo.
ResumenFichar buildResumenFichar({
  required CalendarDate hoy,
  required List<LocalFichada> fichadas,
  required List<Holiday> feriados,
  Agrupamiento? agrupamiento,
}) {
  final records = [for (final f in fichadas) f.toDailyRecord()];
  final calculator = DayCalculator(
    holidays: feriados,
    today: hoy,
    controlStart: controlStartFrom(records),
    agrupamiento: agrupamiento,
  );
  final mes = buildMonthlySummary(
    year: hoy.year,
    month: hoy.month,
    calculator: calculator,
    records: records,
  );
  final total = calculateBankBalance(
    calculator: calculator,
    records: records,
    to: hoy,
  );
  return ResumenFichar(
    hoy: hoy,
    tramos: [
      for (final f in fichadas)
        if (f.date == hoy) f,
    ]..sort((a, b) => a.ingresoMin.compareTo(b.ingresoMin)),
    dia: calculator.calculate(hoy, records: records),
    saldoMesMinutes: mes.bankDeltaMinutes,
    saldoTotalMinutes: total.balanceMinutes,
    todas: fichadas,
    diaNoLaborable: nonWorkingDayFor(hoy, feriados),
    agrupamiento: agrupamiento,
    abiertasAnteriores: [
      for (final f in fichadas)
        if (f.isOpen && f.date.isBefore(hoy)) f,
    ],
  );
}

@riverpod
AsyncValue<ResumenFichar> resumenFichar(Ref ref) {
  final fichadas = ref.watch(misFichadasProvider);
  final feriados = ref.watch(feriadosLocalesProvider);
  final perfil = ref.watch(miPerfilProvider);
  final hoy = ref.watch(todayProvider);

  if (fichadas.hasError) {
    return AsyncError(
      fichadas.error!,
      fichadas.stackTrace ?? StackTrace.current,
    );
  }
  if (feriados.hasError) {
    return AsyncError(
      feriados.error!,
      feriados.stackTrace ?? StackTrace.current,
    );
  }
  final f = fichadas.value;
  final h = feriados.value;
  if (f == null || h == null || perfil.isLoading) return const AsyncLoading();
  return AsyncData(
    buildResumenFichar(
      hoy: hoy,
      fichadas: f,
      feriados: h,
      // Si no se pudo leer el perfil, se usa la jornada por defecto.
      agrupamiento: perfil.value?.agrupamiento,
    ),
  );
}
