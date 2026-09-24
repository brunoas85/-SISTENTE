import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/auth/auth_providers.dart';
import 'fichadas/fichadas_repository.dart';
import 'local/app_database.dart';
import 'local/open_connection.dart';
import 'perfil/perfil_repository.dart';
import 'photos/photo_capture.dart';
import 'photos/photo_compressor.dart';
import 'photos/photo_store.dart';
import 'sync/fichadas_remote.dart';
import 'sync/sync_service.dart';

part 'providers.g.dart';

/// Reloj de la app (se reemplaza en los tests).
@Riverpod(keepAlive: true)
DateTime Function() clock(Ref ref) => DateTime.now;

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase(openAppDatabaseConnection());
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
PhotoStore photoStore(Ref ref) =>
    createPlatformPhotoStore(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
PhotoCapture photoCapture(Ref ref) => ImagePickerPhotoCapture();

@Riverpod(keepAlive: true)
PhotoCompressor photoCompressor(Ref ref) => compressPhotoInBackground;

@Riverpod(keepAlive: true)
FichadasRepository fichadasRepository(Ref ref) => FichadasRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(photoStoreProvider),
  clock: ref.watch(clockProvider),
);

@Riverpod(keepAlive: true)
PerfilRepository perfilRepository(Ref ref) => PerfilRepository(
  ref.watch(appDatabaseProvider),
  clock: ref.watch(clockProvider),
);

@Riverpod(keepAlive: true)
FichadasRemote fichadasRemote(Ref ref) =>
    SupabaseFichadasRemote(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
SyncService syncService(Ref ref) => SyncService(
  repository: ref.watch(fichadasRepositoryProvider),
  perfiles: ref.watch(perfilRepositoryProvider),
  remote: ref.watch(fichadasRemoteProvider),
  clock: ref.watch(clockProvider),
);

/// `true` si el dispositivo tiene alguna red (no garantiza internet).
@Riverpod(keepAlive: true)
Stream<bool> connectivityOnline(Ref ref) => Connectivity().onConnectivityChanged
    .map((r) => r.any((c) => c != ConnectivityResult.none));

/// Cada cuánto se reintenta la sincronización con la app abierta. `null`
/// desactiva el reintento periódico (tests).
@Riverpod(keepAlive: true)
Duration? syncRetryInterval(Ref ref) => const Duration(minutes: 3);
