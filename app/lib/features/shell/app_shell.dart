import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../perfil/perfil_page.dart';
import '../perfil/perfil_providers.dart';

/// Breakpoints de ancho (nunca la plataforma).
abstract final class Breakpoints {
  /// Por debajo: celular.
  static const tablet = 600.0;

  /// Desde acá: escritorio.
  static const desktop = 1024.0;
}

/// Una sección de la navegación principal.
class ShellDestination {
  const ShellDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Marco de las pantallas con sesión: barra inferior en el celular y
/// `NavigationRail` desde tablet. Si falta elegir el agrupamiento, lo pide
/// antes de mostrar la app (una sola vez).
class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.location,
    required this.destinations,
    required this.child,
  });

  final String location;
  final List<ShellDestination> destinations;
  final Widget child;

  int get _selected {
    final i = destinations.indexWhere((d) => location.startsWith(d.path));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(pedirAgrupamientoProvider)) {
      return const ElegirAgrupamientoPage();
    }
    void go(int i) => context.go(destinations[i].path);
    final width = MediaQuery.sizeOf(context).width;

    if (width < Breakpoints.tablet) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          key: const Key('nav-bar'),
          selectedIndex: _selected,
          onDestinationSelected: go,
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                key: Key('nav-${d.path}'),
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      );
    }

    final extended = width >= Breakpoints.desktop;
    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            right: false,
            child: NavigationRail(
              key: const Key('nav-rail'),
              extended: extended,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              selectedIndex: _selected,
              onDestinationSelected: go,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon, key: Key('nav-${d.path}')),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
