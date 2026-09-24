import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

/// Archivo elegido por el usuario (sin procesar).
class PickedFile {
  const PickedFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// Elige un archivo (imagen o PDF) para adjuntar a un movimiento del banco.
abstract interface class AttachmentPicker {
  /// Devuelve el archivo elegido, o `null` si el usuario canceló.
  Future<PickedFile?> pickImageOrPdf();
}

/// Implementación con `file_selector` (Android, iOS, web y Windows). En
/// iOS abre el selector de documentos: no necesita permisos extra en
/// `Info.plist`.
class FileSelectorAttachmentPicker implements AttachmentPicker {
  const FileSelectorAttachmentPicker();

  static const _group = XTypeGroup(
    label: 'Imágenes y PDF',
    extensions: ['jpg', 'jpeg', 'png', 'webp', 'heic', 'pdf'],
    mimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'],
    uniformTypeIdentifiers: ['public.image', 'com.adobe.pdf'],
    webWildCards: ['image/*', 'application/pdf'],
  );

  @override
  Future<PickedFile?> pickImageOrPdf() async {
    final file = await openFile(
      acceptedTypeGroups: const [_group],
      confirmButtonText: 'Adjuntar',
    );
    if (file == null) return null;
    return PickedFile(name: file.name, bytes: await file.readAsBytes());
  }
}
