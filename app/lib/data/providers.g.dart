// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Reloj de la app (se reemplaza en los tests).

@ProviderFor(clock)
final clockProvider = ClockProvider._();

/// Reloj de la app (se reemplaza en los tests).

final class ClockProvider
    extends
        $FunctionalProvider<
          DateTime Function(),
          DateTime Function(),
          DateTime Function()
        >
    with $Provider<DateTime Function()> {
  /// Reloj de la app (se reemplaza en los tests).
  ClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clockHash();

  @$internal
  @override
  $ProviderElement<DateTime Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DateTime Function() create(Ref ref) {
    return clock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime Function()>(value),
    );
  }
}

String _$clockHash() => r'3f65ad34ac6fcd532de9004042bdf2ed2bd85b13';

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'8b7e1ecbff8e0b353faaea23bdfc50530ee3be02';

@ProviderFor(photoStore)
final photoStoreProvider = PhotoStoreProvider._();

final class PhotoStoreProvider
    extends $FunctionalProvider<PhotoStore, PhotoStore, PhotoStore>
    with $Provider<PhotoStore> {
  PhotoStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoStoreHash();

  @$internal
  @override
  $ProviderElement<PhotoStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PhotoStore create(Ref ref) {
    return photoStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhotoStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhotoStore>(value),
    );
  }
}

String _$photoStoreHash() => r'561c4637b21485d1379f838ff5ad962c13b85f7b';

@ProviderFor(photoCapture)
final photoCaptureProvider = PhotoCaptureProvider._();

final class PhotoCaptureProvider
    extends $FunctionalProvider<PhotoCapture, PhotoCapture, PhotoCapture>
    with $Provider<PhotoCapture> {
  PhotoCaptureProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoCaptureProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoCaptureHash();

  @$internal
  @override
  $ProviderElement<PhotoCapture> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PhotoCapture create(Ref ref) {
    return photoCapture(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhotoCapture value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhotoCapture>(value),
    );
  }
}

String _$photoCaptureHash() => r'584e4a7fc158dfae924ed0e3c5c70229c7c0e959';

@ProviderFor(photoCompressor)
final photoCompressorProvider = PhotoCompressorProvider._();

final class PhotoCompressorProvider
    extends
        $FunctionalProvider<PhotoCompressor, PhotoCompressor, PhotoCompressor>
    with $Provider<PhotoCompressor> {
  PhotoCompressorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoCompressorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoCompressorHash();

  @$internal
  @override
  $ProviderElement<PhotoCompressor> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PhotoCompressor create(Ref ref) {
    return photoCompressor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhotoCompressor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhotoCompressor>(value),
    );
  }
}

String _$photoCompressorHash() => r'994b6f5f6968ab98373806d2138ca84b850a1a83';

@ProviderFor(fichadasRepository)
final fichadasRepositoryProvider = FichadasRepositoryProvider._();

final class FichadasRepositoryProvider
    extends
        $FunctionalProvider<
          FichadasRepository,
          FichadasRepository,
          FichadasRepository
        >
    with $Provider<FichadasRepository> {
  FichadasRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fichadasRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fichadasRepositoryHash();

  @$internal
  @override
  $ProviderElement<FichadasRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FichadasRepository create(Ref ref) {
    return fichadasRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FichadasRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FichadasRepository>(value),
    );
  }
}

String _$fichadasRepositoryHash() =>
    r'a7ed1c421ca6f3202bf2afa218daabc6de799d44';

@ProviderFor(fichadasRemote)
final fichadasRemoteProvider = FichadasRemoteProvider._();

final class FichadasRemoteProvider
    extends $FunctionalProvider<FichadasRemote, FichadasRemote, FichadasRemote>
    with $Provider<FichadasRemote> {
  FichadasRemoteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fichadasRemoteProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fichadasRemoteHash();

  @$internal
  @override
  $ProviderElement<FichadasRemote> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FichadasRemote create(Ref ref) {
    return fichadasRemote(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FichadasRemote value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FichadasRemote>(value),
    );
  }
}

String _$fichadasRemoteHash() => r'773800b0914c7806cd2cee4da6805c23693f2ec9';

@ProviderFor(syncService)
final syncServiceProvider = SyncServiceProvider._();

final class SyncServiceProvider
    extends $FunctionalProvider<SyncService, SyncService, SyncService>
    with $Provider<SyncService> {
  SyncServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncServiceHash();

  @$internal
  @override
  $ProviderElement<SyncService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncService create(Ref ref) {
    return syncService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncService>(value),
    );
  }
}

String _$syncServiceHash() => r'f13b1506a1374150a99483423e77d9a0efdbe358';

/// `true` si el dispositivo tiene alguna red (no garantiza internet).

@ProviderFor(connectivityOnline)
final connectivityOnlineProvider = ConnectivityOnlineProvider._();

/// `true` si el dispositivo tiene alguna red (no garantiza internet).

final class ConnectivityOnlineProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// `true` si el dispositivo tiene alguna red (no garantiza internet).
  ConnectivityOnlineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectivityOnlineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectivityOnlineHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return connectivityOnline(ref);
  }
}

String _$connectivityOnlineHash() =>
    r'7d5f30ca902177a0fc40018daea98a4a941ac5dc';

/// Cada cuánto se reintenta la sincronización con la app abierta. `null`
/// desactiva el reintento periódico (tests).

@ProviderFor(syncRetryInterval)
final syncRetryIntervalProvider = SyncRetryIntervalProvider._();

/// Cada cuánto se reintenta la sincronización con la app abierta. `null`
/// desactiva el reintento periódico (tests).

final class SyncRetryIntervalProvider
    extends $FunctionalProvider<Duration?, Duration?, Duration?>
    with $Provider<Duration?> {
  /// Cada cuánto se reintenta la sincronización con la app abierta. `null`
  /// desactiva el reintento periódico (tests).
  SyncRetryIntervalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncRetryIntervalProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncRetryIntervalHash();

  @$internal
  @override
  $ProviderElement<Duration?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Duration? create(Ref ref) {
    return syncRetryInterval(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Duration? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Duration?>(value),
    );
  }
}

String _$syncRetryIntervalHash() => r'a50e8ced10512efafc298546035884d35022a658';
