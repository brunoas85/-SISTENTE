import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/auth/auth_providers.dart';
import '../../data/local/app_database.dart';
import '../../data/providers.dart';
import '../../data/sync/fichadas_remote.dart';

part 'cursos_providers.g.dart';

/// Cursos activos (desde la base local), los más recientes primero.
@riverpod
Stream<List<LocalCurso>> misCursos(Ref ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  return ref.watch(cursosRepositoryProvider).watchCursos(userId);
}

/// Abre una URL fuera de la app (navegador o visor de PDF del sistema).
/// Devuelve `false` si no se pudo. Se reemplaza en los tests.
@Riverpod(keepAlive: true)
Future<bool> Function(Uri) urlOpener(Ref ref) =>
    (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);

/// Cómo se puede mostrar un certificado.
sealed class VistaCertificado {
  const VistaCertificado();
}

/// Imagen guardada en el dispositivo.
class CertificadoImagenLocal extends VistaCertificado {
  const CertificadoImagenLocal(this.bytes);
  final Uint8List bytes;
}

/// Imagen que está solo en el servidor: URL firmada de 60 s.
class CertificadoImagenFirmada extends VistaCertificado {
  const CertificadoImagenFirmada(this.url);
  final String url;
}

/// PDF subido: se abre afuera con una URL firmada de 60 s pedida al tocar
/// "Abrir PDF" (así no vence mientras se lee el diálogo).
class CertificadoPdfRemoto extends VistaCertificado {
  const CertificadoPdfRemoto(this.path);
  final String path;
}

/// PDF que todavía está solo en el dispositivo.
class CertificadoPdfLocal extends VistaCertificado {
  const CertificadoPdfLocal(this.bytes);
  final int bytes;
}

/// No se puede mostrar el certificado. El mensaje es para el usuario.
class CertificadoNoDisponibleException implements Exception {
  const CertificadoNoDisponibleException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Certificado de un curso: primero el del dispositivo; si no está, el del
/// bucket privado `certificados` con una URL firmada de 60 s. No se guarda
/// en caché (el provider se descarta al cerrar el diálogo).
@riverpod
Future<VistaCertificado> certificadoCurso(
  Ref ref, {
  String? localRef,
  String? remotePath,
  required bool esPdf,
}) async {
  if (esPdf && remotePath != null) return CertificadoPdfRemoto(remotePath);
  if (localRef != null) {
    final bytes = await ref
        .read(cursosRepositoryProvider)
        .readCertificado(localRef);
    if (bytes != null) {
      return esPdf
          ? CertificadoPdfLocal(bytes.length)
          : CertificadoImagenLocal(bytes);
    }
  }
  if (remotePath == null) {
    throw const CertificadoNoDisponibleException(
      'El certificado no está en este dispositivo y todavía no se subió.',
    );
  }
  try {
    final url = await ref
        .read(cursosRemoteProvider)
        .signedCertificadoUrl(remotePath);
    return CertificadoImagenFirmada(url);
  } on RemoteUnavailableException {
    throw const CertificadoNoDisponibleException(
      'Sin conexión: el certificado está solo en el servidor.',
    );
  } on RemoteRejectedException catch (e) {
    throw CertificadoNoDisponibleException(
      'No se pudo abrir el certificado: ${e.message}',
    );
  }
}
