-- =============================================================================
-- @sistente · seed local
-- SOLO DATOS FICTICIOS. No cargar nombres, legajos, números GDE ni fotos reales.
--
-- Usuarios de prueba (solo stack local):
--   demo@example.com  / demo1234   -> con datos de ejemplo
--   otro@example.com  / otro1234   -> segundo usuario, para probar RLS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Usuarios ficticios (auth.users + auth.identities)
-- El trigger on_auth_user_created crea la fila en public.profiles.
-- -----------------------------------------------------------------------------
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, email_change, email_change_token_new, recovery_token
)
values
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-4000-8000-000000000001',
   'authenticated', 'authenticated', 'demo@example.com',
   extensions.crypt('demo1234', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{"nombre":"Agente Demo"}',
   now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-4000-8000-000000000002',
   'authenticated', 'authenticated', 'otro@example.com',
   extensions.crypt('otro1234', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{"nombre":"Agente Otro"}',
   now(), now(), '', '', '', '');

insert into auth.identities (
  id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at
)
values
  (gen_random_uuid(), '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000001',
   '{"sub":"00000000-0000-4000-8000-000000000001","email":"demo@example.com","email_verified":true}',
   'email', now(), now(), now()),
  (gen_random_uuid(), '00000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000002',
   '{"sub":"00000000-0000-4000-8000-000000000002","email":"otro@example.com","email_verified":true}',
   'email', now(), now(), now());

update public.profiles set legajo = '000000' where user_id = '00000000-0000-4000-8000-000000000001';
update public.profiles set legajo = '999999' where user_id = '00000000-0000-4000-8000-000000000002';

-- -----------------------------------------------------------------------------
-- Jornadas: 480 min hasta agosto, 420 min desde septiembre (para probar vigencias)
-- -----------------------------------------------------------------------------
insert into public.jornadas (user_id, desde, hasta, minutos, observacion) values
  ('00000000-0000-4000-8000-000000000001', '2026-01-01', '2026-08-31', 480, 'Jornada de ejemplo'),
  ('00000000-0000-4000-8000-000000000001', '2026-09-01', null,         420, 'Jornada reducida de ejemplo');

-- -----------------------------------------------------------------------------
-- Tipos de documento GDE de ejemplo (el catálogo es editable por el usuario)
-- -----------------------------------------------------------------------------
insert into public.tipos_documento_gde (id, user_id, codigo, descripcion) values
  ('10000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000001', 'FSOLI', 'Tipo de ejemplo FSOLI'),
  ('10000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000001', 'FOESC', 'Tipo de ejemplo FOESC'),
  ('10000000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-000000000002', 'FSOLI', 'Tipo de ejemplo del otro usuario');

-- -----------------------------------------------------------------------------
-- Fichadas (minutos desde las 00:00). Casos raros incluidos.
-- -----------------------------------------------------------------------------
insert into public.fichadas
  (user_id, fecha, ingreso_min, egreso_min, ingreso_original_min, egreso_original_min, editado, observacion)
values
  -- agosto (jornada 480)
  ('00000000-0000-4000-8000-000000000001', '2026-08-03', 480, 960,  null, null, false, 'Jornada exacta 08:00-16:00'),
  ('00000000-0000-4000-8000-000000000001', '2026-08-04', 470, 1010, null, null, false, 'A favor 60 min'),
  ('00000000-0000-4000-8000-000000000001', '2026-08-05', 500, 900,  null, null, false, 'Deuda 80 min'),
  ('00000000-0000-4000-8000-000000000001', '2026-08-06', 485, null, null, null, false, 'Egreso vacío: abierta, no computa'),
  ('00000000-0000-4000-8000-000000000001', '2026-08-07', 480, 780,  null, null, false, 'Salida temprana cubierta por usufructo parcial'),
  -- septiembre (jornada 420)
  ('00000000-0000-4000-8000-000000000001', '2026-09-01', 480, 900,  null, null, false, 'Jornada exacta 420'),
  ('00000000-0000-4000-8000-000000000001', '2026-09-02', 475, 900,  482,  null, true,  'Ingreso corregido a mano'),
  -- otro usuario (para probar RLS)
  ('00000000-0000-4000-8000-000000000002', '2026-08-03', 420, 900,  null, null, false, 'Dato del otro usuario');

-- -----------------------------------------------------------------------------
-- Movimientos manuales del banco
-- -----------------------------------------------------------------------------
insert into public.banco_horas_movimientos
  (user_id, tipo, alcance, fecha, minutos, estado, tipo_documento_id, numero_gde, observacion)
values
  ('00000000-0000-4000-8000-000000000001', 'acumulacion', null,      '2026-08-08', 240, 'vigente', null,
   null, 'Sábado trabajado (ficticio)'),
  ('00000000-0000-4000-8000-000000000001', 'usufructo',   'parcial', '2026-08-07', 180, 'vigente',
   '10000000-0000-4000-8000-000000000002', 'NO-2026-00000001-APN-PNL#APNAC', 'Salida temprana (ficticio)'),
  ('00000000-0000-4000-8000-000000000001', 'usufructo',   'total',   '2026-08-10', 480, 'vigente',
   '10000000-0000-4000-8000-000000000001', 'NO-2026-00000002-APN-PNL#APNAC', 'Día completo sin fichada (ficticio)'),
  ('00000000-0000-4000-8000-000000000001', 'usufructo',   'total',   '2026-08-11', 480, 'perdido',
   '10000000-0000-4000-8000-000000000001', 'NO-2026-00000003-APN-PNL#APNAC', 'Perdido: no descuenta (ficticio)'),
  ('00000000-0000-4000-8000-000000000002', 'acumulacion', null,      '2026-08-08', 60,  'vigente', null,
   null, 'Dato del otro usuario');

-- -----------------------------------------------------------------------------
-- Cursos
-- -----------------------------------------------------------------------------
insert into public.cursos
  (user_id, actividad, codigo, portal, fecha_inicio, fecha_fin, creditos, estado, if_gde)
values
  ('00000000-0000-4000-8000-000000000001', 'Curso ficticio de ofimática',   'IN-A0-00001', 'INAP',     '2026-03-02', '2026-04-10', 10, 'aprobado',    'IF-2026-00000001-APN-PNL#APNAC'),
  ('00000000-0000-4000-8000-000000000001', 'Curso ficticio de prevención',  'SE-00002',    'SEDRONAR', '2026-05-04', '2026-06-12', 6,  'abandonado',  null),
  ('00000000-0000-4000-8000-000000000001', 'Curso ficticio de seguridad',   'SRT-00003',   'SRT',      '2026-09-07', '2026-10-16', 8,  'en_curso',    null),
  ('00000000-0000-4000-8000-000000000001', 'Curso ficticio con cupo lleno', 'IN-A0-00004', 'INAP',     '2026-10-05', null,         4,  'no_aceptado', null),
  ('00000000-0000-4000-8000-000000000002', 'Curso del otro usuario',        'IN-A0-00005', 'INAP',     '2026-03-02', '2026-04-10', 3,  'aprobado',    null);

-- -----------------------------------------------------------------------------
-- Feriados nacionales 2026 (datos públicos, no personales).
-- VERIFICAR contra el decreto oficial antes de usarlos en producción:
-- los trasladables ya están movidos según la ley 27.399 y no se incluyen
-- los días no laborables con fines turísticos.
-- -----------------------------------------------------------------------------
insert into public.feriados (fecha, nombre, tipo) values
  ('2026-01-01', 'Año Nuevo', 'inamovible'),
  ('2026-02-16', 'Carnaval', 'inamovible'),
  ('2026-02-17', 'Carnaval', 'inamovible'),
  ('2026-03-24', 'Día Nacional de la Memoria por la Verdad y la Justicia', 'inamovible'),
  ('2026-04-02', 'Día del Veterano y de los Caídos en la Guerra de Malvinas', 'inamovible'),
  ('2026-04-03', 'Viernes Santo', 'inamovible'),
  ('2026-05-01', 'Día del Trabajador', 'inamovible'),
  ('2026-05-25', 'Día de la Revolución de Mayo', 'inamovible'),
  ('2026-06-15', 'Paso a la Inmortalidad del Gral. Martín Miguel de Güemes', 'trasladable'),
  ('2026-06-20', 'Paso a la Inmortalidad del Gral. Manuel Belgrano', 'inamovible'),
  ('2026-07-09', 'Día de la Independencia', 'inamovible'),
  ('2026-08-17', 'Paso a la Inmortalidad del Gral. José de San Martín', 'trasladable'),
  ('2026-10-12', 'Día del Respeto a la Diversidad Cultural', 'trasladable'),
  ('2026-11-23', 'Día de la Soberanía Nacional', 'trasladable'),
  ('2026-12-08', 'Inmaculada Concepción de María', 'inamovible'),
  ('2026-12-25', 'Navidad', 'inamovible')
on conflict (fecha) do nothing;
