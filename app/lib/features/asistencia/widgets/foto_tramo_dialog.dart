import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/formatters.dart';
import '../../../data/local/app_database.dart';
import '../asistencia_mes_providers.dart';

extension FotosTramo on LocalFichada {
  bool get tieneFotoIngreso =>
      fotoIngresoLocal != null || fotoIngresoPath != null;
  bool get tieneFotoEgreso => fotoEgresoLocal != null || fotoEgresoPath != null;
  bool get tieneFoto => tieneFotoIngreso || tieneFotoEgreso;
}

/// Muestra las fotos del biométrico de un tramo: la del dispositivo si
/// está; si no, la del servidor con una URL firmada de 60 s.
Future<void> mostrarFotosTramo(BuildContext context, LocalFichada tramo) =>
    showDialog<void>(
      context: context,
      builder: (_) => FotoTramoDialog(tramo: tramo),
    );

class FotoTramoDialog extends StatelessWidget {
  const FotoTramoDialog({super.key, required this.tramo});

  final LocalFichada tramo;

  @override
  Widget build(BuildContext context) {
    final t = tramo;
    return AlertDialog(
      key: const Key('dialogo-foto'),
      title: Text('Comprobante del ${formatDate(parseIsoDate(t.fecha))}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (t.tieneFotoIngreso)
                _Foto(
                  titulo: 'Ingreso ${formatClock(t.ingresoMin)}',
                  localRef: t.fotoIngresoLocal,
                  remotePath: t.fotoIngresoPath,
                ),
              if (t.tieneFotoEgreso && t.egresoMin != null)
                _Foto(
                  titulo: 'Egreso ${formatClock(t.egresoMin!)}',
                  localRef: t.fotoEgresoLocal,
                  remotePath: t.fotoEgresoPath,
                ),
              if (!t.tieneFoto)
                const Text('Este tramo no tiene foto del biométrico.'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

class _Foto extends ConsumerWidget {
  const _Foto({required this.titulo, this.localRef, this.remotePath});

  final String titulo;
  final String? localRef;
  final String? remotePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final provider = fotoComprobanteProvider(
      localRef: localRef,
      remotePath: remotePath,
    );
    final foto = ref.watch(provider);
    Widget mensaje(String texto, {VoidCallback? reintentar}) => Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_not_supported_outlined, size: 40),
            const SizedBox(height: 8),
            Text(texto, textAlign: TextAlign.center),
            if (reintentar != null)
              TextButton(
                onPressed: reintentar,
                child: const Text('Reintentar'),
              ),
          ],
        ),
      ),
    );
    const noSeVe = 'No se puede mostrar la foto.';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: ColoredBox(
                color: theme.colorScheme.surfaceContainerHighest,
                child: switch (foto) {
                  AsyncData(value: FotoLocal(:final bytes)) => Image.memory(
                    bytes,
                    key: const Key('foto-local'),
                    fit: BoxFit.contain,
                    semanticLabel: 'Foto del biométrico ($titulo)',
                    errorBuilder: (_, _, _) => mensaje(noSeVe),
                  ),
                  AsyncData(value: FotoFirmada(:final url)) => Image.network(
                    url,
                    key: const Key('foto-remota'),
                    fit: BoxFit.contain,
                    semanticLabel: 'Foto del biométrico ($titulo)',
                    errorBuilder: (_, _, _) => mensaje(
                      noSeVe,
                      reintentar: () => ref.invalidate(provider),
                    ),
                  ),
                  AsyncError(:final error) => mensaje(
                    error is FotoNoDisponibleException ? error.message : noSeVe,
                    reintentar: () => ref.invalidate(provider),
                  ),
                  _ => const Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: 'Cargando la foto',
                    ),
                  ),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
