import 'dart:typed_data';

import 'package:asistente/data/photos/photo_compressor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  bool isJpeg(Uint8List b) => b.length > 3 && b[0] == 0xFF && b[1] == 0xD8;

  test('reduce el lado largo a 1600 px y devuelve JPEG (horizontal)', () {
    final png = img.encodePng(img.Image(width: 3200, height: 2400));
    final out = compressPhoto(png);
    final decoded = img.decodeJpg(out)!;
    expect(isJpeg(out), isTrue);
    expect(decoded.width, 1600);
    expect(decoded.height, 1200);
  });

  test('reduce el lado largo a 1600 px (vertical)', () {
    final jpg = img.encodeJpg(img.Image(width: 1000, height: 2000));
    final decoded = img.decodeJpg(compressPhoto(jpg))!;
    expect(decoded.height, 1600);
    expect(decoded.width, 800);
  });

  test('no agranda una imagen chica', () {
    final jpg = img.encodeJpg(img.Image(width: 640, height: 480));
    final decoded = img.decodeJpg(compressPhoto(jpg))!;
    expect(decoded.width, 640);
    expect(decoded.height, 480);
  });

  test('aplica la orientación EXIF', () {
    final image = img.Image(width: 40, height: 20);
    image.exif.imageIfd.orientation = 6; // rotada 90°
    final decoded = img.decodeJpg(compressPhoto(img.encodeJpg(image)))!;
    expect(decoded.width, 20);
    expect(decoded.height, 40);
  });

  test('rechaza bytes que no son una imagen', () {
    expect(
      () => compressPhoto(Uint8List.fromList([1, 2, 3, 4])),
      throwsA(isA<PhotoFormatException>()),
    );
  });
}
