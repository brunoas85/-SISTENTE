// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'perfil_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Perfil del usuario guardado en el dispositivo (`null` si todavía no se
/// bajó ni se eligió nada acá).

@ProviderFor(miPerfil)
final miPerfilProvider = MiPerfilProvider._();

/// Perfil del usuario guardado en el dispositivo (`null` si todavía no se
/// bajó ni se eligió nada acá).

final class MiPerfilProvider
    extends $FunctionalProvider<AsyncValue<Perfil?>, Perfil?, Stream<Perfil?>>
    with $FutureModifier<Perfil?>, $StreamProvider<Perfil?> {
  /// Perfil del usuario guardado en el dispositivo (`null` si todavía no se
  /// bajó ni se eligió nada acá).
  MiPerfilProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'miPerfilProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$miPerfilHash();

  @$internal
  @override
  $StreamProviderElement<Perfil?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Perfil?> create(Ref ref) {
    return miPerfil(ref);
  }
}

String _$miPerfilHash() => r'eeab725b2084b7ac1e3a8cccad5292570af27db0';

/// Hay que pedir el agrupamiento: el perfil local dice que no se eligió, o
/// no hay perfil local y ya terminó una pasada del sync (con o sin red), así
/// no se pregunta mientras se está bajando.

@ProviderFor(pedirAgrupamiento)
final pedirAgrupamientoProvider = PedirAgrupamientoProvider._();

/// Hay que pedir el agrupamiento: el perfil local dice que no se eligió, o
/// no hay perfil local y ya terminó una pasada del sync (con o sin red), así
/// no se pregunta mientras se está bajando.

final class PedirAgrupamientoProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Hay que pedir el agrupamiento: el perfil local dice que no se eligió, o
  /// no hay perfil local y ya terminó una pasada del sync (con o sin red), así
  /// no se pregunta mientras se está bajando.
  PedirAgrupamientoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pedirAgrupamientoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pedirAgrupamientoHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return pedirAgrupamiento(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$pedirAgrupamientoHash() => r'ca5881426e98fe3158f5bdfd32381e2d8ebcddde';
