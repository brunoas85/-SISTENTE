-- =============================================================================
-- @sistente · esquema inicial
--
-- Reglas generales (ver CLAUDE.md):
--   * Todas las horas y saldos son minutos enteros (int). Nada de time/interval.
--   * RLS en todas las tablas: cada usuario ve y edita solo sus filas
--     (user_id = auth.uid()). `feriados` es global y de solo lectura.
--   * Tablas sincronizables (offline-first): id uuid generado por el cliente,
--     updated_at mantenido por trigger y borrado lógico con deleted_at.
--     Por eso no hay políticas DELETE en esas tablas: se borra poniendo
--     deleted_at.
--   * La deuda y el a favor diarios NO se guardan: se derivan de `fichadas`.
-- =============================================================================

create extension if not exists btree_gist with schema extensions;

-- -----------------------------------------------------------------------------
-- Tipos enumerados
-- -----------------------------------------------------------------------------
create type public.movimiento_tipo as enum ('acumulacion', 'usufructo');
create type public.movimiento_estado as enum ('vigente', 'perdido');
create type public.usufructo_alcance as enum ('total', 'parcial');
create type public.curso_estado as enum (
  'inscripto', 'en_curso', 'aprobado', 'no_aceptado', 'abandonado'
);

-- -----------------------------------------------------------------------------
-- Utilidades
-- -----------------------------------------------------------------------------

-- Mantiene updated_at en cada UPDATE.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- =============================================================================
-- profiles: configuración por usuario
-- =============================================================================
create table public.profiles (
  user_id     uuid primary key default auth.uid()
              references auth.users (id) on delete cascade,
  nombre      text,
  legajo      text,
  -- Jornada por defecto cuando no hay una fila vigente en `jornadas`.
  jornada_min int  not null default 480
              check (jornada_min between 1 and 1440),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

comment on table public.profiles is
  'Configuración por usuario. jornada_min es la jornada por defecto (minutos).';

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;

create policy "profiles: ver el propio"
  on public.profiles for select to authenticated
  using (user_id = (select auth.uid()));

create policy "profiles: crear el propio"
  on public.profiles for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy "profiles: editar el propio"
  on public.profiles for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- Crea el perfil al registrarse un usuario.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (user_id, nombre)
  values (new.id, new.raw_user_meta_data ->> 'nombre')
  on conflict (user_id) do nothing;
  return new;
end;
$$;

revoke execute on function public.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- =============================================================================
-- jornadas: jornada por persona con vigencia por fecha
-- =============================================================================
create table public.jornadas (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid()
              references auth.users (id) on delete cascade,
  desde       date not null,
  hasta       date,                       -- null = vigente sin fecha de fin
  minutos     int  not null check (minutos between 1 and 1440),
  observacion text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz,
  constraint jornadas_rango_valido check (hasta is null or hasta >= desde),
  -- Dos jornadas activas de la misma persona no pueden superponerse.
  constraint jornadas_sin_superposicion exclude using gist (
    user_id with =,
    daterange(desde, hasta, '[]') with &&
  ) where (deleted_at is null)
);

comment on table public.jornadas is
  'Jornada (minutos) por persona con vigencia [desde, hasta]. Sin fila vigente se usa profiles.jornada_min.';

create index jornadas_user_updated_idx on public.jornadas (user_id, updated_at);

create trigger jornadas_set_updated_at
  before update on public.jornadas
  for each row execute function public.set_updated_at();

alter table public.jornadas enable row level security;

create policy "jornadas: ver las propias"
  on public.jornadas for select to authenticated
  using (user_id = (select auth.uid()));

create policy "jornadas: crear las propias"
  on public.jornadas for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy "jornadas: editar las propias"
  on public.jornadas for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- Jornada aplicable a un usuario en una fecha (minutos).
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
    (select p.jornada_min from public.profiles p where p.user_id = p_user_id),
    480
  );
$$;

-- =============================================================================
-- fichadas: registros de asistencia
-- =============================================================================
create table public.fichadas (
  id                   uuid primary key default gen_random_uuid(), -- lo genera el cliente
  user_id              uuid not null default auth.uid()
                       references auth.users (id) on delete cascade,
  fecha                date not null,
  ingreso_min          int  not null check (ingreso_min between 0 and 1439),
  egreso_min           int           check (egreso_min between 0 and 1439), -- null = abierta, no computa
  -- Hora propuesta por el dispositivo antes de la corrección manual.
  ingreso_original_min int  check (ingreso_original_min between 0 and 1439),
  egreso_original_min  int  check (egreso_original_min between 0 and 1439),
  editado              boolean not null default false,
  foto_ingreso_path    text,
  foto_egreso_path     text,
  observacion          text,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  deleted_at           timestamptz,
  constraint fichadas_egreso_posterior check (egreso_min is null or egreso_min > ingreso_min),
  constraint fichadas_editado_coherente check (
    editado = (ingreso_original_min is not null or egreso_original_min is not null)
  ),
  -- Las rutas de Storage siempre empiezan con la carpeta del dueño.
  constraint fichadas_foto_ingreso_ruta check (
    foto_ingreso_path is null or foto_ingreso_path like user_id::text || '/%'
  ),
  constraint fichadas_foto_egreso_ruta check (
    foto_egreso_path is null or foto_egreso_path like user_id::text || '/%'
  )
);

comment on table public.fichadas is
  'Fichadas contra el reloj biométrico. egreso_min null = abierta (no computa). Minutos desde las 00:00.';
comment on column public.fichadas.ingreso_original_min is
  'Hora de ingreso propuesta por el dispositivo, si luego se corrigió.';
comment on column public.fichadas.egreso_original_min is
  'Hora de egreso propuesta por el dispositivo, si luego se corrigió.';

create index fichadas_user_fecha_idx   on public.fichadas (user_id, fecha) where deleted_at is null;
create index fichadas_user_updated_idx on public.fichadas (user_id, updated_at);

create trigger fichadas_set_updated_at
  before update on public.fichadas
  for each row execute function public.set_updated_at();

alter table public.fichadas enable row level security;

create policy "fichadas: ver las propias"
  on public.fichadas for select to authenticated
  using (user_id = (select auth.uid()));

create policy "fichadas: crear las propias"
  on public.fichadas for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy "fichadas: editar las propias"
  on public.fichadas for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- =============================================================================
-- tipos_documento_gde: catálogo editable por usuario (FSOLI, FOESC, ...)
-- =============================================================================
create table public.tipos_documento_gde (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid()
              references auth.users (id) on delete cascade,
  codigo      text not null check (btrim(codigo) <> ''),
  descripcion text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz,
  -- Permite FK compuesta (id, user_id) desde los movimientos.
  constraint tipos_documento_gde_id_user_key unique (id, user_id)
);

comment on table public.tipos_documento_gde is
  'Catálogo de tipos de documento GDE que respaldan movimientos del banco. Sin códigos hardcodeados.';

-- Código único por usuario entre los tipos activos.
create unique index tipos_documento_gde_codigo_uidx
  on public.tipos_documento_gde (user_id, upper(codigo))
  where deleted_at is null;
create index tipos_documento_gde_user_updated_idx
  on public.tipos_documento_gde (user_id, updated_at);

create trigger tipos_documento_gde_set_updated_at
  before update on public.tipos_documento_gde
  for each row execute function public.set_updated_at();

alter table public.tipos_documento_gde enable row level security;

create policy "tipos_documento_gde: ver los propios"
  on public.tipos_documento_gde for select to authenticated
  using (user_id = (select auth.uid()));

create policy "tipos_documento_gde: crear los propios"
  on public.tipos_documento_gde for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy "tipos_documento_gde: editar los propios"
  on public.tipos_documento_gde for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- =============================================================================
-- banco_horas_movimientos: movimientos MANUALES del banco
-- (el a favor y la deuda diarios se derivan de fichadas, no se guardan acá)
-- =============================================================================
create table public.banco_horas_movimientos (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null default auth.uid()
                    references auth.users (id) on delete cascade,
  tipo              public.movimiento_tipo not null,
  -- Solo para usufructos: jornada completa o parcial (salida temprana, llegada tarde).
  alcance           public.usufructo_alcance,
  fecha             date not null,
  minutos           int  not null check (minutos > 0 and minutos <= 1440),
  estado            public.movimiento_estado not null default 'vigente',
  tipo_documento_id uuid,
  numero_gde        text,
  adjunto_path      text,
  observacion       text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  deleted_at        timestamptz,
  constraint banco_alcance_solo_usufructo check (
    (tipo = 'usufructo') = (alcance is not null)
  ),
  constraint banco_adjunto_ruta check (
    adjunto_path is null or adjunto_path like user_id::text || '/%'
  ),
  -- El tipo de documento tiene que ser del mismo usuario.
  constraint banco_tipo_documento_fk
    foreign key (tipo_documento_id, user_id)
    references public.tipos_documento_gde (id, user_id)
    on delete set null (tipo_documento_id)
);

comment on table public.banco_horas_movimientos is
  'Movimientos manuales del banco de horas (acumulación / usufructo). Un movimiento perdido no computa en el saldo.';

create index banco_user_fecha_idx   on public.banco_horas_movimientos (user_id, fecha) where deleted_at is null;
create index banco_user_updated_idx on public.banco_horas_movimientos (user_id, updated_at);
create index banco_tipo_documento_idx on public.banco_horas_movimientos (tipo_documento_id);

create trigger banco_horas_movimientos_set_updated_at
  before update on public.banco_horas_movimientos
  for each row execute function public.set_updated_at();

alter table public.banco_horas_movimientos enable row level security;

create policy "banco_horas_movimientos: ver los propios"
  on public.banco_horas_movimientos for select to authenticated
  using (user_id = (select auth.uid()));

create policy "banco_horas_movimientos: crear los propios"
  on public.banco_horas_movimientos for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy "banco_horas_movimientos: editar los propios"
  on public.banco_horas_movimientos for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- =============================================================================
-- cursos: capacitación
-- =============================================================================
create table public.cursos (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null default auth.uid()
                   references auth.users (id) on delete cascade,
  actividad        text not null check (btrim(actividad) <> ''),
  codigo           text,                   -- ej. IN-A3-58697
  portal           text,                   -- INAP, SEDRONAR, SRT, ...
  fecha_inicio     date,
  fecha_fin        date,
  creditos         int check (creditos >= 0),
  estado           public.curso_estado not null default 'inscripto',
  if_gde           text,                   -- número de IF de GDE
  certificado_path text,
  observacion      text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  deleted_at       timestamptz,
  constraint cursos_fechas_validas check (
    fecha_inicio is null or fecha_fin is null or fecha_fin >= fecha_inicio
  ),
  constraint cursos_certificado_ruta check (
    certificado_path is null or certificado_path like user_id::text || '/%'
  )
);

comment on table public.cursos is
  'Cursos de capacitación. Créditos cumplidos = suma de créditos con estado aprobado.';

create index cursos_user_inicio_idx  on public.cursos (user_id, fecha_inicio) where deleted_at is null;
create index cursos_user_updated_idx on public.cursos (user_id, updated_at);

create trigger cursos_set_updated_at
  before update on public.cursos
  for each row execute function public.set_updated_at();

alter table public.cursos enable row level security;

create policy "cursos: ver los propios"
  on public.cursos for select to authenticated
  using (user_id = (select auth.uid()));

create policy "cursos: crear los propios"
  on public.cursos for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy "cursos: editar los propios"
  on public.cursos for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- =============================================================================
-- feriados: feriados nacionales de Argentina (global, solo lectura)
-- Se cargan por seed / migración de datos / función con service_role.
-- =============================================================================
create table public.feriados (
  fecha      date primary key,
  nombre     text not null,
  -- inamovible | trasladable | no_laborable (días no laborables / puente)
  tipo       text not null default 'inamovible'
             check (tipo in ('inamovible', 'trasladable', 'no_laborable')),
  created_at timestamptz not null default now()
);

comment on table public.feriados is
  'Feriados nacionales de Argentina. Global; authenticated solo puede leer.';

alter table public.feriados enable row level security;

create policy "feriados: lectura para usuarios autenticados"
  on public.feriados for select to authenticated
  using (true);

revoke insert, update, delete, truncate on public.feriados from anon, authenticated;

-- =============================================================================
-- Storage: buckets privados y políticas por carpeta {user_id}/...
-- Rutas: {user_id}/{yyyy}/{mm}/{uuid}.{ext}
--   comprobantes: fotos del biométrico y adjuntos de movimientos del banco
--   certificados: certificados de cursos
-- =============================================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('comprobantes', 'comprobantes', false, 10485760,
   array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
  ('certificados', 'certificados', false, 10485760,
   array['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
on conflict (id) do nothing;

create policy "storage: ver archivos propios"
  on storage.objects for select to authenticated
  using (
    bucket_id in ('comprobantes', 'certificados')
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "storage: subir archivos propios"
  on storage.objects for insert to authenticated
  with check (
    bucket_id in ('comprobantes', 'certificados')
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "storage: editar archivos propios"
  on storage.objects for update to authenticated
  using (
    bucket_id in ('comprobantes', 'certificados')
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id in ('comprobantes', 'certificados')
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "storage: borrar archivos propios"
  on storage.objects for delete to authenticated
  using (
    bucket_id in ('comprobantes', 'certificados')
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
