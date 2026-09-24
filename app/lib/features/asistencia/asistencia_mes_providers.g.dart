// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asistencia_mes_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Mes elegido en la vista de Asistencia. Se conserva al cambiar de sección.

@ProviderFor(MesAsistencia)
final mesAsistenciaProvider = MesAsistenciaProvider._();

/// Mes elegido en la vista de Asistencia. Se conserva al cambiar de sección.
final class MesAsistenciaProvider
    extends $NotifierProvider<MesAsistencia, ({int anio, int mes})> {
  /// Mes elegido en la vista de Asistencia. Se conserva al cambiar de sección.
  MesAsistenciaProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mesAsistenciaProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mesAsistenciaHash();

  @$internal
  @override
  MesAsistencia create() => MesAsistencia();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(({int anio, int mes}) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<({int anio, int mes})>(value),
    );
  }
}

String _$mesAsistenciaHash() => r'3042721d11f663e4813317db5d6cc2bc4773aae4';

/// Mes elegido en la vista de Asistencia. Se conserva al cambiar de sección.

abstract class _$MesAsistencia extends $Notifier<({int anio, int mes})> {
  ({int anio, int mes}) build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<({int anio, int mes}), ({int anio, int mes})>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<({int anio, int mes}), ({int anio, int mes})>,
              ({int anio, int mes}),
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Filtro elegido en la vista de Asistencia.

@ProviderFor(FiltroAsistenciaSel)
final filtroAsistenciaSelProvider = FiltroAsistenciaSelProvider._();

/// Filtro elegido en la vista de Asistencia.
final class FiltroAsistenciaSelProvider
    extends $NotifierProvider<FiltroAsistenciaSel, FiltroAsistencia> {
  /// Filtro elegido en la vista de Asistencia.
  FiltroAsistenciaSelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filtroAsistenciaSelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filtroAsistenciaSelHash();

  @$internal
  @override
  FiltroAsistenciaSel create() => FiltroAsistenciaSel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FiltroAsistencia value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FiltroAsistencia>(value),
    );
  }
}

String _$filtroAsistenciaSelHash() =>
    r'b0d44ada16b285e3115a45f2cc14d6241b6d7796';

/// Filtro elegido en la vista de Asistencia.

abstract class _$FiltroAsistenciaSel extends $Notifier<FiltroAsistencia> {
  FiltroAsistencia build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FiltroAsistencia, FiltroAsistencia>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FiltroAsistencia, FiltroAsistencia>,
              FiltroAsistencia,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(asistenciaMes)
final asistenciaMesProvider = AsistenciaMesProvider._();

final class AsistenciaMesProvider
    extends
        $FunctionalProvider<
          AsyncValue<AsistenciaMes>,
          AsyncValue<AsistenciaMes>,
          AsyncValue<AsistenciaMes>
        >
    with $Provider<AsyncValue<AsistenciaMes>> {
  AsistenciaMesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'asistenciaMesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$asistenciaMesHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<AsistenciaMes>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<AsistenciaMes> create(Ref ref) {
    return asistenciaMes(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<AsistenciaMes> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<AsistenciaMes>>(value),
    );
  }
}

String _$asistenciaMesHash() => r'81a04182e717923528dd43d9f442fad4b0327c51';

/// Foto de un tramo: primero la del dispositivo; si no está, una URL
/// firmada de 60 s del bucket privado `comprobantes`. No se guarda en caché
/// (el provider se descarta al cerrar la foto).

@ProviderFor(fotoComprobante)
final fotoComprobanteProvider = FotoComprobanteFamily._();

/// Foto de un tramo: primero la del dispositivo; si no está, una URL
/// firmada de 60 s del bucket privado `comprobantes`. No se guarda en caché
/// (el provider se descarta al cerrar la foto).

final class FotoComprobanteProvider
    extends
        $FunctionalProvider<
          AsyncValue<FotoComprobante>,
          FotoComprobante,
          FutureOr<FotoComprobante>
        >
    with $FutureModifier<FotoComprobante>, $FutureProvider<FotoComprobante> {
  /// Foto de un tramo: primero la del dispositivo; si no está, una URL
  /// firmada de 60 s del bucket privado `comprobantes`. No se guarda en caché
  /// (el provider se descarta al cerrar la foto).
  FotoComprobanteProvider._({
    required FotoComprobanteFamily super.from,
    required ({String? localRef, String? remotePath}) super.argument,
  }) : super(
         retry: null,
         name: r'fotoComprobanteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fotoComprobanteHash();

  @override
  String toString() {
    return r'fotoComprobanteProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<FotoComprobante> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FotoComprobante> create(Ref ref) {
    final argument = this.argument as ({String? localRef, String? remotePath});
    return fotoComprobante(
      ref,
      localRef: argument.localRef,
      remotePath: argument.remotePath,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FotoComprobanteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fotoComprobanteHash() => r'b47ea743db472760e738b7f054409491be1ada3e';

/// Foto de un tramo: primero la del dispositivo; si no está, una URL
/// firmada de 60 s del bucket privado `comprobantes`. No se guarda en caché
/// (el provider se descarta al cerrar la foto).

final class FotoComprobanteFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<FotoComprobante>,
          ({String? localRef, String? remotePath})
        > {
  FotoComprobanteFamily._()
    : super(
        retry: null,
        name: r'fotoComprobanteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Foto de un tramo: primero la del dispositivo; si no está, una URL
  /// firmada de 60 s del bucket privado `comprobantes`. No se guarda en caché
  /// (el provider se descarta al cerrar la foto).

  FotoComprobanteProvider call({String? localRef, String? remotePath}) =>
      FotoComprobanteProvider._(
        argument: (localRef: localRef, remotePath: remotePath),
        from: this,
      );

  @override
  String toString() => r'fotoComprobanteProvider';
}
