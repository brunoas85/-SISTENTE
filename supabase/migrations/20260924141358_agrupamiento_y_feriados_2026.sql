-- =============================================================================
-- @sistente · agrupamiento de la persona y feriados nacionales 2026
--
-- Decisiones de Bruno (2026-09-24):
--   * La jornada depende del agrupamiento:
--       administrativo                    -> 480 min (8 h)
--       guardaparque, guardaparque_apoyo  -> 420 min (7 h)
--   * Prioridad para resolver la jornada de un día:
--       1. vigencia en `jornadas` que cubra la fecha
--       2. jornada según profiles.agrupamiento
--       3. profiles.jornada_min
--       4. 480
--   * Los feriados nacionales 2026 se cargan acá (datos públicos). Los días no
--     laborables con fines turísticos (puentes) van como 'no_laborable'.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Agrupamiento
-- -----------------------------------------------------------------------------
create type public.agrupamiento as enum (
  'administrativo', 'guardaparque', 'guardaparque_apoyo'
);

alter table public.profiles
  add column agrupamiento public.agrupamiento;

comment on column public.profiles.agrupamiento is
  'Agrupamiento de la persona. Define la jornada por defecto: administrativo 480 min; guardaparque y guardaparque_apoyo 420 min. null = todavía no lo eligió (la app lo pide).';

comment on column public.profiles.jornada_min is
  'Jornada de respaldo (minutos). Solo se usa si no hay vigencia en jornadas ni agrupamiento elegido.';

comment on table public.jornadas is
  'Jornada (minutos) por persona con vigencia [desde, hasta]. Tiene prioridad sobre el agrupamiento y sobre profiles.jornada_min.';

-- Jornada por defecto de un agrupamiento (null si no hay agrupamiento).
create or replace function public.jornada_por_agrupamiento(p_agrupamiento public.agrupamiento)
returns int
language sql
immutable
set search_path = ''
as $$
  select case p_agrupamiento
           when 'administrativo'     then 480
           when 'guardaparque'       then 420
           when 'guardaparque_apoyo' then 420
         end;
$$;

-- Misma firma que en el esquema inicial: solo cambia el orden de resolución.
-- security invoker: respeta RLS, así que solo resuelve la del propio usuario.
create or replace function public.jornada_minutos(p_user_id uuid, p_fecha date)
returns int
language sql
stable
security invoker
set search_path = ''
as $$
  select coalesce(
    (select j.minutos
       from public.jornadas j
      where j.user_id = p_user_id
        and j.deleted_at is null
        and j.desde <= p_fecha
        and (j.hasta is null or j.hasta >= p_fecha)
      limit 1),
    (select public.jornada_por_agrupamiento(p.agrupamiento)
       from public.profiles p
      where p.user_id = p_user_id),
    (select p.jornada_min from public.profiles p where p.user_id = p_user_id),
    480
  );
$$;

-- -----------------------------------------------------------------------------
-- Feriados nacionales 2026 (fecha en que se observan)
-- Fuentes: argentina.gob.ar, api.argentinadatos.com, Infobae.
-- -----------------------------------------------------------------------------
insert into public.feriados (fecha, nombre, tipo) values
  -- inamovibles
  ('2026-01-01', 'Año Nuevo', 'inamovible'),
  ('2026-02-16', 'Carnaval', 'inamovible'),
  ('2026-02-17', 'Carnaval', 'inamovible'),
  ('2026-03-24', 'Día Nacional de la Memoria por la Verdad y la Justicia', 'inamovible'),
  ('2026-04-02', 'Día del Veterano y de los Caídos en la Guerra de Malvinas', 'inamovible'),
  ('2026-04-03', 'Viernes Santo', 'inamovible'),
  ('2026-05-01', 'Día del Trabajador', 'inamovible'),
  ('2026-05-25', 'Día de la Revolución de Mayo', 'inamovible'),
  ('2026-06-20', 'Paso a la Inmortalidad del Gral. Manuel Belgrano', 'inamovible'),
  ('2026-07-09', 'Día de la Independencia', 'inamovible'),
  ('2026-12-08', 'Inmaculada Concepción de María', 'inamovible'),
  ('2026-12-25', 'Navidad', 'inamovible'),
  -- trasladables
  ('2026-06-15', 'Paso a la Inmortalidad del Gral. Martín Miguel de Güemes (17/6)', 'trasladable'),
  ('2026-08-17', 'Paso a la Inmortalidad del Gral. José de San Martín', 'trasladable'),
  ('2026-10-12', 'Día del Respeto a la Diversidad Cultural', 'trasladable'),
  ('2026-11-23', 'Día de la Soberanía Nacional (20/11)', 'trasladable'),
  -- días no laborables con fines turísticos (puentes)
  ('2026-03-23', 'Día no laborable con fines turísticos', 'no_laborable'),
  ('2026-07-10', 'Día no laborable con fines turísticos', 'no_laborable'),
  ('2026-12-07', 'Día no laborable con fines turísticos', 'no_laborable')
on conflict (fecha) do nothing;
