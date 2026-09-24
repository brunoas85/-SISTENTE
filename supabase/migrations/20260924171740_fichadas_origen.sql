-- Origen de cada tramo (decisión de Bruno, 2026-09-24): un tramo cargado a
-- mano desde la PC tiene que quedar marcado como tal.
--   dispositivo: fichado con el botón Fichar (hora propuesta por el dispositivo)
--   manual:      agregado a mano (vista mensual o cierre de un tramo anterior)
--   importado:   traído de la planilla xlsx
-- Las filas existentes quedan como 'dispositivo'.

alter table public.fichadas
  add column origen text not null default 'dispositivo'
  constraint fichadas_origen_valido
    check (origen in ('dispositivo', 'manual', 'importado'));

comment on column public.fichadas.origen is
  'Cómo se cargó el tramo: dispositivo (Fichar), manual (cargado a mano) o importado (xlsx).';
