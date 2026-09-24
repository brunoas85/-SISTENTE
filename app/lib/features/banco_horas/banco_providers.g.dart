// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'banco_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Movimientos manuales activos del banco (desde la base local), del más
/// nuevo al más viejo.

@ProviderFor(misMovimientos)
final misMovimientosProvider = MisMovimientosProvider._();

/// Movimientos manuales activos del banco (desde la base local), del más
/// nuevo al más viejo.

final class MisMovimientosProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LocalMovimiento>>,
          List<LocalMovimiento>,
          Stream<List<LocalMovimiento>>
        >
    with
        $FutureModifier<List<LocalMovimiento>>,
        $StreamProvider<List<LocalMovimiento>> {
  /// Movimientos manuales activos del banco (desde la base local), del más
  /// nuevo al más viejo.
  MisMovimientosProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'misMovimientosProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$misMovimientosHash();

  @$internal
  @override
  $StreamProviderElement<List<LocalMovimiento>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<LocalMovimiento>> create(Ref ref) {
    return misMovimientos(ref);
  }
}

String _$misMovimientosHash() => r'c2ef9230cb265a6d75b54afd4563586b812603a4';

/// Catálogo de tipos de documento GDE (incluidos los borrados), por código.

@ProviderFor(tiposDocumento)
final tiposDocumentoProvider = TiposDocumentoProvider._();

/// Catálogo de tipos de documento GDE (incluidos los borrados), por código.

final class TiposDocumentoProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LocalTipoDocumento>>,
          List<LocalTipoDocumento>,
          Stream<List<LocalTipoDocumento>>
        >
    with
        $FutureModifier<List<LocalTipoDocumento>>,
        $StreamProvider<List<LocalTipoDocumento>> {
  /// Catálogo de tipos de documento GDE (incluidos los borrados), por código.
  TiposDocumentoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tiposDocumentoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tiposDocumentoHash();

  @$internal
  @override
  $StreamProviderElement<List<LocalTipoDocumento>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<LocalTipoDocumento>> create(Ref ref) {
    return tiposDocumento(ref);
  }
}

String _$tiposDocumentoHash() => r'd49a0844b8235e27d5c7f0d6350880e5d092b428';
