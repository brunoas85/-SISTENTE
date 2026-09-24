import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/auth/auth_providers.dart';
import '../../data/perfil/perfil_repository.dart';
import '../../data/providers.dart';
import '../../data/sync/sync_controller.dart';
import '../../domain/domain.dart';

part 'perfil_providers.g.dart';

/// Perfil del usuario guardado en el dispositivo (`null` si todavía no se
/// bajó ni se eligió nada acá).
@riverpod
Stream<Perfil?> miPerfil(Ref ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);
  return ref.watch(perfilRepositoryProvider).watchPerfil(userId);
}

/// Hay que pedir el agrupamiento: el perfil local dice que no se eligió, o
/// no hay perfil local y ya terminó una pasada del sync (con o sin red), así
/// no se pregunta mientras se está bajando.
@riverpod
bool pedirAgrupamiento(Ref ref) {
  final perfil = ref.watch(miPerfilProvider);
  if (!perfil.hasValue) return false;
  final p = perfil.value;
  if (p != null) return p.agrupamiento == null;
  return ref.watch(syncControllerProvider.select((s) => s.lastRunAt != null));
}

/// Guarda el agrupamiento elegido en el dispositivo (queda pendiente) y
/// dispara el sync sin esperarlo.
Future<void> elegirAgrupamiento(
  WidgetRef ref,
  Agrupamiento agrupamiento,
) async {
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return;
  await ref
      .read(perfilRepositoryProvider)
      .setAgrupamiento(userId, agrupamiento);
  unawaited(ref.read(syncControllerProvider.notifier).syncNow());
}

/// Texto para la UI.
String agrupamientoLabel(Agrupamiento a) => switch (a) {
  Agrupamiento.administrativo => 'Administrativo',
  Agrupamiento.guardaparque => 'Guardaparque',
  Agrupamiento.guardaparqueApoyo => 'Guardaparque de apoyo',
};
