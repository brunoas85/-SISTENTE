// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cursos_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Cursos activos (desde la base local), los más recientes primero.

@ProviderFor(misCursos)
final misCursosProvider = MisCursosProvider._();

/// Cursos activos (desde la base local), los más recientes primero.

final class MisCursosProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LocalCurso>>,
          List<LocalCurso>,
          Stream<List<LocalCurso>>
        >
    with $FutureModifier<List<LocalCurso>>, $StreamProvider<List<LocalCurso>> {
  /// Cursos activos (desde la base local), los más recientes primero.
  MisCursosProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'misCursosProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$misCursosHash();

  @$internal
  @override
  $StreamProviderElement<List<LocalCurso>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<LocalCurso>> create(Ref ref) {
    return misCursos(ref);
  }
}

String _$misCursosHash() => r'6c20db4173a9b424c480acd9e3fde27b184a64ad';

/// Abre una URL fuera de la app (navegador o visor de PDF del sistema).
/// Devuelve `false` si no se pudo. Se reemplaza en los tests.

@ProviderFor(urlOpener)
final urlOpenerProvider = UrlOpenerProvider._();

/// Abre una URL fuera de la app (navegador o visor de PDF del sistema).
/// Devuelve `false` si no se pudo. Se reemplaza en los tests.

final class UrlOpenerProvider
    extends
        $FunctionalProvider<
          Future<bool> Function(Uri),
          Future<bool> Function(Uri),
          Future<bool> Function(Uri)
        >
    with $Provider<Future<bool> Function(Uri)> {
  /// Abre una URL fuera de la app (navegador o visor de PDF del sistema).
  /// Devuelve `false` si no se pudo. Se reemplaza en los tests.
  UrlOpenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'urlOpenerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$urlOpenerHash();

  @$internal
  @override
  $ProviderElement<Future<bool> Function(Uri)> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<bool> Function(Uri) create(Ref ref) {
    return urlOpener(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<bool> Function(Uri) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<bool> Function(Uri)>(value),
    );
  }
}

String _$urlOpenerHash() => r'4446bd305eaa13c6f86c73cb59f88d0920efc4bf';

/// Certificado de un curso: primero el del dispositivo; si no está, el del
/// bucket privado `certificados` con una URL firmada de 60 s. No se guarda
/// en caché (el provider se descarta al cerrar el diálogo).

@ProviderFor(certificadoCurso)
final certificadoCursoProvider = CertificadoCursoFamily._();

/// Certificado de un curso: primero el del dispositivo; si no está, el del
/// bucket privado `certificados` con una URL firmada de 60 s. No se guarda
/// en caché (el provider se descarta al cerrar el diálogo).

final class CertificadoCursoProvider
    extends
        $FunctionalProvider<
          AsyncValue<VistaCertificado>,
          VistaCertificado,
          FutureOr<VistaCertificado>
        >
    with $FutureModifier<VistaCertificado>, $FutureProvider<VistaCertificado> {
  /// Certificado de un curso: primero el del dispositivo; si no está, el del
  /// bucket privado `certificados` con una URL firmada de 60 s. No se guarda
  /// en caché (el provider se descarta al cerrar el diálogo).
  CertificadoCursoProvider._({
    required CertificadoCursoFamily super.from,
    required ({String? localRef, String? remotePath, bool esPdf})
    super.argument,
  }) : super(
         retry: null,
         name: r'certificadoCursoProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$certificadoCursoHash();

  @override
  String toString() {
    return r'certificadoCursoProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<VistaCertificado> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<VistaCertificado> create(Ref ref) {
    final argument =
        this.argument as ({String? localRef, String? remotePath, bool esPdf});
    return certificadoCurso(
      ref,
      localRef: argument.localRef,
      remotePath: argument.remotePath,
      esPdf: argument.esPdf,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CertificadoCursoProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$certificadoCursoHash() => r'd999fcc00676b79d43750c0b9ba5b4f021eaf62b';

/// Certificado de un curso: primero el del dispositivo; si no está, el del
/// bucket privado `certificados` con una URL firmada de 60 s. No se guarda
/// en caché (el provider se descarta al cerrar el diálogo).

final class CertificadoCursoFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<VistaCertificado>,
          ({String? localRef, String? remotePath, bool esPdf})
        > {
  CertificadoCursoFamily._()
    : super(
        retry: null,
        name: r'certificadoCursoProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Certificado de un curso: primero el del dispositivo; si no está, el del
  /// bucket privado `certificados` con una URL firmada de 60 s. No se guarda
  /// en caché (el provider se descarta al cerrar el diálogo).

  CertificadoCursoProvider call({
    String? localRef,
    String? remotePath,
    required bool esPdf,
  }) => CertificadoCursoProvider._(
    argument: (localRef: localRef, remotePath: remotePath, esPdf: esPdf),
    from: this,
  );

  @override
  String toString() => r'certificadoCursoProvider';
}
