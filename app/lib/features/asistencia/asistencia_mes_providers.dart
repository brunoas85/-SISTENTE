import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/banco/movimiento.dart';
import '../../data/fichadas/fichadas_repository.dart';
import '../../data/local/app_database.dart';
import '../../data/providers.dart';
import '../../data/sync/fichadas_remote.dart';
import '../../domain/domain.dart';
import '../banco_horas/banco_providers.dart';
import '../perfil/perfil_providers.dart';
import 'asistencia_providers.dart';

part 'asistencia_mes_providers.g.dart';

/// Filtro de la vista mensual (uno a la vez).
enum FiltroAsistencia {
  todos('Todos los días'),

  /// Ver [DiaAsistencia.paraRevisar].
  revisar('Para revisar'),
  faltantes('Faltantes'),
  editados('Con tramos editados'),
  manuales('Cargados a mano');

  const FiltroAsistencia(this.label);
  final String label;
}

/// Un día de la vista mensual: el cálculo de `domain/` más los tramos tal
/// como están en la base local (editado, sync, fotos).
class DiaAsistencia {
  const DiaAsistencia({
    required this.dia,
    required this.tramos,
    required this.hoy,
    this.noLaborable,
    this.inicioControl,
  });

  /// Cálculo del día (estado único, minutos).
  final DayResult dia;

  /// Tramos activos del día, por hora de ingreso.
  final List<LocalFichada> tramos;

  final CalendarDate hoy;

  /// Por qué no es laborable (fin de semana o feriado, con su nombre).
  final NonWorkingDay? noLaborable;

  /// Primera fichada (inicio del control), o `null` si no hay ninguna.
  final CalendarDate? inicioControl;

  CalendarDate get fecha => dia.date;
  DayStatus get estado => dia.status;
  bool get esHoy => fecha == hoy;
  bool get esFuturo => fecha.isAfter(hoy);

  /// Necesita revisión: lo que marca `domain/` ([DayResult.needsReview]) más
  /// un tramo abierto de un día que ya terminó (bloquea las fichadas).
  bool get paraRevisar =>
      dia.needsReview || (estado == DayStatus.open && fecha.isBefore(hoy));

  bool get faltante => estado == DayStatus.missing;
  bool get tieneEditados => tramos.any((t) => t.editado);
  bool get tieneManuales => tramos.any((t) => t.esManual);

  /// Se puede agregar un tramo a mano: día pasado y laborable, desde el
  /// inicio del control (decisión de Bruno del 24/09).
  bool get admiteAlta =>
      fecha.isBefore(hoy) &&
      noLaborable == null &&
      !(inicioControl != null && fecha.isBefore(inicioControl!));

  bool cumple(FiltroAsistencia filtro) => switch (filtro) {
    FiltroAsistencia.todos => true,
    FiltroAsistencia.revisar => paraRevisar,
    FiltroAsistencia.faltantes => faltante,
    FiltroAsistencia.editados => tieneEditados,
    FiltroAsistencia.manuales => tieneManuales,
  };
}

/// Lo que muestra la vista mensual de Asistencia. Los cálculos salen de
/// `buildMonthlySummary`.
class AsistenciaMes {
  const AsistenciaMes({
    required this.anio,
    required this.mes,
    required this.hoy,
    required this.resumen,
    required this.dias,
    required this.feriados,
    this.inicioControl,
  });

  final int anio;
  final int mes;
  final CalendarDate hoy;
  final MonthlySummary resumen;

  /// Todos los días del mes, del 1 al último.
  final List<DiaAsistencia> dias;

  /// Feriados guardados en el dispositivo (para validar).
  final List<Holiday> feriados;

  /// Primera fichada, o `null` si todavía no hay ninguna.
  final CalendarDate? inicioControl;

  bool get esMesActual => anio == hoy.year && mes == hoy.month;

  /// La variación del banco se corta en hoy (mes en curso) o el mes todavía
  /// no empezó.
  bool get bancoHastaHoy => !CalendarDate(
    anio,
    mes,
    CalendarDate.daysInMonth(anio, mes),
  ).isBefore(hoy);

  int get paraRevisarCount => dias.where((d) => d.paraRevisar).length;

  List<DiaAsistencia> filtrar(FiltroAsistencia filtro) => [
    for (final d in dias)
      if (d.cumple(filtro)) d,
  ];

  DiaAsistencia? dia(CalendarDate fecha) {
    for (final d in dias) {
      if (d.fecha == fecha) return d;
    }
    return null;
  }

  /// Días de este mes a los que se les puede agregar un tramo.
  List<CalendarDate> get fechasAdmitenAlta => [
    for (final d in dias)
      if (d.admiteAlta) d.fecha,
  ];
}

/// Arma la vista de [anio]/[mes] con el mismo calculador que el banco
/// (jornada por agrupamiento, feriados, hoy e inicio del control).
AsistenciaMes buildAsistenciaMes({
  required int anio,
  required int mes,
  required CalendarDate hoy,
  required List<LocalFichada> fichadas,
  required List<Holiday> feriados,
  List<LocalMovimiento> movimientos = const [],
  Agrupamiento? agrupamiento,
}) {
  final records = [for (final f in fichadas) f.toDailyRecord()];
  final calculator = buildBankCalculator(
    today: hoy,
    records: records,
    holidays: feriados,
    agrupamiento: agrupamiento,
  );
  final resumen = buildMonthlySummary(
    year: anio,
    month: mes,
    calculator: calculator,
    records: records,
    movements: [for (final m in movimientos) m.toBankMovement()],
    bankUntil: hoy,
  );
  final inicio = controlStartFrom(records);
  final porFecha = <CalendarDate, List<LocalFichada>>{};
  for (final f in fichadas) {
    final d = f.date;
    if (d.year == anio && d.month == mes) (porFecha[d] ??= []).add(f);
  }
  return AsistenciaMes(
    anio: anio,
    mes: mes,
    hoy: hoy,
    resumen: resumen,
    feriados: feriados,
    inicioControl: inicio,
    dias: [
      for (final d in resumen.days)
        DiaAsistencia(
          dia: d,
          hoy: hoy,
          tramos: [...?porFecha[d.date]]
            ..sort((a, b) => a.ingresoMin.compareTo(b.ingresoMin)),
          noLaborable: nonWorkingDayFor(d.date, feriados),
          inicioControl: inicio,
        ),
    ],
  );
}

/// Mes elegido en la vista de Asistencia. Se conserva al cambiar de sección.
@Riverpod(keepAlive: true)
class MesAsistencia extends _$MesAsistencia {
  @override
  ({int anio, int mes}) build() {
    final hoy = ref.read(clockProvider)();
    return (anio: hoy.year, mes: hoy.month);
  }

  void anterior() => state = state.mes == 1
      ? (anio: state.anio - 1, mes: 12)
      : (anio: state.anio, mes: state.mes - 1);

  void siguiente() => state = state.mes == 12
      ? (anio: state.anio + 1, mes: 1)
      : (anio: state.anio, mes: state.mes + 1);

  void actual() {
    final hoy = ref.read(clockProvider)();
    state = (anio: hoy.year, mes: hoy.month);
  }
}

/// Filtro elegido en la vista de Asistencia.
@Riverpod(keepAlive: true)
class FiltroAsistenciaSel extends _$FiltroAsistenciaSel {
  @override
  FiltroAsistencia build() => FiltroAsistencia.todos;

  void set(FiltroAsistencia filtro) => state = filtro;
}

@riverpod
AsyncValue<AsistenciaMes> asistenciaMes(Ref ref) {
  final sel = ref.watch(mesAsistenciaProvider);
  final fichadas = ref.watch(misFichadasProvider);
  final feriados = ref.watch(feriadosLocalesProvider);
  final movimientos = ref.watch(misMovimientosProvider);
  final perfil = ref.watch(miPerfilProvider);
  final hoy = ref.watch(todayProvider);

  for (final v in [fichadas, feriados, movimientos]) {
    if (v.hasError) {
      return AsyncError(v.error!, v.stackTrace ?? StackTrace.current);
    }
  }
  final f = fichadas.value;
  final h = feriados.value;
  final m = movimientos.value;
  if (f == null || h == null || m == null || perfil.isLoading) {
    return const AsyncLoading();
  }
  return AsyncData(
    buildAsistenciaMes(
      anio: sel.anio,
      mes: sel.mes,
      hoy: hoy,
      fichadas: f,
      feriados: h,
      movimientos: m,
      // Si no se pudo leer el perfil, se usa la jornada por defecto.
      agrupamiento: perfil.value?.agrupamiento,
    ),
  );
}

/// Foto de un comprobante lista para mostrar.
sealed class FotoComprobante {
  const FotoComprobante();
}

/// Está en el dispositivo.
class FotoLocal extends FotoComprobante {
  const FotoLocal(this.bytes);
  final Uint8List bytes;
}

/// Solo está en el servidor: URL firmada de corta duración (60 s).
class FotoFirmada extends FotoComprobante {
  const FotoFirmada(this.url);
  final String url;
}

/// No se puede mostrar la foto. El mensaje es para el usuario.
class FotoNoDisponibleException implements Exception {
  const FotoNoDisponibleException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Foto de un tramo: primero la del dispositivo; si no está, una URL
/// firmada de 60 s del bucket privado `comprobantes`. No se guarda en caché
/// (el provider se descarta al cerrar la foto).
@riverpod
Future<FotoComprobante> fotoComprobante(
  Ref ref, {
  String? localRef,
  String? remotePath,
}) async {
  if (localRef != null) {
    final bytes = await ref
        .read(fichadasRepositoryProvider)
        .readPhoto(localRef);
    if (bytes != null) return FotoLocal(bytes);
  }
  if (remotePath == null) {
    throw const FotoNoDisponibleException(
      'La foto no está en este dispositivo y todavía no se subió.',
    );
  }
  try {
    final url = await ref
        .read(fichadasRemoteProvider)
        .signedPhotoUrl(remotePath, expiresIn: const Duration(seconds: 60));
    return FotoFirmada(url);
  } on RemoteUnavailableException {
    throw const FotoNoDisponibleException(
      'Sin conexión: la foto está solo en el servidor.',
    );
  } on RemoteRejectedException catch (e) {
    throw FotoNoDisponibleException('No se pudo abrir la foto: ${e.message}');
  }
}
