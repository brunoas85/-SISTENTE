import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/format/formatters.dart';
import '../../../data/fichadas/fichada_validation.dart';
import '../../../data/local/app_database.dart';
import '../../../domain/domain.dart';

/// Guarda el tramo y devuelve el motivo si no se pudo (o `null`).
typedef GuardarTramo = Future<String?> Function(int ingresoMin, int? egresoMin);

/// Edición en línea de un tramo: agregar uno nuevo ([tramo] `null`),
/// corregir las horas o cerrar uno abierto. Valida mientras se escribe con
/// [validarTramoManual] (las mismas reglas que el repositorio). Enter
/// guarda, Esc cancela.
class TramoEditor extends StatefulWidget {
  const TramoEditor({
    super.key,
    required this.fecha,
    required this.hoy,
    required this.otrosDelDia,
    required this.feriados,
    required this.onGuardar,
    required this.onCancelar,
    this.tramo,
    this.dense = false,
    this.inicioControl,
    this.reloj = DateTime.now,
  });

  final CalendarDate fecha;
  final CalendarDate hoy;

  /// El tramo que se edita, o `null` para agregar uno.
  final LocalFichada? tramo;

  /// Tramos activos del día (se ignora el que se edita).
  final List<LocalFichada> otrosDelDia;
  final List<Holiday> feriados;
  final GuardarTramo onGuardar;
  final VoidCallback onCancelar;

  /// Campos compactos (tabla de PC).
  final bool dense;

  /// Primera fichada: no se agregan tramos anteriores.
  final CalendarDate? inicioControl;

  /// Hora actual (hoy no se carga una hora posterior).
  final DateTime Function() reloj;

  @override
  State<TramoEditor> createState() => _TramoEditorState();
}

class _TramoEditorState extends State<TramoEditor> {
  late final _ingreso = TextEditingController(
    text: widget.tramo == null ? '' : formatClock(widget.tramo!.ingresoMin),
  );
  late final _egreso = TextEditingController(
    text: switch (widget.tramo?.egresoMin) {
      null => '',
      final e => formatClock(e),
    },
  );
  bool _saving = false;
  String? _error;

  LocalFichada? get _tramo => widget.tramo;

  /// Cerrar un tramo abierto: el foco va directo al egreso.
  bool get _esCierre => _tramo != null && _tramo!.egresoMin == null;

  @override
  void dispose() {
    _ingreso.dispose();
    _egreso.dispose();
    super.dispose();
  }

  /// Horas escritas, o el motivo por el que no se entienden.
  ({int? ingreso, int? egreso, String? error}) get _horas {
    final ingreso = parseClock(_ingreso.text);
    if (ingreso == null) {
      return (
        ingreso: null,
        egreso: null,
        error: _ingreso.text.trim().isEmpty
            ? 'Falta la hora de ingreso.'
            : 'La hora de ingreso no es válida (usá HH:MM).',
      );
    }
    final texto = _egreso.text.trim();
    if (texto.isEmpty) return (ingreso: ingreso, egreso: null, error: null);
    final egreso = parseClock(texto);
    if (egreso == null) {
      return (
        ingreso: ingreso,
        egreso: null,
        error: 'La hora de egreso no es válida (usá HH:MM).',
      );
    }
    return (ingreso: ingreso, egreso: egreso, error: null);
  }

  bool get _sinCambios {
    final t = _tramo;
    final h = _horas;
    return t != null && h.ingreso == t.ingresoMin && h.egreso == t.egresoMin;
  }

  /// Motivo por el que no se puede guardar todavía, o `null`.
  String? get _validacion {
    final h = _horas;
    if (h.error != null) return h.error;
    final t = _tramo;
    if (t != null && t.egresoMin != null && h.egreso == null) {
      return 'No se puede quitar el egreso. Si el tramo está mal, borralo.';
    }
    // Sin cambios no se guarda, pero se avisa si el tramo ya tiene un
    // problema (por ej. se superpone con otro).
    if (_sinCambios && t!.egresoMin == null) return null;
    final EdicionTramo accion;
    if (t == null) {
      accion = EdicionTramo.alta;
    } else {
      final cambiaHoras =
          t.ingresoMin != h.ingreso ||
          (t.egresoMin != null && t.egresoMin != h.egreso);
      accion = cambiaHoras ? EdicionTramo.edicion : EdicionTramo.cierre;
    }
    return validarTramoManual(
      accion: accion,
      fecha: widget.fecha,
      hoy: widget.hoy,
      id: t?.id,
      ingresoMin: h.ingreso!,
      egresoMin: h.egreso,
      otrosDelDia: widget.otrosDelDia,
      feriados: widget.feriados,
      inicioControl: widget.inicioControl,
      ahoraMin: minutesOfDay(widget.reloj()),
    );
  }

  bool get _puedeGuardar => !_saving && !_sinCambios && _validacion == null;

  Future<void> _guardar() async {
    if (_sinCambios) {
      widget.onCancelar();
      return;
    }
    if (!_puedeGuardar) return;
    final h = _horas;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onGuardar(h.ingreso!, h.egreso);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
  }

  void _cambio() => setState(() => _error = null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Un alta todavía vacía no es un error: se muestra la ayuda.
    final vacio =
        _tramo == null && _ingreso.text.isEmpty && _egreso.text.isEmpty;
    final mensaje = _error ?? (vacio ? null : _validacion);
    final ayuda = _tramo == null
        ? 'Tramo cargado a mano, sin hora del dispositivo.'
        : _esCierre
        ? 'Cargá la hora de egreso para cerrar el tramo.'
        : 'La hora anterior queda registrada como original.';

    Widget campo(String label, TextEditingController c, Key key, bool foco) =>
        SizedBox(
          width: widget.dense ? 96 : 112,
          child: TextField(
            key: key,
            controller: c,
            autofocus: foco,
            enabled: !_saving,
            keyboardType: TextInputType.datetime,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
              LengthLimitingTextInputFormatter(5),
            ],
            decoration: InputDecoration(
              labelText: label,
              hintText: 'HH:MM',
              isDense: widget.dense,
            ),
            style: const TextStyle(
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            onChanged: (_) => _cambio(),
            onSubmitted: (_) => _guardar(),
          ),
        );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): widget.onCancelar,
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                campo(
                  'Ingreso',
                  _ingreso,
                  const Key('editor-ingreso'),
                  !_esCierre,
                ),
                campo('Egreso', _egreso, const Key('editor-egreso'), _esCierre),
                IconButton.filled(
                  key: const Key('editor-guardar'),
                  tooltip: 'Guardar (Enter)',
                  onPressed: _puedeGuardar ? _guardar : null,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                ),
                IconButton(
                  key: const Key('editor-cancelar'),
                  tooltip: 'Cancelar (Esc)',
                  onPressed: _saving ? null : widget.onCancelar,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              mensaje ?? ayuda,
              key: const Key('editor-mensaje'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: mensaje == null
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.error,
                fontWeight: mensaje == null ? null : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
