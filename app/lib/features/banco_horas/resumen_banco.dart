import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/banco/movimiento.dart';
import '../../data/fichadas/fichadas_repository.dart';
import '../../data/local/app_database.dart';
import '../../domain/domain.dart';
import '../asistencia/asistencia_providers.dart';
import '../perfil/perfil_providers.dart';
import 'banco_providers.dart';

part 'resumen_banco.g.dart';

/// `+2:00`, `-24:00`, `0:00`: minutos con signo explícito.
String formatSigned(int minutes) =>
    minutes > 0 ? '+${formatMinutes(minutes)}' : formatMinutes(minutes);

/// Lo que muestra la pantalla Banco. Todos los cálculos salen de `domain/`.
class ResumenBanco {
  const ResumenBanco({
    required this.hoy,
    required this.estado,
    required this.movimientos,
    required this.tipos,
    required this.contexto,
  });

  final CalendarDate hoy;

  /// Saldo actual (hasta hoy), desglose y lo cargado a futuro.
  final BankStatus estado;

  /// Movimientos activos, del más nuevo al más viejo.
  final List<LocalMovimiento> movimientos;

  /// Catálogo de tipos de documento (incluidos los borrados), por id.
  final Map<String, LocalTipoDocumento> tipos;

  /// Para validar altas y ediciones con los mismos datos que se muestran.
  final BancoContexto contexto;

  DayCalculator get calculator => contexto.calculator;

  /// Tipos de documento activos, por código.
  List<LocalTipoDocumento> get tiposActivos => [
    for (final t in tipos.values)
      if (!t.isDeleted) t,
  ]..sort((a, b) => a.codigo.toUpperCase().compareTo(b.codigo.toUpperCase()));

  /// Código del tipo de documento, o `null`.
  String? codigoTipo(String? id) => id == null ? null : tipos[id]?.codigo;

  /// Años con movimientos, más el actual, del más nuevo al más viejo.
  List<int> get anios =>
      {hoy.year, for (final m in movimientos) m.date.year}.toList()
        ..sort((a, b) => b.compareTo(a));

  /// Movimientos de [anio] y, si se indica, del [mes].
  List<LocalMovimiento> filtrar(int anio, int? mes) => [
    for (final m in movimientos)
      if (m.date.year == anio && (mes == null || m.date.month == mes)) m,
  ];

  /// Variación del saldo en [anio]/[mes], hasta hoy si es el mes actual
  /// (fichadas y movimientos del mes).
  int variacionMes(int anio, int mes) {
    final first = CalendarDate(anio, mes, 1);
    if (first.isAfter(hoy)) return 0;
    final last = CalendarDate(anio, mes, CalendarDate.daysInMonth(anio, mes));
    return calculateBankBalance(
      calculator: calculator,
      records: contexto.records,
      movements: [for (final m in contexto.movimientos) m.toBankMovement()],
      from: first,
      to: last.isAfter(hoy) ? hoy : last,
    ).balanceMinutes;
  }
}

/// Arma el [ResumenBanco]: fichadas + movimientos + jornada por
/// agrupamiento + feriados + inicio del control.
ResumenBanco buildResumenBanco({
  required CalendarDate hoy,
  required List<LocalFichada> fichadas,
  required List<Holiday> feriados,
  required List<LocalMovimiento> movimientos,
  List<LocalTipoDocumento> tipos = const [],
  Agrupamiento? agrupamiento,
}) {
  final records = [for (final f in fichadas) f.toDailyRecord()];
  final calculator = buildBankCalculator(
    today: hoy,
    records: records,
    holidays: feriados,
    agrupamiento: agrupamiento,
  );
  return ResumenBanco(
    hoy: hoy,
    estado: calculateBankStatus(
      calculator: calculator,
      records: records,
      movements: [for (final m in movimientos) m.toBankMovement()],
    ),
    movimientos: movimientos,
    tipos: {for (final t in tipos) t.id: t},
    contexto: BancoContexto(
      calculator: calculator,
      records: records,
      movimientos: movimientos,
      holidays: feriados,
    ),
  );
}

@riverpod
AsyncValue<ResumenBanco> resumenBanco(Ref ref) {
  final fichadas = ref.watch(misFichadasProvider);
  final feriados = ref.watch(feriadosLocalesProvider);
  final movimientos = ref.watch(misMovimientosProvider);
  final tipos = ref.watch(tiposDocumentoProvider);
  final perfil = ref.watch(miPerfilProvider);
  final hoy = ref.watch(todayProvider);

  for (final v in [fichadas, feriados, movimientos, tipos]) {
    if (v.hasError) {
      return AsyncError(v.error!, v.stackTrace ?? StackTrace.current);
    }
  }
  final f = fichadas.value;
  final h = feriados.value;
  final m = movimientos.value;
  final t = tipos.value;
  if (f == null || h == null || m == null || t == null || perfil.isLoading) {
    return const AsyncLoading();
  }
  return AsyncData(
    buildResumenBanco(
      hoy: hoy,
      fichadas: f,
      feriados: h,
      movimientos: m,
      tipos: t,
      // Si no se pudo leer el perfil, se usa la jornada por defecto.
      agrupamiento: perfil.value?.agrupamiento,
    ),
  );
}
