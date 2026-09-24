import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/auth/auth_providers.dart';
import '../providers.dart';
import 'sync_service.dart';

part 'sync_controller.g.dart';

/// Estado visible del sync.
class SyncUiState {
  const SyncUiState({this.running = false, this.last, this.lastRunAt});

  final bool running;
  final SyncResult? last;
  final DateTime? lastRunAt;

  /// La última pasada no llegó al servidor.
  bool get offline => last?.offline ?? false;
}

/// Dispara la sincronización sola: al abrir la app (y al iniciar sesión), al
/// volver a primer plano, al recuperar la red, cada tanto mientras la app
/// está abierta y después de cada fichada.
@Riverpod(keepAlive: true)
class SyncController extends _$SyncController {
  @override
  SyncUiState build() {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SyncUiState();

    ref.listen(connectivityOnlineProvider, (prev, next) {
      if (next.value == true && prev?.value != true) unawaited(syncNow());
    });

    final interval = ref.watch(syncRetryIntervalProvider);
    if (interval != null) {
      final timer = Timer.periodic(interval, (_) => unawaited(syncNow()));
      ref.onDispose(timer.cancel);
    }

    final lifecycle = AppLifecycleListener(
      onResume: () => unawaited(syncNow()),
    );
    ref.onDispose(lifecycle.dispose);

    // Al abrir la app.
    Future.microtask(syncNow);
    return const SyncUiState();
  }

  Future<void> syncNow() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || !ref.mounted) return;
    state = SyncUiState(
      running: true,
      last: state.last,
      lastRunAt: state.lastRunAt,
    );
    final result = await ref.read(syncServiceProvider).sync(userId);
    if (!ref.mounted) return;
    state = SyncUiState(last: result, lastRunAt: ref.read(clockProvider)());
  }
}
