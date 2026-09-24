import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/format/formatters.dart';
import '../../data/attachments/attachment.dart';
import '../../data/banco/banco_repository.dart';
import '../../data/banco/movimiento.dart';
import '../../data/local/app_database.dart';
import '../../data/photos/photo_capture.dart';
import '../../data/providers.dart';
import '../../data/sync/sync_controller.dart';
import '../../domain/domain.dart';
import 'movimiento_acciones.dart';
import 'resumen_banco.dart';
import 'tipos_documento_page.dart';

/// Alta o edición de un movimiento del banco (acumulación, usufructo total
/// o parcial). Devuelve el movimiento guardado, o `null` si se canceló o se
/// borró.
class MovimientoFormPage extends ConsumerStatefulWidget {
  const MovimientoFormPage({
    super.key,
    this.movimiento,
    this.tipoInicial = TipoMovimiento.acumulacion,
    this.fechaInicial,
  });

  /// `null` = movimiento nuevo.
  final LocalMovimiento? movimiento;
  final TipoMovimiento tipoInicial;
  final CalendarDate? fechaInicial;

  @override
  ConsumerState<MovimientoFormPage> createState() => _MovimientoFormPageState();
}

class _MovimientoFormPageState extends ConsumerState<MovimientoFormPage> {
  LocalMovimiento? get _original => widget.movimiento;

  late TipoMovimiento _tipo = _original?.kind ?? widget.tipoInicial;
  late CalendarDate? _fecha = _original?.date ?? widget.fechaInicial;
  late final _minutos = TextEditingController(
    text: _original == null || _original!.kind == TipoMovimiento.usufructoTotal
        ? ''
        : formatMinutes(_original!.minutos),
  );
  late String? _tipoDocumentoId = _original?.tipoDocumentoId;
  late final _numeroGde = TextEditingController(text: _original?.numeroGde);
  late final _observacion = TextEditingController(text: _original?.observacion);

  CambioAdjunto _adjunto = const MantenerAdjunto();
  bool _procesandoAdjunto = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _minutos.dispose();
    _numeroGde.dispose();
    _observacion.dispose();
    super.dispose();
  }

  MovimientoDraft? get _draft {
    final fecha = _fecha;
    if (fecha == null) return null;
    return MovimientoDraft(
      id: _original?.id,
      tipo: _tipo,
      fecha: fecha,
      minutos: _tipo == TipoMovimiento.usufructoTotal
          ? null
          : parseHoursMinutes(_minutos.text),
      tipoDocumentoId: _tipoDocumentoId,
      numeroGde: _numeroGde.text,
      observacion: _observacion.text,
    );
  }

  /// Hay adjunto después de aplicar el cambio elegido.
  bool get _tieneAdjunto => switch (_adjunto) {
    MantenerAdjunto() => _original?.tieneAdjunto ?? false,
    QuitarAdjunto() => false,
    NuevoAdjunto() => true,
  };

  bool get _adjuntoEsPdf => switch (_adjunto) {
    NuevoAdjunto(:final archivo) => archivo.isPdf,
    _ => _original?.adjuntoEsPdf ?? false,
  };

  Future<void> _elegirFecha() async {
    final hoy = ref.read(clockProvider)();
    final actual = _fecha;
    final picked = await showDatePicker(
      context: context,
      initialDate: actual == null
          ? hoy
          : DateTime(actual.year, actual.month, actual.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(hoy.year + 2, 12, 31),
      helpText: 'Fecha del movimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked != null && mounted) {
      setState(() => _fecha = CalendarDate.fromDateTime(picked));
    }
  }

  Future<void> _procesar(Future<Uint8List?> Function() obtener) async {
    setState(() {
      _procesandoAdjunto = true;
      _error = null;
    });
    try {
      final raw = await obtener();
      if (raw == null || !mounted) return;
      final archivo = await prepareAttachment(
        raw,
        compress: ref.read(photoCompressorProvider),
      );
      if (mounted) setState(() => _adjunto = NuevoAdjunto(archivo));
    } on AttachmentException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on PhotoCaptureException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo adjuntar: $e');
    } finally {
      if (mounted) setState(() => _procesandoAdjunto = false);
    }
  }

  Future<void> _sacarFoto() =>
      _procesar(() => ref.read(photoCaptureProvider).capture());

  Future<void> _elegirArchivo() => _procesar(() async {
    final f = await ref.read(attachmentPickerProvider).pickImageOrPdf();
    return f?.bytes;
  });

  Future<void> _administrarTipos() => Navigator.of(
    context,
  ).push<void>(MaterialPageRoute(builder: (_) => const TiposDocumentoPage()));

  Future<void> _guardar() async {
    final userId = ref.read(currentUserIdProvider);
    final draft = _draft;
    if (userId == null || draft == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await ref
          .read(bancoRepositoryProvider)
          .guardarMovimiento(userId: userId, draft: draft, adjunto: _adjunto);
      unawaited(ref.read(syncControllerProvider.notifier).syncNow());
      if (mounted) Navigator.of(context).pop(saved);
    } on BancoInvalidoException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo guardar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _accion(String v) async {
    final m = _original;
    if (m == null) return;
    final nav = Navigator.of(context);
    final bool ok;
    if (v == 'borrar') {
      ok = await borrarMovimiento(context, ref, m);
    } else {
      ok = await cambiarPerdido(context, ref, m, perdido: v == 'perdido');
    }
    if (ok && mounted) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resumen = ref.watch(resumenBancoProvider).value;
    final original = _original;
    final fecha = _fecha;
    final draft = _draft;

    // Validación en vivo con los mismos datos que se muestran.
    String? validation;
    if (resumen != null && draft != null) {
      final minutosVacios =
          _tipo != TipoMovimiento.usufructoTotal &&
          _minutos.text.trim().isEmpty;
      if (!minutosVacios) {
        validation = validarMovimiento(
          draft: draft,
          contexto: resumen.contexto,
          original: original,
        );
      }
    }
    final minutosOk =
        _tipo == TipoMovimiento.usufructoTotal ||
        parseHoursMinutes(_minutos.text) != null;
    final message = _error ?? validation;
    final canSave =
        !_saving &&
        !_procesandoAdjunto &&
        resumen != null &&
        draft != null &&
        minutosOk &&
        validation == null;

    final noLaborable = fecha == null || resumen == null
        ? null
        : nonWorkingDayFor(fecha, resumen.contexto.holidays);
    final jornada = fecha == null || resumen == null
        ? null
        : resumen.calculator.workdayMinutesFor(fecha);
    final tiposActivos = resumen?.tiposActivos ?? const <LocalTipoDocumento>[];
    final tipoActual = _tipoDocumentoId == null
        ? null
        : resumen?.tipos[_tipoDocumentoId];
    final usesCamera = ref.watch(photoCaptureProvider).usesCamera;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          original == null ? 'Nuevo movimiento' : 'Editar movimiento',
        ),
        actions: [
          if (original != null)
            PopupMenuButton<String>(
              key: const Key('acciones-movimiento'),
              tooltip: 'Más acciones',
              onSelected: _accion,
              itemBuilder: (_) => [
                if (original.perdido)
                  const PopupMenuItem(
                    value: 'vigente',
                    child: Text('Volver a vigente'),
                  )
                else
                  const PopupMenuItem(
                    value: 'perdido',
                    child: Text('Marcar como perdido'),
                  ),
                const PopupMenuItem(value: 'borrar', child: Text('Borrar')),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (original?.perdido ?? false)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Este movimiento está marcado como perdido: no '
                            'computa en el saldo.',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      SegmentedButton<TipoMovimiento>(
                        key: const Key('tipo-movimiento'),
                        segments: [
                          for (final t in TipoMovimiento.values)
                            ButtonSegment(
                              value: t,
                              label: Text(t.label, key: Key('tipo-${t.name}')),
                            ),
                        ],
                        selected: {_tipo},
                        showSelectedIcon: false,
                        onSelectionChanged: _saving
                            ? null
                            : (s) => setState(() {
                                _tipo = s.first;
                                _error = null;
                              }),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        key: const Key('elegir-fecha'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          alignment: Alignment.centerLeft,
                        ),
                        onPressed: _saving ? null : _elegirFecha,
                        icon: const Icon(Icons.event),
                        label: Text(
                          fecha == null
                              ? 'Elegir fecha'
                              : 'Fecha: ${nombreDiaSemana(fecha)} '
                                    '${formatDate(fecha)}',
                          key: const Key('fecha-elegida'),
                        ),
                      ),
                      if (noLaborable != null &&
                          _tipo == TipoMovimiento.acumulacion)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${motivoDiaNoLaborableBanco(noLaborable)}. Las '
                            'horas de un día no laborable se cargan como '
                            'acumulación.',
                            key: const Key('aviso-dia-no-laborable'),
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (_tipo == TipoMovimiento.usufructoTotal)
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Horas',
                            helperText:
                                'Jornada vigente de ese día. No se edita.',
                          ),
                          child: Text(
                            jornada == null ? '--:--' : formatMinutes(jornada),
                            key: const Key('minutos-total'),
                          ),
                        )
                      else
                        TextField(
                          key: const Key('minutos'),
                          controller: _minutos,
                          keyboardType: TextInputType.datetime,
                          decoration: InputDecoration(
                            labelText: 'Horas (H:MM)',
                            hintText: 'Ej.: 2:30',
                            helperText: _tipo == TipoMovimiento.usufructoParcial
                                ? 'Salida temprana o llegada tarde. Menos que '
                                      'la jornada.'
                                : 'Horas trabajadas fuera de la jornada.',
                            errorText:
                                _minutos.text.trim().isNotEmpty && !minutosOk
                                ? 'Escribilo como H:MM, por ejemplo 2:30.'
                                : null,
                          ),
                          onChanged: (_) => setState(() => _error = null),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'Respaldo (opcional)',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        key: const Key('tipo-documento'),
                        initialValue: _tipoDocumentoId,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de documento GDE',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Sin documento'),
                          ),
                          for (final t in tiposActivos)
                            DropdownMenuItem<String?>(
                              value: t.id,
                              child: Text(
                                t.descripcion == null
                                    ? t.codigo
                                    : '${t.codigo} · ${t.descripcion}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (tipoActual != null && tipoActual.isDeleted)
                            DropdownMenuItem<String?>(
                              value: tipoActual.id,
                              child: Text('${tipoActual.codigo} (borrado)'),
                            ),
                        ],
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _tipoDocumentoId = v),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          key: const Key('administrar-tipos'),
                          onPressed: _administrarTipos,
                          icon: const Icon(Icons.edit_note),
                          label: Text(
                            tiposActivos.isEmpty
                                ? 'Cargar tipos de documento'
                                : 'Administrar tipos',
                          ),
                        ),
                      ),
                      TextField(
                        key: const Key('numero-gde'),
                        controller: _numeroGde,
                        decoration: const InputDecoration(
                          labelText: 'Número GDE',
                          hintText: 'NO-2026-…-APN-PNL#APNAC',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _Adjunto(
                        tiene: _tieneAdjunto,
                        esPdf: _adjuntoEsPdf,
                        nuevo: _adjunto is NuevoAdjunto,
                        subido:
                            _adjunto is MantenerAdjunto &&
                            original?.adjuntoPath != null,
                        procesando: _procesandoAdjunto,
                        usesCamera: usesCamera,
                        enabled: !_saving,
                        onFoto: _sacarFoto,
                        onArchivo: _elegirArchivo,
                        onQuitar: () =>
                            setState(() => _adjunto = const QuitarAdjunto()),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        key: const Key('observacion'),
                        controller: _observacion,
                        minLines: 2,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Observación',
                        ),
                      ),
                    ],
                  ),
                ),
                // El motivo queda siempre a la vista, arriba de Guardar.
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      message,
                      key: const Key('movimiento-error'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: FilledButton.icon(
                    key: const Key('guardar-movimiento'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                    onPressed: canSave ? _guardar : null,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Guardar'),
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

class _Adjunto extends StatelessWidget {
  const _Adjunto({
    required this.tiene,
    required this.esPdf,
    required this.nuevo,
    required this.subido,
    required this.procesando,
    required this.usesCamera,
    required this.enabled,
    required this.onFoto,
    required this.onArchivo,
    required this.onQuitar,
  });

  final bool tiene;
  final bool esPdf;
  final bool nuevo;
  final bool subido;
  final bool procesando;
  final bool usesCamera;
  final bool enabled;
  final VoidCallback onFoto;
  final VoidCallback onArchivo;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    final botones = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (usesCamera)
          OutlinedButton.icon(
            key: const Key('adjunto-foto'),
            onPressed: enabled && !procesando ? onFoto : null,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Sacar foto'),
          ),
        OutlinedButton.icon(
          key: const Key('adjunto-archivo'),
          onPressed: enabled && !procesando ? onArchivo : null,
          icon: const Icon(Icons.attach_file),
          label: const Text('Elegir imagen o PDF'),
        ),
      ],
    );
    if (procesando) {
      return const ListTile(
        leading: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text('Procesando el adjunto…'),
      );
    }
    if (!tiene) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Adjunto (foto o PDF)'),
          const SizedBox(height: 8),
          botones,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          key: const Key('adjunto-actual'),
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            esPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
          ),
          title: Text(esPdf ? 'Adjunto PDF' : 'Adjunto imagen'),
          subtitle: Text(
            subido
                ? 'Guardado en el servidor.'
                : nuevo
                ? 'Se guarda en el dispositivo y se sube al sincronizar.'
                : 'Pendiente de subir.',
          ),
          trailing: IconButton(
            key: const Key('quitar-adjunto'),
            tooltip: 'Quitar adjunto',
            onPressed: enabled ? onQuitar : null,
            icon: const Icon(Icons.delete_outline),
          ),
        ),
        botones,
      ],
    );
  }
}
