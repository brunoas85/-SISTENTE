import 'package:drift/drift.dart';

part 'app_database.drift.dart';

/// Estado de sincronización de una fila local.
enum SyncStatus {
  /// Cambió en el dispositivo y todavía no se subió.
  pending,

  /// Igual que en Supabase.
  synced,

  /// El servidor la rechazó o falta algo (se reintenta igual).
  error,
}

/// Origen de un tramo (columna `fichadas.origen`).
enum OrigenFichada {
  /// Fichado con el botón Fichar (hora propuesta por el dispositivo).
  dispositivo,

  /// Cargado a mano: agregado desde la vista mensual o cerrado con la hora a
  /// mano.
  manual,

  /// Traído de la planilla xlsx.
  importado;

  /// Valor en la base (el nombre).
  String get dbValue => name;

  /// Origen con ese valor, o [dispositivo] si no se conoce.
  static OrigenFichada fromDbValue(String? value) {
    for (final o in values) {
      if (o.name == value) return o;
    }
    return dispositivo;
  }
}

/// Espejo local de `public.fichadas` más las columnas de sincronización.
///
/// Las horas son minutos desde las 00:00 y la fecha es `yyyy-MM-dd`, igual
/// que en Postgres.
@DataClassName('LocalFichada')
class Fichadas extends Table {
  /// uuid generado en el cliente.
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get fecha => text()();
  IntColumn get ingresoMin => integer()();
  IntColumn get egresoMin => integer().nullable()();
  IntColumn get ingresoOriginalMin => integer().nullable()();
  IntColumn get egresoOriginalMin => integer().nullable()();
  BoolColumn get editado => boolean().withDefault(const Constant(false))();

  /// Rutas en el bucket `comprobantes` (se completan al subir la foto).
  TextColumn get fotoIngresoPath => text().nullable()();
  TextColumn get fotoEgresoPath => text().nullable()();

  /// Referencias a la foto guardada en el dispositivo (ver `PhotoStore`).
  TextColumn get fotoIngresoLocal => text().nullable()();
  TextColumn get fotoEgresoLocal => text().nullable()();

  TextColumn get observacion => text().nullable()();

  /// Cómo se cargó el tramo: `dispositivo` (Fichar), `manual` (cargado a
  /// mano) o `importado` (xlsx). Ver `OrigenFichada`.
  TextColumn get origen => text().withDefault(const Constant('dispositivo'))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// Última modificación local.
  DateTimeColumn get updatedAt => dateTime()();

  /// Se incrementa en cada cambio local. El sync solo marca `synced` si no
  /// cambió mientras subía.
  IntColumn get revision => integer().withDefault(const Constant(0))();

  TextColumn get syncStatus => textEnum<SyncStatus>()();
  TextColumn get syncError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Copia local de `public.feriados` (solo lectura).
@DataClassName('LocalFeriado')
class Feriados extends Table {
  TextColumn get fecha => text()();
  TextColumn get nombre => text()();

  /// `inamovible`, `trasladable` o `no_laborable` (ver `HolidayKind`).
  TextColumn get tipo => text().withDefault(const Constant('inamovible'))();

  @override
  Set<Column> get primaryKey => {fecha};
}

/// Cache local de `public.profiles` (solo lo que usa la app).
///
/// Si no hay fila para el usuario, todavía no se bajó el perfil. El
/// agrupamiento se elige en el dispositivo (queda `pending`) y el sync lo
/// sube; lo que baja del servidor no pisa un cambio local sin subir.
@DataClassName('LocalProfile')
class Profiles extends Table {
  TextColumn get userId => text()();

  /// Valor del enum `agrupamiento`, o `null` si no se eligió.
  TextColumn get agrupamiento => text().nullable()();

  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  TextColumn get syncStatus => textEnum<SyncStatus>()();
  TextColumn get syncError => text().nullable()();

  @override
  Set<Column> get primaryKey => {userId};
}

/// Valores sueltos del sync (por ej. el cursor de la última descarga).
class SyncState extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Fotos guardadas dentro de la base. Solo se usa en web, donde no hay
/// sistema de archivos.
class LocalPhotos extends Table {
  TextColumn get key => text()();
  BlobColumn get bytes => blob()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Espejo local de `public.tipos_documento_gde` (catálogo editable por
/// usuario: FSOLI, FOESC, …). Sin códigos hardcodeados.
@DataClassName('LocalTipoDocumento')
class TiposDocumentoGde extends Table {
  /// uuid generado en el cliente.
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get codigo => text()();
  TextColumn get descripcion => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  TextColumn get syncStatus => textEnum<SyncStatus>()();
  TextColumn get syncError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Espejo local de `public.banco_horas_movimientos` (acumulaciones y
/// usufructos cargados a mano). El a favor y la deuda diarios no se guardan:
/// se derivan de las fichadas.
@DataClassName('LocalMovimiento')
class BancoMovimientos extends Table {
  /// uuid generado en el cliente.
  TextColumn get id => text()();
  TextColumn get userId => text()();

  /// `acumulacion` | `usufructo` (enum `movimiento_tipo`).
  TextColumn get tipo => text()();

  /// `total` | `parcial` solo en usufructos; `null` en acumulaciones
  /// (CHECK `banco_alcance_solo_usufructo`).
  TextColumn get alcance => text().nullable()();

  /// `yyyy-MM-dd`.
  TextColumn get fecha => text()();
  IntColumn get minutos => integer()();

  /// `vigente` | `perdido` (enum `movimiento_estado`).
  TextColumn get estado => text().withDefault(const Constant('vigente'))();
  TextColumn get tipoDocumentoId => text().nullable()();
  TextColumn get numeroGde => text().nullable()();

  /// Ruta en el bucket `comprobantes` (se completa al subir el adjunto).
  TextColumn get adjuntoPath => text().nullable()();

  /// Referencia al adjunto guardado en el dispositivo (ver `PhotoStore`).
  /// El nombre termina en la extensión (`.jpg` o `.pdf`).
  TextColumn get adjuntoLocal => text().nullable()();
  TextColumn get observacion => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  TextColumn get syncStatus => textEnum<SyncStatus>()();
  TextColumn get syncError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Fichadas,
    Feriados,
    Profiles,
    SyncState,
    LocalPhotos,
    TiposDocumentoGde,
    BancoMovimientos,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Clave del sync con la fecha de la última descarga de feriados.
  static const holidaysPulledAtKey = 'feriados_pulled_at';

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX fichadas_user_fecha_idx ON fichadas (user_id, fecha)',
      );
      await customStatement(
        'CREATE INDEX fichadas_sync_idx ON fichadas (user_id, sync_status)',
      );
      await _createBancoIndexes();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(feriados, feriados.tipo);
        await m.createTable(profiles);
        // Los feriados guardados no tienen el tipo: se vuelven a bajar.
        await (delete(
          syncState,
        )..where((s) => s.key.equals(holidaysPulledAtKey))).go();
      }
      if (from < 3) {
        await m.createTable(tiposDocumentoGde);
        await m.createTable(bancoMovimientos);
        await _createBancoIndexes();
      }
      if (from < 4) {
        // Las filas existentes quedan como 'dispositivo' (igual que en el
        // servidor).
        await m.addColumn(fichadas, fichadas.origen);
      }
    },
  );

  Future<void> _createBancoIndexes() async {
    await customStatement(
      'CREATE INDEX banco_movimientos_user_fecha_idx '
      'ON banco_movimientos (user_id, fecha)',
    );
    await customStatement(
      'CREATE INDEX banco_movimientos_sync_idx '
      'ON banco_movimientos (user_id, sync_status)',
    );
  }
}
