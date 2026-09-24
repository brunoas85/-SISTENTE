// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resumen_banco.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(resumenBanco)
final resumenBancoProvider = ResumenBancoProvider._();

final class ResumenBancoProvider
    extends
        $FunctionalProvider<
          AsyncValue<ResumenBanco>,
          AsyncValue<ResumenBanco>,
          AsyncValue<ResumenBanco>
        >
    with $Provider<AsyncValue<ResumenBanco>> {
  ResumenBancoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resumenBancoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resumenBancoHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<ResumenBanco>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<ResumenBanco> create(Ref ref) {
    return resumenBanco(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<ResumenBanco> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<ResumenBanco>>(value),
    );
  }
}

String _$resumenBancoHash() => r'6b2385f41da2708dfa58048ea1a7a79e1fdc0357';
