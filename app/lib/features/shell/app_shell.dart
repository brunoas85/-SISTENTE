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

/// Dónde va una sección en el celular (en la PC van todas en el rail, en el
/// orden de la lista).
enum PhonePlacement {
  /// Destino propio en la barra inferior.
  bar,

  /// Dentro de la hoja de "Más".
  more,

  /// Avatar arriba a la derecha, en el AppBar de las pantallas del shell.
  account,
}

/// Una sección de la navegación principal.
class ShellDestination {
  const ShellDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.phone = PhonePlacement.bar,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// Lugar en la navegación del celular.
  final PhonePlacement phone;
}

/// Datos del shell para las pantallas que muestra (avatar de Perfil y botón
/// para volver). Fuera del shell (por ejemplo, en los tests de una
/// pantalla sola) no hay [ShellScope] y esos botones no se muestran.
class ShellScope extends InheritedWidget {
  const ShellScope({
    super.key,
    required this.phone,
    required this.location,
    required this.account,
    required this.home,
    required super.child,
  });

  /// Layout de celular (barra inferior).
  final bool phone;

  /// Ruta actual.
  final String location;

  /// Sección que va en el avatar (Perfil), si hay.
  final ShellDestination? account;

  /// Ruta a la que se vuelve si no hay a dónde volver (la primera sección).
  final String home;

  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  /// Estamos en la sección del avatar, en el celular.
  bool get atAccount =>
      phone && account != null && location.startsWith(account!.path);

  @override
  bool updateShouldNotify(ShellScope oldWidget) =>
      phone != oldWidget.phone ||
      location != oldWidget.location ||
      account != oldWidget.account ||
      home != oldWidget.home;
}

/// Avatar de Perfil para el AppBar. Solo se ve en el celular y dentro del
/// shell; en la PC Perfil está en el rail. Abre Perfil encima de la
/// pantalla actual (se vuelve con la flecha o el gesto de atrás de iOS).
class ShellAccountButton extends StatelessWidget {
  const ShellAccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = ShellScope.maybeOf(context);
    final account = scope?.account;
    if (scope == null || !scope.phone || account == null || scope.atAccount) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      key: Key('nav-${account.path}'),
      tooltip: account.label,
      onPressed: () => context.push(account.path),
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        child: Icon(account.icon, size: 20),
      ),
    );
  }
}

/// Botón para volver desde Perfil en el celular (ahí no hay barra
/// inferior). Si Perfil se abrió directo (por ejemplo, recargando la web),
/// vuelve a la primera sección. `null` fuera de ese caso.
Widget? shellBackButton(BuildContext context) {
  final scope = ShellScope.maybeOf(context);
  if (scope == null || !scope.atAccount) return null;
  if (Navigator.of(context).canPop()) return const BackButton();
  return BackButton(
    key: const Key('volver-de-perfil'),
    onPressed: () => context.go(scope.home),
  );
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
    final width = MediaQuery.sizeOf(context).width;
    final phone = width < Breakpoints.tablet;
    final account = [
      for (final d in destinations)
        if (d.phone == PhonePlacement.account) d,
    ].firstOrNull;
    final scoped = ShellScope(
      phone: phone,
      location: location,
      account: account,
      home: destinations.first.path,
      child: child,
    );

    if (phone) {
      return _PhoneShell(
        location: location,
        destinations: destinations,
        child: scoped,
      );
    }

    void go(int i) => context.go(destinations[i].path);
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
          Expanded(child: scoped),
        ],
      ),
    );
  }
}

/// Navegación del celular: barra inferior con las secciones `bar` más
/// "Más" (hoja con las secciones `more`). La sección `account` va en el
/// avatar del AppBar y se abre sin barra, con botón para volver.
class _PhoneShell extends StatelessWidget {
  const _PhoneShell({
    required this.location,
    required this.destinations,
    required this.child,
  });

  final String location;
  final List<ShellDestination> destinations;
  final Widget child;

  bool _en(ShellDestination d) => location.startsWith(d.path);

  Future<void> _abrirMas(BuildContext context, List<ShellDestination> mas) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        useSafeArea: true,
        builder: (sheetContext) => SafeArea(
          child: Column(
            key: const Key('hoja-mas'),
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final d in mas)
                ListTile(
                  key: Key('nav-${d.path}'),
                  minTileHeight: 56,
                  leading: Icon(_en(d) ? d.selectedIcon : d.icon),
                  title: Text(d.label),
                  selected: _en(d),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.go(d.path);
                  },
                ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final barra = [
      for (final d in destinations)
        if (d.phone == PhonePlacement.bar) d,
    ];
    final mas = [
      for (final d in destinations)
        if (d.phone == PhonePlacement.more) d,
    ];
    final enCuenta = destinations.any(
      (d) => d.phone == PhonePlacement.account && _en(d),
    );
    // En Perfil no hay barra: se vuelve con la flecha del AppBar.
    if (enCuenta) return Scaffold(body: child);

    final masSeleccionado = mas.any(_en);
    final i = barra.indexWhere(_en);
    final selected = masSeleccionado ? barra.length : (i < 0 ? 0 : i);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        key: const Key('nav-bar'),
        selectedIndex: selected,
        onDestinationSelected: (i) {
          if (i < barra.length) {
            context.go(barra[i].path);
          } else {
            _abrirMas(context, mas);
          }
        },
        destinations: [
          for (final d in barra)
            NavigationDestination(
              key: Key('nav-${d.path}'),
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
          if (mas.isNotEmpty)
            const NavigationDestination(
              key: Key('nav-mas'),
              icon: Icon(Icons.menu),
              selectedIcon: Icon(Icons.menu_open),
              label: 'Más',
              tooltip: 'Más secciones',
            ),
        ],
      ),
    );
  }
}
