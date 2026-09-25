-- Un curso aprobado tiene que tener al menos una fecha (decisión de Bruno,
-- 2026-09-25). Alcanza con la de inicio o la de fin. El cliente ya lo valida en
-- domain/courses.dart (validateCourse); acá lo controla también el servidor.

alter table public.cursos
  add constraint cursos_aprobado_con_fecha check (
    estado <> 'aprobado' or fecha_inicio is not null or fecha_fin is not null
  );
