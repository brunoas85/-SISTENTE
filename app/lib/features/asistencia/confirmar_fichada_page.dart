import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/format/formatters.dart';
import '../../data/fichadas/fichadas_repository.dart';
import '../../data/local/app_database.dart';
import '../../data/providers.dart';
import '../../data/sync/sync_controller.dart';
import '../../domain/domain.dart';

/// Datos de una fichada a confirmar.
class FicharDraft {
  const FicharDraft({
    required this.tipo,
    required this.fecha,
    required this.proposedMin,
    required this.rawPhoto,
    this.tramoAbierto,
  });

  final TipoFichada tipo;
  final CalendarDate fecha;

  /// Hora del dispositivo al tocar "Fichar".
  final int proposedMin;

  /// Foto tal como vino de la cámara (se comprime acá).
  final Uint8List rawPhoto;

  /// Para un egreso: el tramo que se cierra.
  final LocalFichada? tramoAbierto;
}

/// Confirmación: foto, hora propuesta (corregible) y botón grande para
/// guardar. Devuelve la fichada guardada o `null` si se canceló.
class ConfirmarFichadaPage extends ConsumerStatefulWidget {
  const ConfirmarFichadaPage({super.key, required this.draft});

  final FicharDraft draft;

  @override
  ConsumerState<ConfirmarFichadaPage> createState() =>
      _ConfirmarFichadaPageState();
}

class _ConfirmarFichadaPageState extends ConsumerState<ConfirmarFichadaPage> {
  late int _chosenMin = widget.draft.proposedMin;
  late Future<Uint8List> _compressed;
  bool _saving = false;
  String? _error;

  FicharDraft get _draft => widget.draft;
  bool get _isIngreso => _draft.tipo == TipoFichada.ingreso;

  @override
  void initState() {
    super.initState();
    // Se comprime mientras el usuario revisa la hora.
    _compressed = ref.read(photoCompressorProvider)(_draft.rawPhoto);
    // Evita un error no manejado si falla antes de confirmar.
    unawaited(_compressed.then((_) {}, onError: (_) {}));
  }

  String? get _validation {
    final open = _draft.tramoAbierto;
    if (!_isIngreso && open != null && _chosenMin <= open.ingresoMin) {
      return 'El egreso tiene que ser posterior al ingreso '
          '(${formatClock(open.ingresoMin)}).';
    }
    return null;
  }

  Future<void> _corregirHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _chosenMin ~/ 60, minute: _chosenMin % 60),
      helpText: _isIngreso ? 'Hora de ingreso' : 'Hora de egreso',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _chosenMin = picked.hour * 60 + picked.minute);
    }
  }

  Future<void> _confirmar() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final Uint8List jpeg;
      try {
        jpeg = await _compressed;
      } catch (_) {
        throw const FichadaInvalidaException(
          'No se pudo procesar la foto. Volvé atrás y sacala de nuevo.',
        );
      }
      final repo = ref.read(fichadasRepositoryProvider);
      final saved = _isIngreso
          ? await repo.ficharIngreso(
              userId: userId,
              date: _draft.fecha,
              proposedMin: _draft.proposedMin,
              chosenMin: _chosenMin,
              photoJpeg: jpeg,
            )
          : await repo.ficharEgreso(
              userId: userId,
              fichadaId: _draft.tramoAbierto!.id,
              proposedMin: _draft.proposedMin,
              chosenMin: _chosenMin,
              photoJpeg: jpeg,
            );
      unawaited(ref.read(syncControllerProvider.notifier).syncNow());
      if (mounted) Navigator.of(context).pop(saved);
    } on FichadaInvalidaException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo guardar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final edited = _chosenMin != _draft.proposedMin;
    final validation = _validation;
    final message = _error ?? validation;
    final titulo = _isIngreso ? 'Confirmar ingreso' : 'Confirmar egreso';

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: ColoredBox(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Image.memory(
                              _draft.rawPhoto,
                              fit: BoxFit.contain,
                              semanticLabel: 'Foto del biométrico',
                              errorBuilder: (_, _, _) => const Center(
                                child: Text('No se puede mostrar la foto'),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        formatDateLong(_draft.fecha),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        formatClock(_chosenMin),
                        key: const Key('hora-elegida'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (edited)
                        Text(
                          'Hora corregida. El dispositivo marcó '
                          '${formatClock(_draft.proposedMin)}.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      const SizedBox(height: 8),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : _corregirHora,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Corregir hora'),
                        ),
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          message,
                          key: const Key('confirmar-error'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: FilledButton.icon(
                    key: const Key('confirmar-fichada'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(72),
                      textStyle: theme.textTheme.titleLarge,
                    ),
                    onPressed: _saving || validation != null
                        ? null
                        : _confirmar,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      _isIngreso ? 'Confirmar ingreso' : 'Confirmar egreso',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
