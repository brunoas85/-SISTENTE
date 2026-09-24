import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../local/app_database.dart';
import 'photo_store.dart';

PhotoStore createPhotoStore(AppDatabase db) => FilePhotoStore();

/// Fotos como archivos en la carpeta de soporte de la app
/// (`…/comprobantes/{nombre}`). La referencia local es la ruta absoluta.
class FilePhotoStore implements PhotoStore {
  FilePhotoStore({Future<Directory> Function()? baseDir})
    : _baseDir = baseDir ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _baseDir;

  @override
  Future<String> save(String name, Uint8List bytes) async {
    final dir = Directory(p.join((await _baseDir()).path, 'comprobantes'));
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  @override
  Future<Uint8List?> read(String localRef) async {
    final file = File(localRef);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  Future<void> delete(String localRef) async {
    final file = File(localRef);
    if (await file.exists()) await file.delete();
  }
}
