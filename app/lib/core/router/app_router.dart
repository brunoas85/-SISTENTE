import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/asistencia/fichar_page.dart';
import '../../features/auth/login_page.dart';
import '../auth/auth_providers.dart';

part 'app_router.g.dart';

abstract final class Routes {
  static const login = '/login';
  static const fichar = '/fichar';
}

/// Rutas de la app. Sin sesión se muestra siempre el login.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final session = ValueNotifier<String?>(ref.read(currentUserIdProvider));
  ref.listen(currentUserIdProvider, (_, next) => session.value = next);

  final router = GoRouter(
    initialLocation: Routes.fichar,
    refreshListenable: session,
    redirect: (context, state) {
      final loggedIn = session.value != null;
      final atLogin = state.matchedLocation == Routes.login;
      if (!loggedIn) return atLogin ? null : Routes.login;
      if (atLogin) return Routes.fichar;
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => Routes.fichar),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: Routes.fichar,
        builder: (context, state) => const FicharPage(),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    session.dispose();
  });
  return router;
}
