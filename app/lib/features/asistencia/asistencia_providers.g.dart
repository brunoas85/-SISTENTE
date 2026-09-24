// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asistencia_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fecha de hoy según el dispositivo. Se invalida al volver a primer plano.

@ProviderFor(today)
final todayProvider = TodayProvider._();

/// Fecha de hoy según el dispositivo. Se invalida al volver a primer plano.

final class TodayProvider
    extends $FunctionalProvider<CalendarDate, CalendarDate, CalendarDate>
    with $Provider<CalendarDate> {
  /// Fecha de hoy según el dispositivo. Se invalida al volver a primer plano.
  TodayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayHash();

  @$internal
  @override
  $ProviderElement<CalendarDate> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CalendarDate create(Ref ref) {
    return today(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarDate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarDate>(value),
    );
  }
}

String _$todayHash() => r'9ff72523560902537dfd3dfc3aa4aa654695db11';

/// Todas las fichadas activas del usuario (desde la base local).

@ProviderFor(misFichadas)
final misFichadasProvider = MisFichadasProvider._();

/// Todas las fichadas activas del usuario (desde la base local).

final class MisFichadasProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LocalFichada>>,
          List<LocalFichada>,
          Stream<List<LocalFichada>>
        >
    with
        $FutureModifier<List<LocalFichada>>,
        $StreamProvider<List<LocalFichada>> {
  /// Todas las fichadas activas del usuario (desde la base local).
  MisFichadasProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'misFichadasProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$misFichadasHash();

  @$internal
  @override
  $StreamProviderElement<List<LocalFichada>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<LocalFichada>> create(Ref ref) {
    return misFichadas(ref);
  }
}

String _$misFichadasHash() => r'ab82841bf84f600a1148569da4274a4c1b3412d1';

/// Feriados guardados en el dispositivo.

@ProviderFor(feriadosLocales)
final feriadosLocalesProvider = FeriadosLocalesProvider._();

/// Feriados guardados en el dispositivo.

final class FeriadosLocalesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Holiday>>,
          List<Holiday>,
          Stream<List<Holiday>>
        >
    with $FutureModifier<List<Holiday>>, $StreamProvider<List<Holiday>> {
  /// Feriados guardados en el dispositivo.
  FeriadosLocalesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feriadosLocalesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feriadosLocalesHash();

  @$internal
  @override
  $StreamProviderElement<List<Holiday>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Holiday>> create(Ref ref) {
    return feriadosLocales(ref);
  }
}

String _$feriadosLocalesHash() => r'b37c1c482183a885f5b80dbca2e4a0738aba690e';

/// Fichadas sin sincronizar (pendientes o con error).

@ProviderFor(pendientesCount)
final pendientesCountProvider = PendientesCountProvider._();

/// Fichadas sin sincronizar (pendientes o con error).

final class PendientesCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Fichadas sin sincronizar (pendientes o con error).
  PendientesCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendientesCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendientesCountHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return pendientesCount(ref);
  }
}

String _$pendientesCountHash() => r'a68fd6140d54de6046dd486f5c9c24e959a0d6c7';

@ProviderFor(resumenFichar)
final resumenFicharProvider = ResumenFicharProvider._();

final class ResumenFicharProvider
    extends
        $FunctionalProvider<
          AsyncValue<ResumenFichar>,
          AsyncValue<ResumenFichar>,
          AsyncValue<ResumenFichar>
        >
    with $Provider<AsyncValue<ResumenFichar>> {
  ResumenFicharProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resumenFicharProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resumenFicharHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<ResumenFichar>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<ResumenFichar> create(Ref ref) {
    return resumenFichar(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<ResumenFichar> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<ResumenFichar>>(value),
    );
  }
}

String _$resumenFicharHash() => r'9bd369e721ecfc6a50dac22b54290e0202dffcd9';
