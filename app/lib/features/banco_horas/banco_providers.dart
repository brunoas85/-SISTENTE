import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/auth/auth_providers.dart';
import '../../data/local/app_database.dart';
import '../../data/providers.dart';

part 'banco_providers.g.dart';

/// Movimientos manuales activos del banco (desde la base local), del más
/// nuevo al más viejo.
@riverpod
Stream<List<LocalMovimiento>> misMovimientos(Ref ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  return ref.watch(bancoRepositoryProvider).watchMovimientos(userId);
}

/// Catálogo de tipos de documento GDE (incluidos los borrados), por código.
@riverpod
Stream<List<LocalTipoDocumento>> tiposDocumento(Ref ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  return ref.watch(bancoRepositoryProvider).watchTipos(userId);
}
