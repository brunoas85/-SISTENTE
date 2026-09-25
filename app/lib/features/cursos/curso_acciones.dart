import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../data/cursos/curso.dart';
import '../../data/cursos/cursos_repository.dart';
import '../../data/local/app_database.dart';
import '../../data/providers.dart';
import '../../data/sync/fichadas_remote.dart';
import '../../data/sync/sync_controller.dart';
import '../../domain/domain.dart';
import 'cursos_providers.dart';

void _avisar(ScaffoldMessengerState messenger, String texto) =>
    messenger.showSnackBar(
      SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating),
    );

/// Pide confirmación y borra [c] (borrado lógico). Devuelve `true` si se
/// borró.
Future<bool> borrarCurso(
  BuildContext context,
  WidgetRef ref,
  LocalCurso c,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Borrar curso'),
      content: Text(
        '¿Querés borrar el curso ${describirCurso(c)}? '
        'Deja de sumar créditos.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('confirmar-borrar-curso'),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Borrar'),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return false;
  try {
    await ref
        .read(cursosRepositoryProvider)
        .borrarCurso(userId: userId, id: c.id);
    unawaited(ref.read(syncControllerProvider.notifier).syncNow());
    _avisar(messenger, 'Curso ${describirCurso(c)} borrado.');
    return true;
  } on CursoInvalidoException catch (e) {
    _avisar(messenger, e.message);
  } catch (e) {
    _avisar(messenger, 'No se pudo borrar: $e');
  }
  return false;
}

/// Cambia el estado de [c] (edición en línea desde la tabla). Devuelve
/// `true` si se guardó.
Future<bool> cambiarEstadoCurso(
  BuildContext context,
  WidgetRef ref,
  LocalCurso c,
  CourseStatus estado,
) async {
  if (estado == c.status) return false;
  final messenger = ScaffoldMessenger.of(context);
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return false;
  try {
    await ref
        .read(cursosRepositoryProvider)
        .guardarCurso(
          userId: userId,
          draft: c.toDraft(estado: estado),
        );
    unawaited(ref.read(syncControllerProvider.notifier).syncNow());
    _avisar(messenger, 'Curso ${describirCurso(c)}: ${estado.label}.');
    return true;
  } on CursoInvalidoException catch (e) {
    _avisar(messenger, e.message);
  } catch (e) {
    _avisar(messenger, 'No se pudo guardar: $e');
  }
  return false;
}

/// Muestra el certificado de [c]: el del dispositivo si está; si no, el del
/// servidor con una URL firmada de 60 s.
Future<void> mostrarCertificado(BuildContext context, LocalCurso c) =>
    showDialog<void>(
      context: context,
      builder: (_) => CertificadoDialog(curso: c),
    );

class CertificadoDialog extends ConsumerWidget {
  const CertificadoDialog({super.key, required this.curso});

  final LocalCurso curso;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = curso;
    return AlertDialog(
      key: const Key('dialogo-certificado'),
      title: Text('Certificado de ${c.actividad}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: c.tieneCertificado
              ? _Vista(curso: c)
              : const Text('Este curso no tiene certificado.'),
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

class _Vista extends ConsumerStatefulWidget {
  const _Vista({required this.curso});

  final LocalCurso curso;

  @override
  ConsumerState<_Vista> createState() => _VistaState();
}

class _VistaState extends ConsumerState<_Vista> {
  bool _abriendo = false;
  String? _errorPdf;

  Future<void> _abrirPdf(String path) async {
    setState(() {
      _abriendo = true;
      _errorPdf = null;
    });
    try {
      // URL nueva en cada toque: vence a los 60 s.
      final url = await ref
          .read(cursosRemoteProvider)
          .signedCertificadoUrl(path, expiresIn: const Duration(seconds: 60));
      final ok = await ref.read(urlOpenerProvider)(Uri.parse(url));
      if (!ok && mounted) {
        setState(() => _errorPdf = 'No se pudo abrir el PDF.');
      }
    } on RemoteUnavailableException {
      if (mounted) {
        setState(
          () => _errorPdf = 'Sin conexión: el PDF está solo en el servidor.',
        );
      }
    } on RemoteRejectedException catch (e) {
      if (mounted) {
        setState(() => _errorPdf = 'No se pudo abrir el PDF: ${e.message}');
      }
    } finally {
      if (mounted) setState(() => _abriendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.curso;
    final theme = Theme.of(context);
    final provider = certificadoCursoProvider(
      localRef: c.certificadoLocal,
      remotePath: c.certificadoPath,
      esPdf: c.certificadoEsPdf,
    );
    final vista = ref.watch(provider);

    Widget mensaje(String texto, {VoidCallback? reintentar}) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_not_supported_outlined, size: 40),
          const SizedBox(height: 8),
          Text(texto, textAlign: TextAlign.center),
          if (reintentar != null)
            TextButton(onPressed: reintentar, child: const Text('Reintentar')),
        ],
      ),
    );
    const noSeVe = 'No se puede mostrar el certificado.';

    Widget imagen(Widget child) => ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: child,
      ),
    );

    return switch (vista) {
      AsyncData(value: CertificadoImagenLocal(:final bytes)) => imagen(
        Image.memory(
          bytes,
          key: const Key('certificado-local'),
          fit: BoxFit.contain,
          semanticLabel: 'Certificado de ${c.actividad}',
          errorBuilder: (_, _, _) => mensaje(noSeVe),
        ),
      ),
      AsyncData(value: CertificadoImagenFirmada(:final url)) => imagen(
        Image.network(
          url,
          key: const Key('certificado-remoto'),
          fit: BoxFit.contain,
          semanticLabel: 'Certificado de ${c.actividad}',
          errorBuilder: (_, _, _) =>
              mensaje(noSeVe, reintentar: () => ref.invalidate(provider)),
        ),
      ),
      AsyncData(value: CertificadoPdfRemoto(:final path)) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.picture_as_pdf_outlined),
            title: Text('Certificado en PDF'),
            subtitle: Text(
              'Se abre en el visor del sistema con un enlace que vence en '
              '60 segundos.',
            ),
          ),
          FilledButton.icon(
            key: const Key('abrir-pdf'),
            onPressed: _abriendo ? null : () => _abrirPdf(path),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir PDF'),
          ),
          if (_errorPdf != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _errorPdf!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
      AsyncData(value: CertificadoPdfLocal(:final bytes)) => ListTile(
        key: const Key('certificado-pdf-local'),
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.picture_as_pdf_outlined),
        title: Text(
          'PDF guardado en este dispositivo '
          '(${(bytes / 1024).ceil()} KB)',
        ),
        subtitle: const Text(
          'Se sube al sincronizar. Cuando esté en el servidor se puede '
          'abrir desde acá.',
        ),
      ),
      AsyncError(:final error) => mensaje(
        error is CertificadoNoDisponibleException ? error.message : noSeVe,
        reintentar: () => ref.invalidate(provider),
      ),
      _ => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Cargando el certificado',
          ),
        ),
      ),
    };
  }
}
