import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import 'perfil_providers.dart';

/// Lista de agrupamientos para elegir uno, con la jornada de cada uno.
class AgrupamientoSelector extends StatelessWidget {
  const AgrupamientoSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
  });

  final Agrupamiento? selected;
  final ValueChanged<Agrupamiento> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<Agrupamiento>(
      groupValue: selected,
      onChanged: (a) {
        if (a != null && enabled) onSelected(a);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final a in Agrupamiento.values)
            RadioListTile<Agrupamiento>(
              key: Key('agrupamiento-${a.dbValue}'),
              value: a,
              enabled: enabled,
              title: Text(agrupamientoLabel(a)),
              subtitle: Text('Jornada de ${formatMinutes(a.workdayMinutes)} h'),
            ),
        ],
      ),
    );
  }
}
