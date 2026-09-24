// Fakes para tests: sin red real ni datos reales (todo ficticio).
import 'dart:async';

import 'package:asistente/core/auth/auth_repository.dart';
import 'package:asistente/data/fichadas/remote_fichada.dart';
import 'package:asistente/data/local/app_database.dart';
import 'package:asistente/data/photos/photo_capture.dart';
import 'package:asistente/data/photos/photo_store.dart';
import 'package:asistente/data/sync/fichadas_remote.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:image/image.dart' as img;

/// Usuario ficticio.
const fakeUserId = '11111111-2222-4333-8444-555555555555';

AppDatabase newTestDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

/// JPEG chico generado en el momento (no es una foto real).
Uint8List fakeJpeg({int width = 8, int height = 6}) =>
    img.encodeJpg(img.Image(width: width, height: height));

/// Reloj que avanza un segundo en cada lectura.
DateTime Function() steppingClock(DateTime start) {
  var t = start;
  return () {
    final now = t;
    t = t.add(const Duration(seconds: 1));
    return now;
  };
}

/// Generador de ids predecible.
String Function() sequentialIds() {
  var n = 0;
  return () {
    n++;
    return '00000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';
  };
}

class InMemoryPhotoStore implements PhotoStore {
  final files = <String, Uint8List>{};

  @override
  Future<String> save(String name, Uint8List bytes) async {
    files['mem:$name'] = bytes;
    return 'mem:$name';
  }

  @override
  Future<Uint8List?> read(String localRef) async => files[localRef];

  @override
  Future<void> delete(String localRef) async => files.remove(localRef);
}

/// Backend de mentira. Guarda en memoria lo que se sube y deja simular
/// falta de red y rechazos.
class FakeFichadasRemote implements FichadasRemote {
  bool online = true;

  /// Cantidad de upserts que van a fallar por falta de red.
  int upsertsOffline = 0;

  /// Si no es `null`, el upsert de esa fichada se rechaza con este mensaje.
  final rejectUpsert = <String, String>{};

  /// Se llama durante el upsert (para simular cambios concurrentes).
  Future<void> Function(RemoteFichada)? onUpsert;

  /// Registro de llamadas, en orden (`upload:<path>` / `upsert:<id>`).
  final calls = <String>[];
  final storage = <String, Uint8List>{};
  final rows = <String, RemoteFichada>{};
  var feriados = <RemoteFeriado>[];
  DateTime serverNow = DateTime.utc(2026, 9, 24, 12);
  DateTime? lastSince;

  void _checkOnline() {
    if (!online) throw const RemoteUnavailableException('Sin conexión');
  }

  @override
  Future<void> uploadPhoto({
    required String path,
    required Uint8List bytes,
  }) async {
    _checkOnline();
    calls.add('upload:$path');
    storage[path] = bytes;
  }

  @override
  Future<void> upsertFichada(RemoteFichada fichada) async {
    _checkOnline();
    calls.add('upsert:${fichada.id}');
    if (upsertsOffline > 0) {
      upsertsOffline--;
      throw const RemoteUnavailableException('Se cortó la conexión');
    }
    final reject = rejectUpsert[fichada.id];
    if (reject != null) throw RemoteRejectedException(reject);
    await onUpsert?.call(fichada);
    serverNow = serverNow.add(const Duration(seconds: 1));
    rows[fichada.id] = _withUpdatedAt(fichada, serverNow);
  }

  @override
  Future<List<RemoteFichada>> fetchFichadasChangedSince(DateTime? since) async {
    _checkOnline();
    lastSince = since;
    final list =
        rows.values
            .where((r) => since == null || !r.updatedAt!.isBefore(since))
            .toList()
          ..sort((a, b) => a.updatedAt!.compareTo(b.updatedAt!));
    return list;
  }

  @override
  Future<List<RemoteFeriado>> fetchFeriados() async {
    _checkOnline();
    return feriados;
  }

  /// Simula un cambio hecho desde otro dispositivo.
  void putFromOtherDevice(RemoteFichada f) {
    serverNow = serverNow.add(const Duration(seconds: 1));
    rows[f.id] = _withUpdatedAt(f, serverNow);
  }

  static RemoteFichada _withUpdatedAt(RemoteFichada f, DateTime at) =>
      RemoteFichada(
        id: f.id,
        userId: f.userId,
        fecha: f.fecha,
        ingresoMin: f.ingresoMin,
        egresoMin: f.egresoMin,
        ingresoOriginalMin: f.ingresoOriginalMin,
        egresoOriginalMin: f.egresoOriginalMin,
        editado: f.editado,
        fotoIngresoPath: f.fotoIngresoPath,
        fotoEgresoPath: f.fotoEgresoPath,
        observacion: f.observacion,
        deletedAt: f.deletedAt,
        updatedAt: at,
      );
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.userId});

  String? userId;
  final _changes = StreamController<String?>.broadcast();

  @override
  String? get currentUserId => userId;

  @override
  Stream<String?> get userIdChanges => _changes.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (password != 'clave-ficticia') {
      throw const AuthFailure('El email o la contraseña no son correctos.');
    }
    userId = fakeUserId;
    _changes.add(userId);
  }

  @override
  Future<void> signOut() async {
    userId = null;
    _changes.add(null);
  }
}

class FakePhotoCapture implements PhotoCapture {
  FakePhotoCapture(this.result);

  /// Lo que devuelve [capture] (`null` = cancelado).
  Uint8List? result;
  int calls = 0;

  @override
  bool get usesCamera => true;

  @override
  Future<Uint8List?> capture() async {
    calls++;
    return result;
  }
}
