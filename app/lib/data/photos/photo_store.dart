import 'dart:typed_data';

import 'package:drift/drift.dart';

import '../local/app_database.dart';
import 'photo_store_factory_stub.dart'
    if (dart.library.io) 'photo_store_factory_io.dart'
    as platform;

/// Guarda las fotos comprimidas en el dispositivo hasta que se suben.
abstract interface class PhotoStore {
  /// Guarda [bytes] con el nombre [name] y devuelve la referencia local.
  Future<String> save(String name, Uint8List bytes);

  /// Lee una foto guardada, o `null` si ya no existe.
  Future<Uint8List?> read(String localRef);

  Future<void> delete(String localRef);
}

/// Crea el [PhotoStore] de la plataforma: archivos en Android/iOS/Windows y
/// la base local en web.
PhotoStore createPlatformPhotoStore(AppDatabase db) =>
    platform.createPhotoStore(db);

/// Fotos dentro de la base drift (tabla `local_photos`). Se usa en web.
class DbPhotoStore implements PhotoStore {
  DbPhotoStore(this._db);

  final AppDatabase _db;
  static const _prefix = 'db:';

  @override
  Future<String> save(String name, Uint8List bytes) async {
    await _db
        .into(_db.localPhotos)
        .insertOnConflictUpdate(
          LocalPhotosCompanion.insert(key: name, bytes: bytes),
        );
    return '$_prefix$name';
  }

  @override
  Future<Uint8List?> read(String localRef) async {
    final row = await (_db.select(
      _db.localPhotos,
    )..where((t) => t.key.equals(_keyOf(localRef)))).getSingleOrNull();
    return row?.bytes;
  }

  @override
  Future<void> delete(String localRef) async {
    await (_db.delete(
      _db.localPhotos,
    )..where((t) => t.key.equals(_keyOf(localRef)))).go();
  }

  String _keyOf(String ref) =>
      ref.startsWith(_prefix) ? ref.substring(_prefix.length) : ref;
}
