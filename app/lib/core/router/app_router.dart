import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/asistencia/asistencia_mes_page.dart';
import '../../features/asistencia/fichar_page.dart';
import '../../features/banco_horas/banco_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/feriados/feriados_page.dart';
import '../../features/perfil/perfil_page.dart';
import '../../features/shell/app_shell.dart';
import '../auth/auth_providers.dart';

part 'app_router.g.dart';

abstract final class Routes {
  static const login = '/login';
  static const fichar = '/fichar';
  static const asistencia = '/asistencia';
  static const banco = '/banco';
  static const feriados = '/feriados';
  static const perfil = '/perfil';
}

/// Secciones de la navegación principal. Asistencia va segunda: en el
/// celular lo primero es fichar y en la PC queda arriba del rail.
const shellDestinations = [
  ShellDestination(
    path: Routes.fichar,
    label: 'Fichar',
    icon: Icons.fingerprint,
    selectedIcon: Icons.fingerprint,
  ),
  ShellDestination(
    path: Routes.asistencia,
    label: 'Asistencia',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month,
  ),
  ShellDestination(
    path: Routes.banco,
    label: 'Banco',
    icon: Icons.account_balance_wallet_outlined,
    selectedIcon: Icons.account_balance_wallet,
  ),
  ShellDestination(
    path: Routes.feriados,
    label: 'Feriados',
    icon: Icons.event_outlined,
    selectedIcon: Icons.event,
  ),
  ShellDestination(
    path: Routes.perfil,
    label: 'Perfil',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
];

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
      ShellRoute(
        builder: (context, state, child) => AppShell(
          location: state.uri.path,
          destinations: shellDestinations,
          child: child,
        ),
        routes: [
          GoRoute(
            path: Routes.fichar,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: FicharPage()),
          ),
          GoRoute(
            path: Routes.asistencia,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AsistenciaMesPage()),
          ),
          GoRoute(
            path: Routes.banco,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BancoPage()),
          ),
          GoRoute(
            path: Routes.feriados,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: FeriadosPage()),
          ),
          GoRoute(
            path: Routes.perfil,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PerfilPage()),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    session.dispose();
  });
  return router;
}
