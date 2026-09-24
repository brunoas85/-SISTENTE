import 'dart:typed_data';

import 'package:asistente/data/attachments/attachment.dart';
import 'package:asistente/data/photos/photo_compressor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../support/fakes.dart';

void main() {
  group('prepareAttachment', () {
    test('un PDF se guarda tal cual', () async {
      var compressCalls = 0;
      final a = await prepareAttachment(
        fakePdf(),
        compress: (b) async {
          compressCalls++;
          return b;
        },
      );
      expect(a.extension, 'pdf');
      expect(a.contentType, 'application/pdf');
      expect(a.bytes, fakePdf());
      expect(compressCalls, 0);
    });

    test('una imagen se comprime como las fotos de fichada', () async {
      final png = img.encodePng(img.Image(width: 3200, height: 1000));
      final a = await prepareAttachment(
        png,
        compress: compressPhotoInBackground,
      );
      expect(a.extension, 'jpg');
      expect(a.contentType, 'image/jpeg');
      final decoded = img.decodeJpg(a.bytes)!;
      expect(decoded.width, photoMaxLongSide);
      expect(decoded.height, 500);
    });

    test('algo que no es imagen ni PDF se rechaza', () async {
      await expectLater(
        prepareAttachment(
          Uint8List.fromList('texto ficticio'.codeUnits),
          compress: (b) async => compressPhoto(b),
        ),
        throwsA(isA<AttachmentException>()),
      );
    });

    test('un PDF de más de 10 MB se rechaza', () async {
      final grande = Uint8List(attachmentMaxBytes + 1)..setAll(0, fakePdf());
      await expectLater(
        prepareAttachment(grande, compress: (b) async => b),
        throwsA(isA<AttachmentException>()),
      );
    });
  });

  test('extensionOf y contentTypeForExtension', () {
    expect(extensionOf('mem:abc_adjunto.PDF'), 'pdf');
    expect(extensionOf(r'C:\datos\abc_adjunto.jpg'), 'jpg');
    expect(extensionOf('sin-extension'), isNull);
    expect(extensionOf(null), isNull);
    expect(contentTypeForExtension('pdf'), 'application/pdf');
    expect(contentTypeForExtension('png'), 'image/png');
    expect(contentTypeForExtension(null), 'image/jpeg');
  });
}
