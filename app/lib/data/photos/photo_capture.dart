import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'photo_compressor.dart';

class PhotoCaptureException implements Exception {
  const PhotoCaptureException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Saca (o elige) la foto del biométrico.
abstract interface class PhotoCapture {
  /// `true` si abre la cámara; `false` si pide un archivo (web/PC sin cámara).
  bool get usesCamera;

  /// Devuelve los bytes de la foto, o `null` si el usuario canceló.
  Future<Uint8List?> capture();
}

/// Implementación con `image_picker`: cámara en Android/iOS; en Windows,
/// selector de archivo. En web el navegador decide (en el celular ofrece la
/// cámara, en la PC abre el selector de archivos).
class ImagePickerPhotoCapture implements PhotoCapture {
  ImagePickerPhotoCapture([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  bool get usesCamera => _picker.supportsImageSource(ImageSource.camera);

  @override
  Future<Uint8List?> capture() async {
    try {
      final file = await _picker.pickImage(
        source: usesCamera ? ImageSource.camera : ImageSource.gallery,
        // Primera reducción nativa; después se normaliza con compressPhoto.
        maxWidth: photoMaxLongSide.toDouble(),
        maxHeight: photoMaxLongSide.toDouble(),
        imageQuality: photoJpegQuality,
        requestFullMetadata: false,
      );
      if (file == null) return null;
      return await file.readAsBytes();
    } on PlatformException catch (e) {
      if (e.code.contains('access_denied')) {
        throw const PhotoCaptureException(
          'La app no tiene permiso para usar la cámara. '
          'Habilitalo en la configuración del teléfono.',
        );
      }
      throw PhotoCaptureException('No se pudo abrir la cámara (${e.code}).');
    }
  }
}
