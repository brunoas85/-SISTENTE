// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Dispara la sincronización sola: al abrir la app (y al iniciar sesión), al
/// volver a primer plano, al recuperar la red, cada tanto mientras la app
/// está abierta y después de cada fichada.

@ProviderFor(SyncController)
final syncControllerProvider = SyncControllerProvider._();

/// Dispara la sincronización sola: al abrir la app (y al iniciar sesión), al
/// volver a primer plano, al recuperar la red, cada tanto mientras la app
/// está abierta y después de cada fichada.
final class SyncControllerProvider
    extends $NotifierProvider<SyncController, SyncUiState> {
  /// Dispara la sincronización sola: al abrir la app (y al iniciar sesión), al
  /// volver a primer plano, al recuperar la red, cada tanto mientras la app
  /// está abierta y después de cada fichada.
  SyncControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncControllerHash();

  @$internal
  @override
  SyncController create() => SyncController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncUiState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncUiState>(value),
    );
  }
}

String _$syncControllerHash() => r'e8893d5c3b81b741c0cea652aed14262897d5b48';

/// Dispara la sincronización sola: al abrir la app (y al iniciar sesión), al
/// volver a primer plano, al recuperar la red, cada tanto mientras la app
/// está abierta y después de cada fichada.

abstract class _$SyncController extends $Notifier<SyncUiState> {
  SyncUiState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SyncUiState, SyncUiState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SyncUiState, SyncUiState>,
              SyncUiState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
