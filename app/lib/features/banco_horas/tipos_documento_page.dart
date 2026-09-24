import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../data/banco/banco_repository.dart';
import '../../data/banco/movimiento.dart';
import '../../data/local/app_database.dart';
import '../../data/providers.dart';
import '../../data/sync/sync_controller.dart';
import '../asistencia/widgets/sync_indicator.dart';
import '../asistencia/widgets/sync_status_icon.dart';
import 'banco_providers.dart';

/// Códigos que se ofrecen cuando el catálogo está vacío. Son solo una
/// sugerencia: el usuario elige cuáles crear (no se cargan solos).
const sugerenciasTiposGde = ['FSOLI', 'FOESC'];

/// ABM del catálogo de tipos de documento GDE (código y descripción). El
/// código es único por usuario sin distinguir mayúsculas.
class TiposDocumentoPage extends ConsumerWidget {
  const TiposDocumentoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipos = ref.watch(tiposDocumentoProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tipos de documento GDE'),
        actions: const [SyncIndicator()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('nuevo-tipo'),
        onPressed: () => editarTipo(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo tipo'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: switch (tipos) {
              AsyncData(:final value) => _Lista(
                tipos: [
                  for (final t in value)
                    if (!t.isDeleted) t,
                ],
              ),
              AsyncError(:final error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'No se pudo leer el catálogo guardado en el '
                        'dispositivo.',
                        key: Key('error-tipos'),
                        textAlign: TextAlign.center,
                      ),
                      Text('$error', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref.invalidate(tiposDocumentoProvider),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
              _ => const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Cargando tipos de documento',
                ),
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _Lista extends ConsumerWidget {
  const _Lista({required this.tipos});

  final List<LocalTipoDocumento> tipos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tipos.isEmpty) return const _Vacio();
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        for (final t in tipos)
          ListTile(
            key: Key('tipo-${t.codigo}'),
            title: Text(t.codigo),
            subtitle: Text(
              [
                t.descripcion ?? 'Sin descripción',
                if (t.syncStatus == SyncStatus.error && t.syncError != null)
                  t.syncError!,
              ].join('\n'),
            ),
            onTap: () => editarTipo(context, ref, tipo: t),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SyncStatusIcon(status: t.syncStatus, error: t.syncError),
                IconButton(
                  key: Key('borrar-tipo-${t.codigo}'),
                  tooltip: 'Borrar ${t.codigo}',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _borrar(context, ref, t),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _borrar(
    BuildContext context,
    WidgetRef ref,
    LocalTipoDocumento t,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Borrar ${t.codigo}'),
        content: const Text(
          'Deja de aparecer para movimientos nuevos. Los movimientos que ya '
          'lo usan lo conservan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirmar-borrar-tipo'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    final userId = ref.read(currentUserIdProvider);
    if (ok != true || userId == null) return;
    try {
      await ref
          .read(bancoRepositoryProvider)
          .borrarTipo(userId: userId, id: t.id);
      unawaited(ref.read(syncControllerProvider.notifier).syncNow());
    } on BancoInvalidoException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

/// Catálogo vacío: se explica y se ofrecen las sugerencias, que el usuario
/// tiene que confirmar.
class _Vacio extends ConsumerWidget {
  const _Vacio();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.description_outlined, size: 48),
        const SizedBox(height: 12),
        const Text(
          'Todavía no cargaste tipos de documento GDE.',
          key: Key('sin-tipos'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text(
          'Son los documentos que respaldan los movimientos del banco '
          '(usufructos, salidas tempranas, llegadas tarde, comisiones).',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            key: const Key('sugerir-tipos'),
            onPressed: () => _sugerir(context, ref),
            icon: const Icon(Icons.lightbulb_outline),
            label: Text('Crear ${sugerenciasTiposGde.join(' y ')}'),
          ),
        ),
      ],
    );
  }

  Future<void> _sugerir(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final elegidos = await showDialog<Set<String>>(
      context: context,
      builder: (context) => const _SugerenciasDialog(),
    );
    final userId = ref.read(currentUserIdProvider);
    if (elegidos == null || elegidos.isEmpty || userId == null) return;
    final repo = ref.read(bancoRepositoryProvider);
    try {
      for (final codigo in sugerenciasTiposGde) {
        if (elegidos.contains(codigo)) {
          await repo.guardarTipo(userId: userId, codigo: codigo);
        }
      }
      unawaited(ref.read(syncControllerProvider.notifier).syncNow());
    } on BancoInvalidoException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _SugerenciasDialog extends StatefulWidget {
  const _SugerenciasDialog();

  @override
  State<_SugerenciasDialog> createState() => _SugerenciasDialogState();
}

class _SugerenciasDialogState extends State<_SugerenciasDialog> {
  final _elegidos = {...sugerenciasTiposGde};

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Crear tipos sugeridos'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Elegí cuáles crear. Después les podés agregar la descripción.',
        ),
        for (final c in sugerenciasTiposGde)
          CheckboxListTile(
            key: Key('sugerencia-$c'),
            value: _elegidos.contains(c),
            title: Text(c),
            onChanged: (v) => setState(
              () => v == true ? _elegidos.add(c) : _elegidos.remove(c),
            ),
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        key: const Key('confirmar-sugerencias'),
        onPressed: _elegidos.isEmpty
            ? null
            : () => Navigator.pop(context, _elegidos),
        child: const Text('Crear'),
      ),
    ],
  );
}

/// Alta o edición de un tipo de documento en un diálogo. Devuelve el tipo
/// guardado, o `null` si se canceló.
Future<LocalTipoDocumento?> editarTipo(
  BuildContext context,
  WidgetRef ref, {
  LocalTipoDocumento? tipo,
}) => showDialog<LocalTipoDocumento>(
  context: context,
  builder: (_) => _TipoDialog(tipo: tipo),
);

class _TipoDialog extends ConsumerStatefulWidget {
  const _TipoDialog({this.tipo});

  final LocalTipoDocumento? tipo;

  @override
  ConsumerState<_TipoDialog> createState() => _TipoDialogState();
}

class _TipoDialogState extends ConsumerState<_TipoDialog> {
  late final _codigo = TextEditingController(text: widget.tipo?.codigo);
  late final _descripcion = TextEditingController(
    text: widget.tipo?.descripcion,
  );
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _codigo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  String? get _validation {
    if (_codigo.text.trim().isEmpty) return null;
    return validarCodigoTipo(
      codigo: _codigo.text,
      id: widget.tipo?.id,
      existentes: ref.watch(tiposDocumentoProvider).value ?? const [],
    );
  }

  Future<void> _guardar() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await ref
          .read(bancoRepositoryProvider)
          .guardarTipo(
            userId: userId,
            id: widget.tipo?.id,
            codigo: _codigo.text,
            descripcion: _descripcion.text,
          );
      unawaited(ref.read(syncControllerProvider.notifier).syncNow());
      if (mounted) Navigator.pop(context, saved);
    } on BancoInvalidoException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = _error ?? _validation;
    final canSave =
        !_saving && _codigo.text.trim().isNotEmpty && _validation == null;
    return AlertDialog(
      title: Text(
        widget.tipo == null ? 'Nuevo tipo de documento' : 'Editar tipo',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('tipo-codigo'),
            controller: _codigo,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Código',
              hintText: 'Ej.: el código del documento en GDE',
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('tipo-descripcion'),
            controller: _descripcion,
            decoration: const InputDecoration(
              labelText: 'Descripción (opcional)',
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message,
              key: const Key('tipo-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('guardar-tipo'),
          onPressed: canSave ? _guardar : null,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
