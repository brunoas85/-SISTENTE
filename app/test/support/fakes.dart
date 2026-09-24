// Fakes para tests: sin red real ni datos reales (todo ficticio).
import 'dart:async';

import 'package:asistente/core/auth/auth_repository.dart';
import 'package:asistente/data/attachments/attachment_picker.dart';
import 'package:asistente/data/banco/remote_banco.dart';
import 'package:asistente/data/fichadas/remote_fichada.dart';
import 'package:asistente/data/local/app_database.dart';
import 'package:asistente/data/photos/photo_capture.dart';
import 'package:asistente/data/photos/photo_store.dart';
import 'package:asistente/data/sync/banco_remote.dart';
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

  /// Perfil en el servidor (`null` = sin fila).
  RemotePerfil? perfil;

  /// Si no es `null`, guardar el agrupamiento se rechaza con este mensaje.
  String? rejectPerfil;

  /// Simula que el servidor todavía no tiene `profiles.agrupamiento`.
  bool perfilSinColumna = false;

  /// Agrupamientos guardados, en orden.
  final perfilSaves = <String?>[];

  /// Cantidad de veces que se bajaron los feriados.
  int feriadosFetches = 0;
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

  /// Duraciones pedidas para las URLs firmadas, en orden.
  final signedUrlRequests = <(String, Duration)>[];

  @override
  Future<String> signedPhotoUrl(
    String path, {
    Duration expiresIn = const Duration(seconds: 60),
  }) async {
    _checkOnline();
    signedUrlRequests.add((path, expiresIn));
    return 'https://storage.example.invalid/firmada/$path?token=ficticio';
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
    feriadosFetches++;
    return feriados;
  }

  @override
  Future<RemotePerfil?> fetchPerfil(String userId) async {
    _checkOnline();
    if (perfilSinColumna) {
      throw const RemoteSchemaMissingException('falta la columna (ficticio)');
    }
    return perfil;
  }

  @override
  Future<void> saveAgrupamiento(String userId, String? agrupamiento) async {
    _checkOnline();
    if (perfilSinColumna) {
      throw const RemoteSchemaMissingException('falta la columna (ficticio)');
    }
    perfilSaves.add(agrupamiento);
    final reject = rejectPerfil;
    if (reject != null) throw RemoteRejectedException(reject);
    perfil = RemotePerfil(userId: userId, agrupamiento: agrupamiento);
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
        origen: f.origen,
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

/// Backend de mentira para el banco de horas (tipos de documento,
/// movimientos y adjuntos).
class FakeBancoRemote implements BancoRemote {
  bool online = true;

  /// Si no es `null`, el upsert de ese movimiento se rechaza con este
  /// mensaje.
  final rejectMovimiento = <String, String>{};

  /// Registro de llamadas, en orden (`upload:<path>`, `tipo:<id>`,
  /// `movimiento:<id>`).
  final calls = <String>[];
  final storage = <String, Uint8List>{};
  final contentTypes = <String, String>{};
  final tipos = <String, RemoteTipoDocumento>{};
  final movimientos = <String, RemoteMovimiento>{};
  DateTime serverNow = DateTime.utc(2026, 9, 24, 12);
  DateTime? lastMovimientosSince;

  void _checkOnline() {
    if (!online) throw const RemoteUnavailableException('Sin conexión');
  }

  DateTime _tick() => serverNow = serverNow.add(const Duration(seconds: 1));

  @override
  Future<void> uploadAdjunto({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    _checkOnline();
    calls.add('upload:$path');
    storage[path] = bytes;
    contentTypes[path] = contentType;
  }

  @override
  Future<void> upsertTipoDocumento(RemoteTipoDocumento tipo) async {
    _checkOnline();
    calls.add('tipo:${tipo.id}');
    tipos[tipo.id] = tipo.withUpdatedAt(_tick());
  }

  @override
  Future<void> upsertMovimiento(RemoteMovimiento movimiento) async {
    _checkOnline();
    calls.add('movimiento:${movimiento.id}');
    final reject = rejectMovimiento[movimiento.id];
    if (reject != null) throw RemoteRejectedException(reject);
    // FK compuesta: el tipo de documento tiene que existir y ser del usuario.
    final tipoId = movimiento.tipoDocumentoId;
    if (tipoId != null && tipos[tipoId]?.userId != movimiento.userId) {
      throw const RemoteRejectedException('FK banco_tipo_documento_fk');
    }
    // CHECK banco_alcance_solo_usufructo.
    if ((movimiento.tipo == 'usufructo') != (movimiento.alcance != null)) {
      throw const RemoteRejectedException('CHECK banco_alcance_solo_usufructo');
    }
    movimientos[movimiento.id] = movimiento.withUpdatedAt(_tick());
  }

  @override
  Future<List<RemoteTipoDocumento>> fetchTiposChangedSince(
    DateTime? since,
  ) async {
    _checkOnline();
    return tipos.values
        .where((r) => since == null || !r.updatedAt!.isBefore(since))
        .toList()
      ..sort((a, b) => a.updatedAt!.compareTo(b.updatedAt!));
  }

  @override
  Future<List<RemoteMovimiento>> fetchMovimientosChangedSince(
    DateTime? since,
  ) async {
    _checkOnline();
    lastMovimientosSince = since;
    return movimientos.values
        .where((r) => since == null || !r.updatedAt!.isBefore(since))
        .toList()
      ..sort((a, b) => a.updatedAt!.compareTo(b.updatedAt!));
  }

  /// Simula un movimiento cargado desde otro dispositivo.
  void putFromOtherDevice(RemoteMovimiento m) =>
      movimientos[m.id] = m.withUpdatedAt(_tick());
}

class FakeAttachmentPicker implements AttachmentPicker {
  FakeAttachmentPicker([this.result]);

  /// Lo que devuelve [pickImageOrPdf] (`null` = cancelado).
  PickedFile? result;
  int calls = 0;

  @override
  Future<PickedFile?> pickImageOrPdf() async {
    calls++;
    return result;
  }
}

/// Bytes que empiezan como un PDF (no es un documento real).
Uint8List fakePdf() => Uint8List.fromList('%PDF-1.4 ficticio'.codeUnits);

/// Días hábiles ficticios del 17/09/2026 al 23/09/2026 (jueves a
/// miércoles, sin el fin de semana).
const semanaFicticia = [
  '2026-09-17',
  '2026-09-18',
  '2026-09-21',
  '2026-09-22',
  '2026-09-23',
];

/// Inserta fichadas sincronizadas de 08:00 a 16:00 (jornada exacta de 8 h:
/// no suman ni restan) en [fechas]. La primera es el inicio del control.
Future<void> insertarJornadasExactas(
  AppDatabase db, [
  List<String> fechas = semanaFicticia,
]) async {
  for (final f in fechas) {
    await db
        .into(db.fichadas)
        .insert(
          FichadasCompanion.insert(
            id: 'jornada-$f',
            userId: fakeUserId,
            fecha: f,
            ingresoMin: 480,
            egresoMin: const Value(960),
            updatedAt: DateTime(2026, 9, 16),
            syncStatus: SyncStatus.synced,
          ),
        );
  }
}

/// Borra las fichadas de [fechas] (para armar días faltantes).
Future<void> borrarFichadas(AppDatabase db, List<String> fechas) =>
    (db.delete(db.fichadas)..where((f) => f.fecha.isIn(fechas))).go();
