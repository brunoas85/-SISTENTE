import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_repository.dart';

part 'auth_providers.g.dart';

/// Cliente de Supabase ya inicializado en `main`.
@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) => Supabase.instance.client;

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    SupabaseAuthRepository(ref.watch(supabaseClientProvider).auth);

/// Id del usuario con sesión, o `null` si hay que mostrar el login.
@Riverpod(keepAlive: true)
class CurrentUserId extends _$CurrentUserId {
  @override
  String? build() {
    final repo = ref.watch(authRepositoryProvider);
    final sub = repo.userIdChanges.listen((id) => state = id);
    ref.onDispose(sub.cancel);
    return repo.currentUserId;
  }

  /// Relee la sesión (por ej. justo después del login).
  void refresh() => state = ref.read(authRepositoryProvider).currentUserId;
}
