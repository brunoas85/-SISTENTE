import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/perfil/perfil_repository.dart';
import '../../domain/domain.dart';
import '../asistencia/widgets/sync_indicator.dart';
import '../asistencia/widgets/sync_status_icon.dart';
import '../shell/app_shell.dart';
import 'agrupamiento_selector.dart';
import 'perfil_providers.dart';

/// Guarda el agrupamiento y avisa si no se pudo escribir en el dispositivo.
Future<bool> guardarAgrupamiento(
  BuildContext context,
  WidgetRef ref,
  Agrupamiento agrupamiento,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await elegirAgrupamiento(ref, agrupamiento);
    return true;
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('No se pudo guardar el agrupamiento: $e')),
    );
    return false;
  }
}

/// Perfil: agrupamiento (define la jornada). Se lee y se guarda en el
/// dispositivo; el sync lo sube a Supabase.
class PerfilPage extends ConsumerWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(miPerfilProvider);
    return Scaffold(
      appBar: AppBar(
        leading: shellBackButton(context),
        title: const Text('Perfil'),
        actions: const [SyncIndicator()],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: switch (perfil) {
              AsyncData(:final value) => _Contenido(perfil: value),
              AsyncError(:final error) => _Error(
                error: error,
                onRetry: () => ref.invalidate(miPerfilProvider),
              ),
              _ => const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Cargando perfil',
                ),
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.perfil});

  final Perfil? perfil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final agrupamiento = perfil?.agrupamiento;
    final estado = perfil?.syncStatus;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ListTile(
          title: Text('Agrupamiento', style: theme.textTheme.titleMedium),
          subtitle: Text(
            agrupamiento == null
                ? 'Todavía no lo elegiste. Mientras tanto la jornada es de '
                      '${formatMinutes(workdayMinutesForAgrupamiento(null))} h.'
                : 'Tu jornada es de '
                      '${formatMinutes(agrupamiento.workdayMinutes)} h, salvo '
                      'que haya una jornada cargada con vigencia.',
            key: const Key('perfil-jornada'),
          ),
          trailing: estado == null || agrupamiento == null
              ? null
              : SyncStatusIcon(status: estado, error: perfil?.syncError),
        ),
        AgrupamientoSelector(
          selected: agrupamiento,
          onSelected: (a) => guardarAgrupamiento(context, ref, a),
        ),
        if (estado == SyncStatus.error && perfil?.syncError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              perfil!.syncError!,
              key: const Key('perfil-error-sync'),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            const Text(
              'No se pudo leer el perfil guardado en el dispositivo.',
              key: Key('error-perfil'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

/// Se muestra una sola vez, al entrar, si el agrupamiento no está elegido.
class ElegirAgrupamientoPage extends ConsumerWidget {
  const ElegirAgrupamientoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('@sistente')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              key: const Key('elegir-agrupamiento'),
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '¿Cuál es tu agrupamiento?',
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'Define tu jornada para calcular la deuda y el a favor. '
                    'Lo podés cambiar después desde Perfil.',
                  ),
                ),
                AgrupamientoSelector(
                  selected: null,
                  onSelected: (a) => guardarAgrupamiento(context, ref, a),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
