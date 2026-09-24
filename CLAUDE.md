# @sistente

**Nombre visible de la app: `@sistente`** (con arroba), en el título, el
launcher, la pestaña del navegador y las tiendas. Donde el `@` no está
permitido se usa `asistente`: nombre del paquete Dart, carpeta del repo,
bundle id / applicationId y nombres de buckets.

App personal para llevar el control administrativo de un agente de la APN
(Parque Nacional Lanín): asistencia contra el reloj biométrico, banco de horas,
licencias/franquicias y cursos de capacitación. Reemplaza la planilla
`control asistencia.v2.xlsx` (3 hojas: CONTROL ASISTENCIA, CONTROL BANCO DE
HORAS, CONTROL CURSOS).

Idioma de la UI, los datos y los mensajes de commit: **español (Argentina)**.
Nombres de código (clases, variables, tablas): inglés.

## Dos contextos de uso

| | Celular (Android / iOS) | PC (web / Windows) |
|---|---|---|
| Para qué | Fichar rápido: ingreso/egreso + **foto del biométrico** como comprobante | Cargar, editar y revisar: tablas, resúmenes mensuales, cursos, importar/exportar |
| Conectividad | Puede no haber señal → **offline-first**, cola de sincronización | Siempre online |
| UI | Una mano, botones grandes, cámara | Tablas densas, filtros, edición en línea, atajos de teclado |

Es **una sola base de código**. La diferencia entre los dos es de layout
(responsive por ancho), no de features duplicadas.

## Stack

- **Frontend:** Flutter (Android + iOS + web + Windows). Riverpod para el estado,
  go_router para la navegación, drift (SQLite) como base local, `camera`/`image_picker`
  para las fotos.
- **Backend:** Supabase (Postgres + Auth + Storage + Edge Functions en TypeScript/Deno).
  Row Level Security en **todas** las tablas.
- **Deploy web:** Vercel (igual que `fwi-lanin-web`).
- **iOS:** para compilar y firmar hace falta macOS con Xcode, o un CI en la
  nube (Codemagic / GitHub Actions `macos-latest`). En esta PC Windows se
  desarrolla y se prueba en Android/web. No uses plugins sin soporte iOS, y
  declará los permisos en `ios/Runner/Info.plist`
  (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`).

```
asistente/
├── app/                 # proyecto Flutter
│   └── lib/
│       ├── core/        # tema, router, utilidades de tiempo, cliente Supabase
│       ├── data/        # drift (local), repositorios, sync
│       ├── domain/      # modelos y reglas de cálculo (Dart puro, sin Flutter)
│       └── features/    # asistencia/, banco_horas/, licencias/, cursos/, importar/
├── supabase/
│   ├── migrations/      # SQL versionado (única fuente del esquema)
│   ├── functions/       # Edge Functions
│   └── seed.sql
└── .claude/agents/      # frontend-flutter.md, backend-supabase.md
```

## Reglas de negocio (de la planilla original)

Guardar **todas las horas como minutos enteros** (`int`) y las fechas como `date`.
Nunca usar horas estilo Excel (fracción de día): no representan saldos negativos.

**Asistencia diaria**
- `trabajado = egreso - ingreso` (sin descuento de almuerzo).
- `jornada` por defecto 480 min (8 h), configurable por persona y con vigencia por fecha.
- `deuda = max(jornada - trabajado, 0)` · `a_favor = max(trabajado - jornada, 0)`.
- **Un registro sin egreso está *abierto* y no computa.** En la planilla, un
  egreso vacío daba −5:53 trabajadas y 13:53 de deuda; ese error no se repite acá.
- Un día cubierto por un usufructo del banco **no genera deuda**. En la planilla
  el 01/06 se contaba como deuda y como usufructo al mismo tiempo: un día tiene
  un solo estado. Un usufructo parcial (salida temprana, llegada tarde) cubre
  solo esos minutos.

**Banco de horas (una sola cuenta)**
- El banco se alimenta de:
  - `a_favor` diario → entra **automáticamente** (derivado de las fichadas, no
    se carga dos veces);
  - `deuda` diaria → sale automáticamente, salvo la parte cubierta por un usufructo;
  - `acumulacion` manual: horas fuera de jornada, por ej. sábados;
  - `usufructo`: una jornada completa (480 min) o parcial.
- `saldo = Σ a_favor + Σ acumulacion - Σ deuda no cubierta - Σ usufructo vigente`.
  **Puede ser negativo** y la UI tiene que mostrarlo (formato `-24:00`, nunca `#####`).
- Un movimiento `perdido` (usufructo o acumulación) **no computa** en el banco. Queda registrado solo como historial.

**Documentos GDE**
- `FSOLI`, `FOESC`, etc. son **tipos de documento GDE** que respaldan los
  movimientos del banco (usufructos, salidas tempranas, llegadas tarde,
  comisiones). **No** son licencias aparte del banco.
- Catálogo editable de tipos (código y descripción). No hardcodear códigos.
- Cada movimiento del banco puede llevar tipo de documento, número GDE
  (`NO-2026-…-APN-PNL#APNAC`) y adjunto.

**Cursos**
- Actividad, código (ej. `IN-A3-58697`), portal (INAP, SEDRONAR, SRT…),
  fecha de inicio y de fin, créditos y **estado** (`inscripto`, `en_curso`,
  `aprobado`, `no_aceptado`, `abandonado`) en vez del SI/NO de la planilla.
- Número de IF de GDE y certificado adjunto (PDF/imagen).
- Créditos cumplidos = suma de créditos con estado `aprobado`, filtrable por año.

**Resúmenes**
- Siempre por **año + mes** (la planilla filtraba solo por el nombre del mes).
- Días hábiles sin registro ni usufructo → se marcan como *faltantes* y restan la jornada del banco
  (hay que tener en cuenta los feriados nacionales de Argentina).

## Fichada con foto (celular)

1. "Fichar ingreso/egreso" → abre la cámara → foto del biométrico.
2. La hora propuesta es la del dispositivo. Se puede corregir, y la corrección
   queda registrada (`hora_original`, `editado`).
3. La foto se comprime (lado largo ≤ 1600 px, JPEG ~80 %) y se guarda local.
   Se sube al bucket privado `comprobantes/{user_id}/{yyyy}/{mm}/…` cuando hay red.
4. Todo funciona sin conexión. La sincronización se reintenta sola y el estado
   (pendiente / sincronizado / error) se ve en la UI.

## Importación

Tiene que haber un importador de `control asistencia.v2.xlsx` (y de versiones
similares). Lo hace una Edge Function o el cliente en PC y aplica estas reglas:
ignora filas de relleno (sin ingreso), normaliza las horas a minutos, reporta
las filas dudosas en vez de adivinar y **nunca pisa** datos existentes sin confirmación.

## Datos personales

Son datos laborales y fotos de una persona. RLS con `auth.uid() = user_id`
en todo, buckets privados, URLs firmadas de corta duración y nada de datos
reales en tests, seeds ni capturas: usá datos ficticios.

## Comandos

```bash
# App
cd app && flutter pub get
cd app && flutter run -d chrome --dart-define-from-file=env/dev.json   # PC/web (config en env/dev.json, ver env/example.json)
cd app && flutter run -d <android-id>    # celular
cd app && flutter build ipa              # iOS (solo en macOS/CI)
cd app && flutter test
cd app && dart run build_runner build --delete-conflicting-outputs   # drift/riverpod

# Backend
supabase start                  # stack local (Docker)
supabase migration new <nombre>
supabase db reset               # aplica migraciones + seed
supabase functions serve
supabase gen types dart ...     # tras cambiar el esquema
```

## Cómo trabajar en este repo

- **Decisiones ya tomadas por Bruno (2026-09-23):** un usufructo perdido no
  descuenta, el a favor diario va al banco y FSOLI/FOESC son tipos de
  documento GDE que forman parte del banco, y la deuda diaria no cubierta
  resta del banco.
- **Decisiones de Bruno (2026-09-24):**
  - Puede haber varias fichadas en el mismo día (salir y volver). El trabajado
    es la suma de los tramos, y si dos tramos se superponen es un conflicto.
  - Un día hábil sin fichada ni usufructo es *faltante* y resta la jornada
    completa del banco. Esto rige desde el inicio del control, que es la
    primera fichada con la app; los días anteriores no restan.
  - Un usufructo parcial en un día sin fichada queda para revisar, y un
    usufructo en fin de semana o feriado descuenta igual.
  - Para ver si alcanza el saldo de un usufructo se cuentan también los
    usufructos ya cargados a futuro.
  - Lo fichado en un fin de semana o feriado entra solo al banco como a favor.
  - Los no laborables turísticos (puentes) no son días hábiles.
  - Una acumulación también puede quedar `perdida` y entonces no computa. No
    hay vencimiento automático: se marca a mano.
  - Un usufructo total es igual a la jornada vigente, y no se puede usufructuar
    más de lo que hay de saldo.
  - No hay licencias fuera del banco: lo único que cubre un día es un usufructo.
  - No hay turnos que crucen la medianoche.
  - Los créditos de los cursos son enteros.
  - Ante un conflicto de sincronización gana el último que sincroniza.
  - Backend: Supabase en la nube (proyecto `umzfjkdeuvsyswoueafu`). No se usa
    Docker local: las migraciones se aplican con `supabase db push`.
  - Pendiente: usufructos de varios días, distinguir salida temprana de llegada
    tarde, qué pasa con un usufructo parcial mayor que la deuda del día y si
    las acumulaciones vencen.
- **Agentes:** para UI, estado, navegación, cámara, offline y layout usá
  `frontend-flutter`. Para esquema, migraciones, RLS, Storage, Edge Functions
  e importación usá `backend-supabase`. Si un cambio toca los dos lados, primero
  va el contrato (tablas/tipos) del backend y después el frontend.
- La lógica de cálculo (deuda, a favor, saldos, faltantes) vive en `domain/`
  como Dart puro **con tests unitarios**. Los casos raros de la planilla
  (egreso vacío, saldo negativo, día duplicado) tienen que tener un test cada uno.
- El esquema solo cambia por migraciones. Nunca se edita a mano en el dashboard.
- Antes de decidir algo de negocio que no esté en este archivo, preguntale a Bruno.
