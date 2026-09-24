import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Lado largo máximo de la foto que se guarda y se sube.
const photoMaxLongSide = 1600;

/// Calidad JPEG de la foto que se guarda y se sube.
const photoJpegQuality = 80;

class PhotoFormatException implements Exception {
  const PhotoFormatException();

  @override
  String toString() => 'El archivo no es una imagen válida.';
}

/// Comprime una foto: aplica la orientación EXIF, reduce el lado largo a
/// [photoMaxLongSide] px como máximo y la codifica en JPEG
/// ([photoJpegQuality] %). Nunca agranda la imagen.
///
/// Es Dart puro (paquete `image`), así que funciona igual en todas las
/// plataformas.
Uint8List compressPhoto(Uint8List input) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(input);
  } catch (_) {
    // Con bytes corruptos algunos decodificadores tiran en vez de devolver null.
    decoded = null;
  }
  if (decoded == null) throw const PhotoFormatException();
  var image = img.bakeOrientation(decoded);
  final longSide = math.max(image.width, image.height);
  if (longSide > photoMaxLongSide) {
    image = image.width >= image.height
        ? img.copyResize(
            image,
            width: photoMaxLongSide,
            interpolation: img.Interpolation.average,
          )
        : img.copyResize(
            image,
            height: photoMaxLongSide,
            interpolation: img.Interpolation.average,
          );
  }
  return img.encodeJpg(image, quality: photoJpegQuality);
}

/// Firma del compresor (se reemplaza en los tests).
typedef PhotoCompressor = Future<Uint8List> Function(Uint8List input);

/// [compressPhoto] en otro isolate (en web corre en el mismo hilo).
Future<Uint8List> compressPhotoInBackground(Uint8List input) =>
    compute(compressPhoto, input);
