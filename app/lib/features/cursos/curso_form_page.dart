import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/format/formatters.dart';
import '../../data/attachments/attachment.dart';
import '../../data/cursos/curso.dart';
import '../../data/cursos/cursos_repository.dart';
import '../../data/local/app_database.dart';
import '../../data/photos/photo_capture.dart';
import '../../data/providers.dart';
import '../../data/sync/sync_controller.dart';
import '../../domain/domain.dart';
import 'curso_acciones.dart';
import 'cursos_providers.dart';

/// Alta o edición de un curso. Devuelve el curso guardado, o `null` si se
/// canceló o se borró.
class CursoFormPage extends ConsumerStatefulWidget {
  const CursoFormPage({super.key, this.curso});

  /// `null` = curso nuevo.
  final LocalCurso? curso;

  @override
  ConsumerState<CursoFormPage> createState() => _CursoFormPageState();
}

class _CursoFormPageState extends ConsumerState<CursoFormPage> {
  LocalCurso? get _original => widget.curso;

  late final _actividad = TextEditingController(text: _original?.actividad);
  late final _codigo = TextEditingController(text: _original?.codigo);
  late final _portal = TextEditingController(text: _original?.portal);
  final _portalFocus = FocusNode();
  late final _creditos = TextEditingController(
    text: _original?.creditos?.toString(),
  );
  late final _ifGde = TextEditingController(text: _original?.ifGde);
  late final _observacion = TextEditingController(text: _original?.observacion);
  late CalendarDate? _inicio = _original?.inicio;
  late CalendarDate? _fin = _original?.fin;
  late CourseStatus _estado = _original?.status ?? CourseStatus.enrolled;

  CambioAdjunto _certificado = const MantenerAdjunto();
  bool _procesando = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _actividad.dispose();
    _codigo.dispose();
    _portal.dispose();
    _portalFocus.dispose();
    _creditos.dispose();
    _ifGde.dispose();
    _observacion.dispose();
    super.dispose();
  }

  CursoDraft get _draft => CursoDraft(
    id: _original?.id,
    actividad: _actividad.text,
    codigo: _codigo.text,
    portal: _portal.text,
    fechaInicio: _inicio,
    fechaFin: _fin,
    creditos: int.tryParse(_creditos.text.trim()),
    estado: _estado,
    ifGde: _ifGde.text,
    observacion: _observacion.text,
  );

  /// Hay certificado después de aplicar el cambio elegido.
  bool get _tieneCertificado => switch (_certificado) {
    MantenerAdjunto() => _original?.tieneCertificado ?? false,
    QuitarAdjunto() => false,
    NuevoAdjunto() => true,
  };

  bool get _certificadoEsPdf => switch (_certificado) {
    NuevoAdjunto(:final archivo) => archivo.isPdf,
    _ => _original?.certificadoEsPdf ?? false,
  };

  Future<void> _elegirFecha({required bool inicio}) async {
    final hoy = ref.read(clockProvider)();
    final actual = inicio ? _inicio : _fin ?? _inicio;
    final picked = await showDatePicker(
      context: context,
      initialDate: actual == null
          ? hoy
          : DateTime(actual.year, actual.month, actual.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(hoy.year + 5, 12, 31),
      helpText: inicio ? 'Fecha de inicio' : 'Fecha de fin',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked == null || !mounted) return;
    final d = CalendarDate.fromDateTime(picked);
    setState(() {
      if (inicio) {
        _inicio = d;
      } else {
        _fin = d;
      }
      _error = null;
    });
  }

  Future<void> _procesar(Future<Uint8List?> Function() obtener) async {
    setState(() {
      _procesando = true;
      _error = null;
    });
    try {
      final raw = await obtener();
      if (raw == null || !mounted) return;
      final archivo = await prepareAttachment(
        raw,
        compress: ref.read(photoCompressorProvider),
      );
      if (mounted) setState(() => _certificado = NuevoAdjunto(archivo));
    } on AttachmentException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on PhotoCaptureException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo adjuntar: $e');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _sacarFoto() =>
      _procesar(() => ref.read(photoCaptureProvider).capture());

  Future<void> _elegirArchivo() => _procesar(() async {
    final f = await ref.read(attachmentPickerProvider).pickImageOrPdf();
    return f?.bytes;
  });

  Future<void> _guardar() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await ref
          .read(cursosRepositoryProvider)
          .guardarCurso(
            userId: userId,
            draft: _draft,
            certificado: _certificado,
          );
      unawaited(ref.read(syncControllerProvider.notifier).syncNow());
      if (mounted) Navigator.of(context).pop(saved);
    } on CursoInvalidoException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo guardar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _borrar() async {
    final c = _original;
    if (c == null) return;
    final nav = Navigator.of(context);
    if (await borrarCurso(context, ref, c) && mounted) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final original = _original;
    final draft = _draft;
    final creditosTexto = _creditos.text.trim();
    final creditosOk =
        creditosTexto.isEmpty || int.tryParse(creditosTexto) != null;
    // La actividad vacía se marca en el campo, no como error general.
    final validation = draft.actividad.trim().isEmpty ? null : draft.validar();
    final message = _error ?? validation;
    final canSave =
        !_saving &&
        !_procesando &&
        draft.actividad.trim().isNotEmpty &&
        creditosOk &&
        validation == null;
    final avisos = courseWarnings(
      Course(
        id: original?.id ?? '',
        activity: draft.actividad,
        status: _estado,
        gdeIfNumber: draft.ifGde,
        hasCertificate: _tieneCertificado,
      ),
    );
    final usados = [
      for (final c
          in ref.watch(misCursosProvider).value ?? const <LocalCurso>[])
        c.portal,
    ];
    final sugerencias = portalSuggestions(usados);
    final usesCamera = ref.watch(photoCaptureProvider).usesCamera;

    Widget fecha({required bool inicio}) {
      final valor = inicio ? _inicio : _fin;
      final nombre = inicio ? 'inicio' : 'fin';
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              key: Key('fecha-$nombre'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                alignment: Alignment.centerLeft,
              ),
              onPressed: _saving ? null : () => _elegirFecha(inicio: inicio),
              icon: const Icon(Icons.event),
              label: Text(
                valor == null
                    ? 'Fecha de $nombre (opcional)'
                    : 'Fecha de $nombre: ${formatDate(valor)}',
              ),
            ),
          ),
          if (valor != null)
            IconButton(
              key: Key('quitar-fecha-$nombre'),
              tooltip: 'Quitar la fecha de $nombre',
              onPressed: _saving
                  ? null
                  : () => setState(() {
                      if (inicio) {
                        _inicio = null;
                      } else {
                        _fin = null;
                      }
                    }),
              icon: const Icon(Icons.clear),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(original == null ? 'Nuevo curso' : 'Editar curso'),
        actions: [
          if (original != null)
            IconButton(
              key: const Key('borrar-curso'),
              tooltip: 'Borrar curso',
              onPressed: _saving ? null : _borrar,
              icon: const Icon(Icons.delete_outline),
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
                      TextField(
                        key: const Key('curso-actividad'),
                        controller: _actividad,
                        autofocus: original == null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Actividad *',
                          hintText: 'Nombre del curso',
                        ),
                        onChanged: (_) => setState(() => _error = null),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        key: const Key('curso-codigo'),
                        controller: _codigo,
                        decoration: const InputDecoration(
                          labelText: 'Código',
                          hintText: 'Ej.: IN-A3-00000',
                        ),
                      ),
                      const SizedBox(height: 16),
                      RawAutocomplete<String>(
                        textEditingController: _portal,
                        focusNode: _portalFocus,
                        optionsBuilder: (value) {
                          final q = foldForSearch(value.text.trim());
                          return sugerencias.where(
                            (s) => q.isEmpty || foldForSearch(s).contains(q),
                          );
                        },
                        fieldViewBuilder:
                            (context, controller, focus, submit) => TextField(
                              key: const Key('curso-portal'),
                              controller: controller,
                              focusNode: focus,
                              decoration: const InputDecoration(
                                labelText: 'Portal',
                                hintText: 'INAP, SEDRONAR, SRT…',
                              ),
                              onSubmitted: (_) => submit(),
                            ),
                        optionsViewBuilder: (context, onSelected, options) =>
                            Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4,
                                borderRadius: BorderRadius.circular(8),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 240,
                                    maxWidth: 400,
                                  ),
                                  child: ListView(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    children: [
                                      for (final o in options)
                                        ListTile(
                                          key: Key('portal-sugerido-$o'),
                                          title: Text(o),
                                          onTap: () => onSelected(o),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                      ),
                      const SizedBox(height: 16),
                      fecha(inicio: true),
                      const SizedBox(height: 8),
                      fecha(inicio: false),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('curso-creditos'),
                              controller: _creditos,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: 'Créditos',
                                hintText: 'Ej.: 3',
                                errorText: creditosOk
                                    ? null
                                    : 'Escribí un número entero.',
                              ),
                              onChanged: (_) => setState(() => _error = null),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<CourseStatus>(
                              key: const Key('curso-estado'),
                              initialValue: _estado,
                              // En el celular la mitad del ancho no alcanza
                              // para "No aceptado" sin recortar.
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Estado',
                              ),
                              items: [
                                for (final s in CourseStatus.values)
                                  DropdownMenuItem(
                                    value: s,
                                    child: Text(
                                      s.label,
                                      key: Key('estado-${s.dbValue}'),
                                    ),
                                  ),
                              ],
                              onChanged: _saving
                                  ? null
                                  : (s) {
                                      if (s != null) {
                                        setState(() => _estado = s);
                                      }
                                    },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Respaldo (opcional)',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('curso-if'),
                        controller: _ifGde,
                        decoration: const InputDecoration(
                          labelText: 'Número de IF (GDE)',
                          hintText: 'IF-2026-…-APN-…',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      _Certificado(
                        tiene: _tieneCertificado,
                        esPdf: _certificadoEsPdf,
                        nuevo: _certificado is NuevoAdjunto,
                        subido:
                            _certificado is MantenerAdjunto &&
                            original?.certificadoPath != null,
                        procesando: _procesando,
                        usesCamera: usesCamera,
                        enabled: !_saving,
                        onFoto: _sacarFoto,
                        onArchivo: _elegirArchivo,
                        onVer:
                            _certificado is MantenerAdjunto &&
                                (original?.tieneCertificado ?? false)
                            ? () => mostrarCertificado(context, original!)
                            : null,
                        onQuitar: () => setState(
                          () => _certificado = const QuitarAdjunto(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        key: const Key('curso-observacion'),
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
                if (avisos.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _Avisos(avisos: avisos),
                  ),
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      message,
                      key: const Key('curso-error'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: FilledButton.icon(
                    key: const Key('guardar-curso'),
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

/// Avisos suaves (no impiden guardar).
class _Avisos extends StatelessWidget {
  const _Avisos({required this.avisos});

  final List<CourseWarning> avisos;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: 'Avisos',
      child: DecoratedBox(
        key: const Key('avisos-curso'),
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: scheme.onTertiaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${avisos.map((a) => a.label).join(' · ')}. '
                  'Podés guardar igual y completarlo después.',
                  style: TextStyle(color: scheme.onTertiaryContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Certificado extends StatelessWidget {
  const _Certificado({
    required this.tiene,
    required this.esPdf,
    required this.nuevo,
    required this.subido,
    required this.procesando,
    required this.usesCamera,
    required this.enabled,
    required this.onFoto,
    required this.onArchivo,
    required this.onVer,
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
  final VoidCallback? onVer;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    if (procesando) {
      return const ListTile(
        leading: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text('Procesando el certificado…'),
      );
    }
    final botones = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (usesCamera)
          OutlinedButton.icon(
            key: const Key('certificado-foto'),
            onPressed: enabled ? onFoto : null,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Sacar foto'),
          ),
        OutlinedButton.icon(
          key: const Key('certificado-archivo'),
          onPressed: enabled ? onArchivo : null,
          icon: const Icon(Icons.attach_file),
          label: const Text('Elegir imagen o PDF'),
        ),
      ],
    );
    if (!tiene) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Certificado (foto o PDF, hasta 10 MB)'),
          const SizedBox(height: 8),
          botones,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          key: const Key('certificado-actual'),
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            esPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
          ),
          title: Text(esPdf ? 'Certificado PDF' : 'Certificado imagen'),
          subtitle: Text(
            subido
                ? 'Guardado en el servidor.'
                : nuevo
                ? 'Se guarda en el dispositivo y se sube al sincronizar.'
                : 'Pendiente de subir.',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onVer != null)
                IconButton(
                  key: const Key('ver-certificado'),
                  tooltip: 'Ver certificado',
                  onPressed: onVer,
                  icon: const Icon(Icons.visibility_outlined),
                ),
              IconButton(
                key: const Key('quitar-certificado'),
                tooltip: 'Quitar certificado',
                onPressed: enabled ? onQuitar : null,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
        botones,
      ],
    );
  }
}
