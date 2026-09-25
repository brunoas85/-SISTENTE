import 'dart:typed_data';

import '../photos/photo_compressor.dart';

/// Tamaño máximo de un adjunto (igual que `file_size_limit` del bucket
/// `comprobantes`: 10 MB).
const attachmentMaxBytes = 10 * 1024 * 1024;

/// El archivo no se puede adjuntar. El mensaje es para el usuario.
class AttachmentException implements Exception {
  const AttachmentException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Adjunto listo para guardar: imagen comprimida en JPEG o PDF tal cual.
class PreparedAttachment {
  const PreparedAttachment({required this.bytes, required this.extension});

  final Uint8List bytes;

  /// `jpg` o `pdf`.
  final String extension;

  bool get isPdf => extension == 'pdf';
  String get contentType => contentTypeForExtension(extension);
}

/// Extensión (sin punto y en minúsculas) de una ruta o referencia, o `null`.
String? extensionOf(String? ref) {
  if (ref == null) return null;
  final name = ref.split(RegExp(r'[/\\]')).last;
  final dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) return null;
  return name.substring(dot + 1).toLowerCase();
}

/// Tipo MIME para subir a Storage (el bucket acepta JPEG, PNG, WebP y PDF).
String contentTypeForExtension(String? extension) => switch (extension) {
  'pdf' => 'application/pdf',
  'png' => 'image/png',
  'webp' => 'image/webp',
  _ => 'image/jpeg',
};

/// `true` si los bytes empiezan con la firma de un PDF (`%PDF`).
bool looksLikePdf(Uint8List bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x25 &&
    bytes[1] == 0x50 &&
    bytes[2] == 0x44 &&
    bytes[3] == 0x46;

/// Prepara un archivo elegido por el usuario:
/// - un PDF se guarda tal cual;
/// - una imagen se comprime igual que las fotos de fichada (lado largo ≤
///   1600 px, JPEG 80 %) con [compress].
///
/// Lanza [AttachmentException] si no es imagen ni PDF o si supera
/// [attachmentMaxBytes].
Future<PreparedAttachment> prepareAttachment(
  Uint8List bytes, {
  required PhotoCompressor compress,
}) async {
  if (looksLikePdf(bytes)) {
    if (bytes.length > attachmentMaxBytes) {
      throw const AttachmentException('El PDF supera los 10 MB.');
    }
    return PreparedAttachment(bytes: bytes, extension: 'pdf');
  }
  final Uint8List jpeg;
  try {
    jpeg = await compress(bytes);
  } on PhotoFormatException {
    throw const AttachmentException(
      'El archivo no es una imagen ni un PDF. Elegí una foto o un PDF.',
    );
  }
  if (jpeg.length > attachmentMaxBytes) {
    throw const AttachmentException('La imagen supera los 10 MB.');
  }
  return PreparedAttachment(bytes: jpeg, extension: 'jpg');
}

/// Qué hacer con el adjunto al guardar.
sealed class CambioAdjunto {
  const CambioAdjunto();
}

/// Dejar el adjunto como está.
class MantenerAdjunto extends CambioAdjunto {
  const MantenerAdjunto();
}

/// Quitar el adjunto.
class QuitarAdjunto extends CambioAdjunto {
  const QuitarAdjunto();
}

/// Reemplazar (o agregar) el adjunto.
class NuevoAdjunto extends CambioAdjunto {
  const NuevoAdjunto(this.archivo);
  final PreparedAttachment archivo;
}
