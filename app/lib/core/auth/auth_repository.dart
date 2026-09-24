import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Error de login con un mensaje listo para mostrar.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Sesión del usuario. La implementación real usa Supabase Auth, que
/// persiste la sesión en el dispositivo.
abstract interface class AuthRepository {
  /// Usuario con sesión, o `null`. Funciona sin red si hay una sesión
  /// guardada.
  String? get currentUserId;

  /// Cambios de usuario (login, logout, sesión expirada).
  Stream<String?> get userIdChanges;

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._auth);

  final GoTrueClient _auth;

  @override
  String? get currentUserId => _auth.currentUser?.id;

  @override
  Stream<String?> get userIdChanges =>
      _auth.onAuthStateChange.map((s) => s.session?.user.id).distinct();

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithPassword(email: email.trim(), password: password);
    } on AuthRetryableFetchException {
      throw const AuthFailure(
        'No hay conexión. Para entrar por primera vez hace falta internet.',
      );
    } on AuthApiException catch (e) {
      if (e.code == 'invalid_credentials' || e.statusCode == '400') {
        throw const AuthFailure('El email o la contraseña no son correctos.');
      }
      throw AuthFailure('No se pudo iniciar sesión (${e.message}).');
    } on AuthException catch (e) {
      throw AuthFailure('No se pudo iniciar sesión (${e.message}).');
    } catch (_) {
      throw const AuthFailure(
        'No se pudo iniciar sesión. Revisá la conexión e intentá de nuevo.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Sin red igual se borra la sesión local.
      await _auth.signOut(scope: SignOutScope.local);
    }
  }
}
