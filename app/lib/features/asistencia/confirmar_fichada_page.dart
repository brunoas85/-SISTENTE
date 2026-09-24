import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/format/formatters.dart';
import '../../data/fichadas/fichada_validation.dart';
import '../../data/fichadas/fichadas_repository.dart';
import '../../data/local/app_database.dart';
import '../../data/photos/photo_capture.dart';
import '../../data/providers.dart';
import '../../data/sync/sync_controller.dart';
import '../../domain/domain.dart';

/// Datos de una fichada a confirmar.
class FicharDraft {
  const FicharDraft({
    required this.tipo,
    required this.fecha,
    required this.proposedMin,
    this.tramoAbierto,
    this.otrosTramos = const [],
  }) : assert(tipo == TipoFichada.egreso || proposedMin != null),
       assert(tipo == TipoFichada.ingreso || tramoAbierto != null);

  final TipoFichada tipo;

  /// Fecha del tramo (para cerrar un tramo anterior, la de ese día).
  final CalendarDate fecha;

  /// Hora del dispositivo al tocar "Fichar", o `null` si la hora se carga a
  /// mano (cerrar un tramo de un día anterior).
  final int? proposedMin;

  /// Para un egreso: el tramo que se cierra.
  final LocalFichada? tramoAbierto;

  /// Los demás tramos de esa fecha (para avisar si se superponen).
  final List<LocalFichada> otrosTramos;

  bool get esCierreAnterior => proposedMin == null;
}

/// Confirmación: hora propuesta (corregible), foto opcional del biométrico y
/// botón grande para guardar. Devuelve la fichada guardada o `null` si se
/// canceló.
class ConfirmarFichadaPage extends ConsumerStatefulWidget {
  const ConfirmarFichadaPage({super.key, required this.draft});

  final FicharDraft draft;

  @override
  ConsumerState<ConfirmarFichadaPage> createState() =>
      _ConfirmarFichadaPageState();
}

class _ConfirmarFichadaPageState extends ConsumerState<ConfirmarFichadaPage> {
  late int? _chosenMin = widget.draft.proposedMin;
  Uint8List? _rawPhoto;
  Future<Uint8List>? _compressed;
  bool _capturando = false;
  bool _saving = false;
  String? _error;

  FicharDraft get _draft => widget.draft;
  bool get _isIngreso => _draft.tipo == TipoFichada.ingreso;

  /// Motivo por el que no se puede confirmar todavía, o `null`.
  String? get _validation {
    final chosen = _chosenMin;
    if (chosen == null) return null;
    final open = _draft.tramoAbierto;
    final now = ref.read(clockProvider)();
    final futura = validarHoraNoFutura(
      fecha: _draft.fecha,
      hoy: CalendarDate.fromDateTime(now),
      ahoraMin: minutesOfDay(now),
      ingresoMin: _isIngreso ? chosen : open!.ingresoMin,
      egresoMin: _isIngreso ? null : chosen,
    );
    if (futura != null) return futura;
    return validarTramo(
      fecha: _draft.fecha,
      id: open?.id,
      ingresoMin: _isIngreso ? chosen : open!.ingresoMin,
      egresoMin: _isIngreso ? null : chosen,
      otrosDelDia: _draft.otrosTramos,
    );
  }

  Future<void> _sacarFoto() async {
    setState(() {
      _capturando = true;
      _error = null;
    });
    try {
      final raw = await ref.read(photoCaptureProvider).capture();
      if (raw != null && mounted) {
        final compressed = ref.read(photoCompressorProvider)(raw);
        // Evita un error no manejado si falla antes de confirmar.
        unawaited(compressed.then((_) {}, onError: (_) {}));
        setState(() {
          _rawPhoto = raw;
          _compressed = compressed;
        });
      }
    } on PhotoCaptureException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo sacar la foto: $e');
    } finally {
      if (mounted) setState(() => _capturando = false);
    }
  }

  void _quitarFoto() => setState(() {
    _rawPhoto = null;
    _compressed = null;
  });

  Future<void> _elegirHora() async {
    final inicial = _chosenMin ?? _draft.tramoAbierto?.ingresoMin ?? 0;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: inicial ~/ 60, minute: inicial % 60),
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
    final chosen = _chosenMin;
    if (userId == null || chosen == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      Uint8List? jpeg;
      final compressed = _compressed;
      if (compressed != null) {
        try {
          jpeg = await compressed;
        } catch (_) {
          throw const FichadaInvalidaException(
            'No se pudo procesar la foto. Sacala de nuevo o quitala.',
          );
        }
      }
      final repo = ref.read(fichadasRepositoryProvider);
      final saved = _isIngreso
          ? await repo.ficharIngreso(
              userId: userId,
              date: _draft.fecha,
              proposedMin: _draft.proposedMin!,
              chosenMin: chosen,
              photoJpeg: jpeg,
            )
          : await repo.ficharEgreso(
              userId: userId,
              fichadaId: _draft.tramoAbierto!.id,
              proposedMin: _draft.proposedMin,
              chosenMin: chosen,
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
    final chosen = _chosenMin;
    final proposed = _draft.proposedMin;
    final edited = chosen != null && proposed != null && chosen != proposed;
    final validation = _validation;
    final message = _error ?? validation;
    final usesCamera = ref.watch(photoCaptureProvider).usesCamera;
    final titulo = _draft.esCierreAnterior
        ? 'Cerrar tramo del ${formatDate(_draft.fecha)}'
        : (_isIngreso ? 'Confirmar ingreso' : 'Confirmar egreso');
    final raw = _rawPhoto;

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
                      if (_draft.esCierreAnterior)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Este tramo quedó abierto desde las '
                            '${formatClock(_draft.tramoAbierto!.ingresoMin)}. '
                            'Cargá la hora de egreso de ese día para poder '
                            'volver a fichar.',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      Text(
                        formatDateLong(_draft.fecha),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        chosen == null ? '--:--' : formatClock(chosen),
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
                          '${formatClock(proposed)}.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      const SizedBox(height: 8),
                      Center(
                        child: OutlinedButton.icon(
                          key: const Key('elegir-hora'),
                          onPressed: _saving ? null : _elegirHora,
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(
                            chosen == null ? 'Elegir hora' : 'Corregir hora',
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (raw == null)
                        OutlinedButton.icon(
                          key: const Key('sacar-foto'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                          ),
                          onPressed: _saving || _capturando ? null : _sacarFoto,
                          icon: _capturando
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  usesCamera
                                      ? Icons.photo_camera_outlined
                                      : Icons.attach_file,
                                ),
                          label: Text(
                            usesCamera
                                ? 'Sacar foto del biométrico (opcional)'
                                : 'Adjuntar foto del biométrico (opcional)',
                          ),
                        )
                      else ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: ColoredBox(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Image.memory(
                                raw,
                                fit: BoxFit.contain,
                                semanticLabel: 'Foto del biométrico',
                                errorBuilder: (_, _, _) => const Center(
                                  child: Text('No se puede mostrar la foto'),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: _saving || _capturando
                                  ? null
                                  : _sacarFoto,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Cambiar foto'),
                            ),
                            TextButton.icon(
                              key: const Key('quitar-foto'),
                              onPressed: _saving ? null : _quitarFoto,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Quitar foto'),
                            ),
                          ],
                        ),
                      ],
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
                    onPressed:
                        _saving ||
                            _capturando ||
                            chosen == null ||
                            validation != null
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
