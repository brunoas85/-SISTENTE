// dart format width=80
// ignore_for_file: type=lint
part of 'app_database.dart';

class $FichadasTable extends Fichadas
    with TableInfo<$FichadasTable, LocalFichada> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FichadasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<String> fecha = GeneratedColumn<String>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ingresoMinMeta = const VerificationMeta(
    'ingresoMin',
  );
  @override
  late final GeneratedColumn<int> ingresoMin = GeneratedColumn<int>(
    'ingreso_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _egresoMinMeta = const VerificationMeta(
    'egresoMin',
  );
  @override
  late final GeneratedColumn<int> egresoMin = GeneratedColumn<int>(
    'egreso_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ingresoOriginalMinMeta =
      const VerificationMeta('ingresoOriginalMin');
  @override
  late final GeneratedColumn<int> ingresoOriginalMin = GeneratedColumn<int>(
    'ingreso_original_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _egresoOriginalMinMeta = const VerificationMeta(
    'egresoOriginalMin',
  );
  @override
  late final GeneratedColumn<int> egresoOriginalMin = GeneratedColumn<int>(
    'egreso_original_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _editadoMeta = const VerificationMeta(
    'editado',
  );
  @override
  late final GeneratedColumn<bool> editado = GeneratedColumn<bool>(
    'editado',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("editado" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _fotoIngresoPathMeta = const VerificationMeta(
    'fotoIngresoPath',
  );
  @override
  late final GeneratedColumn<String> fotoIngresoPath = GeneratedColumn<String>(
    'foto_ingreso_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fotoEgresoPathMeta = const VerificationMeta(
    'fotoEgresoPath',
  );
  @override
  late final GeneratedColumn<String> fotoEgresoPath = GeneratedColumn<String>(
    'foto_egreso_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fotoIngresoLocalMeta = const VerificationMeta(
    'fotoIngresoLocal',
  );
  @override
  late final GeneratedColumn<String> fotoIngresoLocal = GeneratedColumn<String>(
    'foto_ingreso_local',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fotoEgresoLocalMeta = const VerificationMeta(
    'fotoEgresoLocal',
  );
  @override
  late final GeneratedColumn<String> fotoEgresoLocal = GeneratedColumn<String>(
    'foto_egreso_local',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _observacionMeta = const VerificationMeta(
    'observacion',
  );
  @override
  late final GeneratedColumn<String> observacion = GeneratedColumn<String>(
    'observacion',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _origenMeta = const VerificationMeta('origen');
  @override
  late final GeneratedColumn<String> origen = GeneratedColumn<String>(
    'origen',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('dispositivo'),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, String> syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SyncStatus>($FichadasTable.$convertersyncStatus);
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    fecha,
    ingresoMin,
    egresoMin,
    ingresoOriginalMin,
    egresoOriginalMin,
    editado,
    fotoIngresoPath,
    fotoEgresoPath,
    fotoIngresoLocal,
    fotoEgresoLocal,
    observacion,
    origen,
    deletedAt,
    updatedAt,
    revision,
    syncStatus,
    syncError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fichadas';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalFichada> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('ingreso_min')) {
      context.handle(
        _ingresoMinMeta,
        ingresoMin.isAcceptableOrUnknown(data['ingreso_min']!, _ingresoMinMeta),
      );
    } else if (isInserting) {
      context.missing(_ingresoMinMeta);
    }
    if (data.containsKey('egreso_min')) {
      context.handle(
        _egresoMinMeta,
        egresoMin.isAcceptableOrUnknown(data['egreso_min']!, _egresoMinMeta),
      );
    }
    if (data.containsKey('ingreso_original_min')) {
      context.handle(
        _ingresoOriginalMinMeta,
        ingresoOriginalMin.isAcceptableOrUnknown(
          data['ingreso_original_min']!,
          _ingresoOriginalMinMeta,
        ),
      );
    }
    if (data.containsKey('egreso_original_min')) {
      context.handle(
        _egresoOriginalMinMeta,
        egresoOriginalMin.isAcceptableOrUnknown(
          data['egreso_original_min']!,
          _egresoOriginalMinMeta,
        ),
      );
    }
    if (data.containsKey('editado')) {
      context.handle(
        _editadoMeta,
        editado.isAcceptableOrUnknown(data['editado']!, _editadoMeta),
      );
    }
    if (data.containsKey('foto_ingreso_path')) {
      context.handle(
        _fotoIngresoPathMeta,
        fotoIngresoPath.isAcceptableOrUnknown(
          data['foto_ingreso_path']!,
          _fotoIngresoPathMeta,
        ),
      );
    }
    if (data.containsKey('foto_egreso_path')) {
      context.handle(
        _fotoEgresoPathMeta,
        fotoEgresoPath.isAcceptableOrUnknown(
          data['foto_egreso_path']!,
          _fotoEgresoPathMeta,
        ),
      );
    }
    if (data.containsKey('foto_ingreso_local')) {
      context.handle(
        _fotoIngresoLocalMeta,
        fotoIngresoLocal.isAcceptableOrUnknown(
          data['foto_ingreso_local']!,
          _fotoIngresoLocalMeta,
        ),
      );
    }
    if (data.containsKey('foto_egreso_local')) {
      context.handle(
        _fotoEgresoLocalMeta,
        fotoEgresoLocal.isAcceptableOrUnknown(
          data['foto_egreso_local']!,
          _fotoEgresoLocalMeta,
        ),
      );
    }
    if (data.containsKey('observacion')) {
      context.handle(
        _observacionMeta,
        observacion.isAcceptableOrUnknown(
          data['observacion']!,
          _observacionMeta,
        ),
      );
    }
    if (data.containsKey('origen')) {
      context.handle(
        _origenMeta,
        origen.isAcceptableOrUnknown(data['origen']!, _origenMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalFichada map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalFichada(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fecha'],
      )!,
      ingresoMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ingreso_min'],
      )!,
      egresoMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}egreso_min'],
      ),
      ingresoOriginalMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ingreso_original_min'],
      ),
      egresoOriginalMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}egreso_original_min'],
      ),
      editado: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}editado'],
      )!,
      fotoIngresoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}foto_ingreso_path'],
      ),
      fotoEgresoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}foto_egreso_path'],
      ),
      fotoIngresoLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}foto_ingreso_local'],
      ),
      fotoEgresoLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}foto_egreso_local'],
      ),
      observacion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observacion'],
      ),
      origen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origen'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      syncStatus: $FichadasTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
    );
  }

  @override
  $FichadasTable createAlias(String alias) {
    return $FichadasTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatus, String, String> $convertersyncStatus =
      const EnumNameConverter<SyncStatus>(SyncStatus.values);
}

class LocalFichada extends DataClass implements Insertable<LocalFichada> {
  /// uuid generado en el cliente.
  final String id;
  final String userId;
  final String fecha;
  final int ingresoMin;
  final int? egresoMin;
  final int? ingresoOriginalMin;
  final int? egresoOriginalMin;
  final bool editado;

  /// Rutas en el bucket `comprobantes` (se completan al subir la foto).
  final String? fotoIngresoPath;
  final String? fotoEgresoPath;

  /// Referencias a la foto guardada en el dispositivo (ver `PhotoStore`).
  final String? fotoIngresoLocal;
  final String? fotoEgresoLocal;
  final String? observacion;

  /// Cómo se cargó el tramo: `dispositivo` (Fichar), `manual` (cargado a
  /// mano) o `importado` (xlsx). Ver `OrigenFichada`.
  final String origen;
  final DateTime? deletedAt;

  /// Última modificación local.
  final DateTime updatedAt;

  /// Se incrementa en cada cambio local. El sync solo marca `synced` si no
  /// cambió mientras subía.
  final int revision;
  final SyncStatus syncStatus;
  final String? syncError;
  const LocalFichada({
    required this.id,
    required this.userId,
    required this.fecha,
    required this.ingresoMin,
    this.egresoMin,
    this.ingresoOriginalMin,
    this.egresoOriginalMin,
    required this.editado,
    this.fotoIngresoPath,
    this.fotoEgresoPath,
    this.fotoIngresoLocal,
    this.fotoEgresoLocal,
    this.observacion,
    required this.origen,
    this.deletedAt,
    required this.updatedAt,
    required this.revision,
    required this.syncStatus,
    this.syncError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['fecha'] = Variable<String>(fecha);
    map['ingreso_min'] = Variable<int>(ingresoMin);
    if (!nullToAbsent || egresoMin != null) {
      map['egreso_min'] = Variable<int>(egresoMin);
    }
    if (!nullToAbsent || ingresoOriginalMin != null) {
      map['ingreso_original_min'] = Variable<int>(ingresoOriginalMin);
    }
    if (!nullToAbsent || egresoOriginalMin != null) {
      map['egreso_original_min'] = Variable<int>(egresoOriginalMin);
    }
    map['editado'] = Variable<bool>(editado);
    if (!nullToAbsent || fotoIngresoPath != null) {
      map['foto_ingreso_path'] = Variable<String>(fotoIngresoPath);
    }
    if (!nullToAbsent || fotoEgresoPath != null) {
      map['foto_egreso_path'] = Variable<String>(fotoEgresoPath);
    }
    if (!nullToAbsent || fotoIngresoLocal != null) {
      map['foto_ingreso_local'] = Variable<String>(fotoIngresoLocal);
    }
    if (!nullToAbsent || fotoEgresoLocal != null) {
      map['foto_egreso_local'] = Variable<String>(fotoEgresoLocal);
    }
    if (!nullToAbsent || observacion != null) {
      map['observacion'] = Variable<String>(observacion);
    }
    map['origen'] = Variable<String>(origen);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['revision'] = Variable<int>(revision);
    {
      map['sync_status'] = Variable<String>(
        $FichadasTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    return map;
  }

  FichadasCompanion toCompanion(bool nullToAbsent) {
    return FichadasCompanion(
      id: Value(id),
      userId: Value(userId),
      fecha: Value(fecha),
      ingresoMin: Value(ingresoMin),
      egresoMin: egresoMin == null && nullToAbsent
          ? const Value.absent()
          : Value(egresoMin),
      ingresoOriginalMin: ingresoOriginalMin == null && nullToAbsent
          ? const Value.absent()
          : Value(ingresoOriginalMin),
      egresoOriginalMin: egresoOriginalMin == null && nullToAbsent
          ? const Value.absent()
          : Value(egresoOriginalMin),
      editado: Value(editado),
      fotoIngresoPath: fotoIngresoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(fotoIngresoPath),
      fotoEgresoPath: fotoEgresoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(fotoEgresoPath),
      fotoIngresoLocal: fotoIngresoLocal == null && nullToAbsent
          ? const Value.absent()
          : Value(fotoIngresoLocal),
      fotoEgresoLocal: fotoEgresoLocal == null && nullToAbsent
          ? const Value.absent()
          : Value(fotoEgresoLocal),
      observacion: observacion == null && nullToAbsent
          ? const Value.absent()
          : Value(observacion),
      origen: Value(origen),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      updatedAt: Value(updatedAt),
      revision: Value(revision),
      syncStatus: Value(syncStatus),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
    );
  }

  factory LocalFichada.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalFichada(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      fecha: serializer.fromJson<String>(json['fecha']),
      ingresoMin: serializer.fromJson<int>(json['ingresoMin']),
      egresoMin: serializer.fromJson<int?>(json['egresoMin']),
      ingresoOriginalMin: serializer.fromJson<int?>(json['ingresoOriginalMin']),
      egresoOriginalMin: serializer.fromJson<int?>(json['egresoOriginalMin']),
      editado: serializer.fromJson<bool>(json['editado']),
      fotoIngresoPath: serializer.fromJson<String?>(json['fotoIngresoPath']),
      fotoEgresoPath: serializer.fromJson<String?>(json['fotoEgresoPath']),
      fotoIngresoLocal: serializer.fromJson<String?>(json['fotoIngresoLocal']),
      fotoEgresoLocal: serializer.fromJson<String?>(json['fotoEgresoLocal']),
      observacion: serializer.fromJson<String?>(json['observacion']),
      origen: serializer.fromJson<String>(json['origen']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      revision: serializer.fromJson<int>(json['revision']),
      syncStatus: $FichadasTable.$convertersyncStatus.fromJson(
        serializer.fromJson<String>(json['syncStatus']),
      ),
      syncError: serializer.fromJson<String?>(json['syncError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'fecha': serializer.toJson<String>(fecha),
      'ingresoMin': serializer.toJson<int>(ingresoMin),
      'egresoMin': serializer.toJson<int?>(egresoMin),
      'ingresoOriginalMin': serializer.toJson<int?>(ingresoOriginalMin),
      'egresoOriginalMin': serializer.toJson<int?>(egresoOriginalMin),
      'editado': serializer.toJson<bool>(editado),
      'fotoIngresoPath': serializer.toJson<String?>(fotoIngresoPath),
      'fotoEgresoPath': serializer.toJson<String?>(fotoEgresoPath),
      'fotoIngresoLocal': serializer.toJson<String?>(fotoIngresoLocal),
      'fotoEgresoLocal': serializer.toJson<String?>(fotoEgresoLocal),
      'observacion': serializer.toJson<String?>(observacion),
      'origen': serializer.toJson<String>(origen),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'revision': serializer.toJson<int>(revision),
      'syncStatus': serializer.toJson<String>(
        $FichadasTable.$convertersyncStatus.toJson(syncStatus),
      ),
      'syncError': serializer.toJson<String?>(syncError),
    };
  }

  LocalFichada copyWith({
    String? id,
    String? userId,
    String? fecha,
    int? ingresoMin,
    Value<int?> egresoMin = const Value.absent(),
    Value<int?> ingresoOriginalMin = const Value.absent(),
    Value<int?> egresoOriginalMin = const Value.absent(),
    bool? editado,
    Value<String?> fotoIngresoPath = const Value.absent(),
    Value<String?> fotoEgresoPath = const Value.absent(),
    Value<String?> fotoIngresoLocal = const Value.absent(),
    Value<String?> fotoEgresoLocal = const Value.absent(),
    Value<String?> observacion = const Value.absent(),
    String? origen,
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? updatedAt,
    int? revision,
    SyncStatus? syncStatus,
    Value<String?> syncError = const Value.absent(),
  }) => LocalFichada(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    fecha: fecha ?? this.fecha,
    ingresoMin: ingresoMin ?? this.ingresoMin,
    egresoMin: egresoMin.present ? egresoMin.value : this.egresoMin,
    ingresoOriginalMin: ingresoOriginalMin.present
        ? ingresoOriginalMin.value
        : this.ingresoOriginalMin,
    egresoOriginalMin: egresoOriginalMin.present
        ? egresoOriginalMin.value
        : this.egresoOriginalMin,
    editado: editado ?? this.editado,
    fotoIngresoPath: fotoIngresoPath.present
        ? fotoIngresoPath.value
        : this.fotoIngresoPath,
    fotoEgresoPath: fotoEgresoPath.present
        ? fotoEgresoPath.value
        : this.fotoEgresoPath,
    fotoIngresoLocal: fotoIngresoLocal.present
        ? fotoIngresoLocal.value
        : this.fotoIngresoLocal,
    fotoEgresoLocal: fotoEgresoLocal.present
        ? fotoEgresoLocal.value
        : this.fotoEgresoLocal,
    observacion: observacion.present ? observacion.value : this.observacion,
    origen: origen ?? this.origen,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    revision: revision ?? this.revision,
    syncStatus: syncStatus ?? this.syncStatus,
    syncError: syncError.present ? syncError.value : this.syncError,
  );
  LocalFichada copyWithCompanion(FichadasCompanion data) {
    return LocalFichada(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      ingresoMin: data.ingresoMin.present
          ? data.ingresoMin.value
          : this.ingresoMin,
      egresoMin: data.egresoMin.present ? data.egresoMin.value : this.egresoMin,
      ingresoOriginalMin: data.ingresoOriginalMin.present
          ? data.ingresoOriginalMin.value
          : this.ingresoOriginalMin,
      egresoOriginalMin: data.egresoOriginalMin.present
          ? data.egresoOriginalMin.value
          : this.egresoOriginalMin,
      editado: data.editado.present ? data.editado.value : this.editado,
      fotoIngresoPath: data.fotoIngresoPath.present
          ? data.fotoIngresoPath.value
          : this.fotoIngresoPath,
      fotoEgresoPath: data.fotoEgresoPath.present
          ? data.fotoEgresoPath.value
          : this.fotoEgresoPath,
      fotoIngresoLocal: data.fotoIngresoLocal.present
          ? data.fotoIngresoLocal.value
          : this.fotoIngresoLocal,
      fotoEgresoLocal: data.fotoEgresoLocal.present
          ? data.fotoEgresoLocal.value
          : this.fotoEgresoLocal,
      observacion: data.observacion.present
          ? data.observacion.value
          : this.observacion,
      origen: data.origen.present ? data.origen.value : this.origen,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      revision: data.revision.present ? data.revision.value : this.revision,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalFichada(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('fecha: $fecha, ')
          ..write('ingresoMin: $ingresoMin, ')
          ..write('egresoMin: $egresoMin, ')
          ..write('ingresoOriginalMin: $ingresoOriginalMin, ')
          ..write('egresoOriginalMin: $egresoOriginalMin, ')
          ..write('editado: $editado, ')
          ..write('fotoIngresoPath: $fotoIngresoPath, ')
          ..write('fotoEgresoPath: $fotoEgresoPath, ')
          ..write('fotoIngresoLocal: $fotoIngresoLocal, ')
          ..write('fotoEgresoLocal: $fotoEgresoLocal, ')
          ..write('observacion: $observacion, ')
          ..write('origen: $origen, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    fecha,
    ingresoMin,
    egresoMin,
    ingresoOriginalMin,
    egresoOriginalMin,
    editado,
    fotoIngresoPath,
    fotoEgresoPath,
    fotoIngresoLocal,
    fotoEgresoLocal,
    observacion,
    origen,
    deletedAt,
    updatedAt,
    revision,
    syncStatus,
    syncError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalFichada &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.fecha == this.fecha &&
          other.ingresoMin == this.ingresoMin &&
          other.egresoMin == this.egresoMin &&
          other.ingresoOriginalMin == this.ingresoOriginalMin &&
          other.egresoOriginalMin == this.egresoOriginalMin &&
          other.editado == this.editado &&
          other.fotoIngresoPath == this.fotoIngresoPath &&
          other.fotoEgresoPath == this.fotoEgresoPath &&
          other.fotoIngresoLocal == this.fotoIngresoLocal &&
          other.fotoEgresoLocal == this.fotoEgresoLocal &&
          other.observacion == this.observacion &&
          other.origen == this.origen &&
          other.deletedAt == this.deletedAt &&
          other.updatedAt == this.updatedAt &&
          other.revision == this.revision &&
          other.syncStatus == this.syncStatus &&
          other.syncError == this.syncError);
}

class FichadasCompanion extends UpdateCompanion<LocalFichada> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> fecha;
  final Value<int> ingresoMin;
  final Value<int?> egresoMin;
  final Value<int?> ingresoOriginalMin;
  final Value<int?> egresoOriginalMin;
  final Value<bool> editado;
  final Value<String?> fotoIngresoPath;
  final Value<String?> fotoEgresoPath;
  final Value<String?> fotoIngresoLocal;
  final Value<String?> fotoEgresoLocal;
  final Value<String?> observacion;
  final Value<String> origen;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> updatedAt;
  final Value<int> revision;
  final Value<SyncStatus> syncStatus;
  final Value<String?> syncError;
  final Value<int> rowid;
  const FichadasCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.fecha = const Value.absent(),
    this.ingresoMin = const Value.absent(),
    this.egresoMin = const Value.absent(),
    this.ingresoOriginalMin = const Value.absent(),
    this.egresoOriginalMin = const Value.absent(),
    this.editado = const Value.absent(),
    this.fotoIngresoPath = const Value.absent(),
    this.fotoEgresoPath = const Value.absent(),
    this.fotoIngresoLocal = const Value.absent(),
    this.fotoEgresoLocal = const Value.absent(),
    this.observacion = const Value.absent(),
    this.origen = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FichadasCompanion.insert({
    required String id,
    required String userId,
    required String fecha,
    required int ingresoMin,
    this.egresoMin = const Value.absent(),
    this.ingresoOriginalMin = const Value.absent(),
    this.egresoOriginalMin = const Value.absent(),
    this.editado = const Value.absent(),
    this.fotoIngresoPath = const Value.absent(),
    this.fotoEgresoPath = const Value.absent(),
    this.fotoIngresoLocal = const Value.absent(),
    this.fotoEgresoLocal = const Value.absent(),
    this.observacion = const Value.absent(),
    this.origen = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required DateTime updatedAt,
    this.revision = const Value.absent(),
    required SyncStatus syncStatus,
    this.syncError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       fecha = Value(fecha),
       ingresoMin = Value(ingresoMin),
       updatedAt = Value(updatedAt),
       syncStatus = Value(syncStatus);
  static Insertable<LocalFichada> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? fecha,
    Expression<int>? ingresoMin,
    Expression<int>? egresoMin,
    Expression<int>? ingresoOriginalMin,
    Expression<int>? egresoOriginalMin,
    Expression<bool>? editado,
    Expression<String>? fotoIngresoPath,
    Expression<String>? fotoEgresoPath,
    Expression<String>? fotoIngresoLocal,
    Expression<String>? fotoEgresoLocal,
    Expression<String>? observacion,
    Expression<String>? origen,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? revision,
    Expression<String>? syncStatus,
    Expression<String>? syncError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (fecha != null) 'fecha': fecha,
      if (ingresoMin != null) 'ingreso_min': ingresoMin,
      if (egresoMin != null) 'egreso_min': egresoMin,
      if (ingresoOriginalMin != null)
        'ingreso_original_min': ingresoOriginalMin,
      if (egresoOriginalMin != null) 'egreso_original_min': egresoOriginalMin,
      if (editado != null) 'editado': editado,
      if (fotoIngresoPath != null) 'foto_ingreso_path': fotoIngresoPath,
      if (fotoEgresoPath != null) 'foto_egreso_path': fotoEgresoPath,
      if (fotoIngresoLocal != null) 'foto_ingreso_local': fotoIngresoLocal,
      if (fotoEgresoLocal != null) 'foto_egreso_local': fotoEgresoLocal,
      if (observacion != null) 'observacion': observacion,
      if (origen != null) 'origen': origen,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (revision != null) 'revision': revision,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncError != null) 'sync_error': syncError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FichadasCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? fecha,
    Value<int>? ingresoMin,
    Value<int?>? egresoMin,
    Value<int?>? ingresoOriginalMin,
    Value<int?>? egresoOriginalMin,
    Value<bool>? editado,
    Value<String?>? fotoIngresoPath,
    Value<String?>? fotoEgresoPath,
    Value<String?>? fotoIngresoLocal,
    Value<String?>? fotoEgresoLocal,
    Value<String?>? observacion,
    Value<String>? origen,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? updatedAt,
    Value<int>? revision,
    Value<SyncStatus>? syncStatus,
    Value<String?>? syncError,
    Value<int>? rowid,
  }) {
    return FichadasCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fecha: fecha ?? this.fecha,
      ingresoMin: ingresoMin ?? this.ingresoMin,
      egresoMin: egresoMin ?? this.egresoMin,
      ingresoOriginalMin: ingresoOriginalMin ?? this.ingresoOriginalMin,
      egresoOriginalMin: egresoOriginalMin ?? this.egresoOriginalMin,
      editado: editado ?? this.editado,
      fotoIngresoPath: fotoIngresoPath ?? this.fotoIngresoPath,
      fotoEgresoPath: fotoEgresoPath ?? this.fotoEgresoPath,
      fotoIngresoLocal: fotoIngresoLocal ?? this.fotoIngresoLocal,
      fotoEgresoLocal: fotoEgresoLocal ?? this.fotoEgresoLocal,
      observacion: observacion ?? this.observacion,
      origen: origen ?? this.origen,
      deletedAt: deletedAt ?? this.deletedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      revision: revision ?? this.revision,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError ?? this.syncError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<String>(fecha.value);
    }
    if (ingresoMin.present) {
      map['ingreso_min'] = Variable<int>(ingresoMin.value);
    }
    if (egresoMin.present) {
      map['egreso_min'] = Variable<int>(egresoMin.value);
    }
    if (ingresoOriginalMin.present) {
      map['ingreso_original_min'] = Variable<int>(ingresoOriginalMin.value);
    }
    if (egresoOriginalMin.present) {
      map['egreso_original_min'] = Variable<int>(egresoOriginalMin.value);
    }
    if (editado.present) {
      map['editado'] = Variable<bool>(editado.value);
    }
    if (fotoIngresoPath.present) {
      map['foto_ingreso_path'] = Variable<String>(fotoIngresoPath.value);
    }
    if (fotoEgresoPath.present) {
      map['foto_egreso_path'] = Variable<String>(fotoEgresoPath.value);
    }
    if (fotoIngresoLocal.present) {
      map['foto_ingreso_local'] = Variable<String>(fotoIngresoLocal.value);
    }
    if (fotoEgresoLocal.present) {
      map['foto_egreso_local'] = Variable<String>(fotoEgresoLocal.value);
    }
    if (observacion.present) {
      map['observacion'] = Variable<String>(observacion.value);
    }
    if (origen.present) {
      map['origen'] = Variable<String>(origen.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $FichadasTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FichadasCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('fecha: $fecha, ')
          ..write('ingresoMin: $ingresoMin, ')
          ..write('egresoMin: $egresoMin, ')
          ..write('ingresoOriginalMin: $ingresoOriginalMin, ')
          ..write('egresoOriginalMin: $egresoOriginalMin, ')
          ..write('editado: $editado, ')
          ..write('fotoIngresoPath: $fotoIngresoPath, ')
          ..write('fotoEgresoPath: $fotoEgresoPath, ')
          ..write('fotoIngresoLocal: $fotoIngresoLocal, ')
          ..write('fotoEgresoLocal: $fotoEgresoLocal, ')
          ..write('observacion: $observacion, ')
          ..write('origen: $origen, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FeriadosTable extends Feriados
    with TableInfo<$FeriadosTable, LocalFeriado> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FeriadosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<String> fecha = GeneratedColumn<String>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('inamovible'),
  );
  @override
  List<GeneratedColumn> get $columns => [fecha, nombre, tipo];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'feriados';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalFeriado> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fecha};
  @override
  LocalFeriado map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalFeriado(
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fecha'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
    );
  }

  @override
  $FeriadosTable createAlias(String alias) {
    return $FeriadosTable(attachedDatabase, alias);
  }
}

class LocalFeriado extends DataClass implements Insertable<LocalFeriado> {
  final String fecha;
  final String nombre;

  /// `inamovible`, `trasladable` o `no_laborable` (ver `HolidayKind`).
  final String tipo;
  const LocalFeriado({
    required this.fecha,
    required this.nombre,
    required this.tipo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['fecha'] = Variable<String>(fecha);
    map['nombre'] = Variable<String>(nombre);
    map['tipo'] = Variable<String>(tipo);
    return map;
  }

  FeriadosCompanion toCompanion(bool nullToAbsent) {
    return FeriadosCompanion(
      fecha: Value(fecha),
      nombre: Value(nombre),
      tipo: Value(tipo),
    );
  }

  factory LocalFeriado.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalFeriado(
      fecha: serializer.fromJson<String>(json['fecha']),
      nombre: serializer.fromJson<String>(json['nombre']),
      tipo: serializer.fromJson<String>(json['tipo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fecha': serializer.toJson<String>(fecha),
      'nombre': serializer.toJson<String>(nombre),
      'tipo': serializer.toJson<String>(tipo),
    };
  }

  LocalFeriado copyWith({String? fecha, String? nombre, String? tipo}) =>
      LocalFeriado(
        fecha: fecha ?? this.fecha,
        nombre: nombre ?? this.nombre,
        tipo: tipo ?? this.tipo,
      );
  LocalFeriado copyWithCompanion(FeriadosCompanion data) {
    return LocalFeriado(
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalFeriado(')
          ..write('fecha: $fecha, ')
          ..write('nombre: $nombre, ')
          ..write('tipo: $tipo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(fecha, nombre, tipo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalFeriado &&
          other.fecha == this.fecha &&
          other.nombre == this.nombre &&
          other.tipo == this.tipo);
}

class FeriadosCompanion extends UpdateCompanion<LocalFeriado> {
  final Value<String> fecha;
  final Value<String> nombre;
  final Value<String> tipo;
  final Value<int> rowid;
  const FeriadosCompanion({
    this.fecha = const Value.absent(),
    this.nombre = const Value.absent(),
    this.tipo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FeriadosCompanion.insert({
    required String fecha,
    required String nombre,
    this.tipo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : fecha = Value(fecha),
       nombre = Value(nombre);
  static Insertable<LocalFeriado> custom({
    Expression<String>? fecha,
    Expression<String>? nombre,
    Expression<String>? tipo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fecha != null) 'fecha': fecha,
      if (nombre != null) 'nombre': nombre,
      if (tipo != null) 'tipo': tipo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FeriadosCompanion copyWith({
    Value<String>? fecha,
    Value<String>? nombre,
    Value<String>? tipo,
    Value<int>? rowid,
  }) {
    return FeriadosCompanion(
      fecha: fecha ?? this.fecha,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fecha.present) {
      map['fecha'] = Variable<String>(fecha.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FeriadosCompanion(')
          ..write('fecha: $fecha, ')
          ..write('nombre: $nombre, ')
          ..write('tipo: $tipo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProfilesTable extends Profiles
    with TableInfo<$ProfilesTable, LocalProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _agrupamientoMeta = const VerificationMeta(
    'agrupamiento',
  );
  @override
  late final GeneratedColumn<String> agrupamiento = GeneratedColumn<String>(
    'agrupamiento',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, String> syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SyncStatus>($ProfilesTable.$convertersyncStatus);
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    agrupamiento,
    updatedAt,
    revision,
    syncStatus,
    syncError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('agrupamiento')) {
      context.handle(
        _agrupamientoMeta,
        agrupamiento.isAcceptableOrUnknown(
          data['agrupamiento']!,
          _agrupamientoMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  LocalProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalProfile(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      agrupamiento: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agrupamiento'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      syncStatus: $ProfilesTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatus, String, String> $convertersyncStatus =
      const EnumNameConverter<SyncStatus>(SyncStatus.values);
}

class LocalProfile extends DataClass implements Insertable<LocalProfile> {
  final String userId;

  /// Valor del enum `agrupamiento`, o `null` si no se eligió.
  final String? agrupamiento;
  final DateTime updatedAt;
  final int revision;
  final SyncStatus syncStatus;
  final String? syncError;
  const LocalProfile({
    required this.userId,
    this.agrupamiento,
    required this.updatedAt,
    required this.revision,
    required this.syncStatus,
    this.syncError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || agrupamiento != null) {
      map['agrupamiento'] = Variable<String>(agrupamiento);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['revision'] = Variable<int>(revision);
    {
      map['sync_status'] = Variable<String>(
        $ProfilesTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      userId: Value(userId),
      agrupamiento: agrupamiento == null && nullToAbsent
          ? const Value.absent()
          : Value(agrupamiento),
      updatedAt: Value(updatedAt),
      revision: Value(revision),
      syncStatus: Value(syncStatus),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
    );
  }

  factory LocalProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalProfile(
      userId: serializer.fromJson<String>(json['userId']),
      agrupamiento: serializer.fromJson<String?>(json['agrupamiento']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      revision: serializer.fromJson<int>(json['revision']),
      syncStatus: $ProfilesTable.$convertersyncStatus.fromJson(
        serializer.fromJson<String>(json['syncStatus']),
      ),
      syncError: serializer.fromJson<String?>(json['syncError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'agrupamiento': serializer.toJson<String?>(agrupamiento),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'revision': serializer.toJson<int>(revision),
      'syncStatus': serializer.toJson<String>(
        $ProfilesTable.$convertersyncStatus.toJson(syncStatus),
      ),
      'syncError': serializer.toJson<String?>(syncError),
    };
  }

  LocalProfile copyWith({
    String? userId,
    Value<String?> agrupamiento = const Value.absent(),
    DateTime? updatedAt,
    int? revision,
    SyncStatus? syncStatus,
    Value<String?> syncError = const Value.absent(),
  }) => LocalProfile(
    userId: userId ?? this.userId,
    agrupamiento: agrupamiento.present ? agrupamiento.value : this.agrupamiento,
    updatedAt: updatedAt ?? this.updatedAt,
    revision: revision ?? this.revision,
    syncStatus: syncStatus ?? this.syncStatus,
    syncError: syncError.present ? syncError.value : this.syncError,
  );
  LocalProfile copyWithCompanion(ProfilesCompanion data) {
    return LocalProfile(
      userId: data.userId.present ? data.userId.value : this.userId,
      agrupamiento: data.agrupamiento.present
          ? data.agrupamiento.value
          : this.agrupamiento,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      revision: data.revision.present ? data.revision.value : this.revision,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalProfile(')
          ..write('userId: $userId, ')
          ..write('agrupamiento: $agrupamiento, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    agrupamiento,
    updatedAt,
    revision,
    syncStatus,
    syncError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalProfile &&
          other.userId == this.userId &&
          other.agrupamiento == this.agrupamiento &&
          other.updatedAt == this.updatedAt &&
          other.revision == this.revision &&
          other.syncStatus == this.syncStatus &&
          other.syncError == this.syncError);
}

class ProfilesCompanion extends UpdateCompanion<LocalProfile> {
  final Value<String> userId;
  final Value<String?> agrupamiento;
  final Value<DateTime> updatedAt;
  final Value<int> revision;
  final Value<SyncStatus> syncStatus;
  final Value<String?> syncError;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.userId = const Value.absent(),
    this.agrupamiento = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required String userId,
    this.agrupamiento = const Value.absent(),
    required DateTime updatedAt,
    this.revision = const Value.absent(),
    required SyncStatus syncStatus,
    this.syncError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       updatedAt = Value(updatedAt),
       syncStatus = Value(syncStatus);
  static Insertable<LocalProfile> custom({
    Expression<String>? userId,
    Expression<String>? agrupamiento,
    Expression<DateTime>? updatedAt,
    Expression<int>? revision,
    Expression<String>? syncStatus,
    Expression<String>? syncError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (agrupamiento != null) 'agrupamiento': agrupamiento,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (revision != null) 'revision': revision,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncError != null) 'sync_error': syncError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith({
    Value<String>? userId,
    Value<String?>? agrupamiento,
    Value<DateTime>? updatedAt,
    Value<int>? revision,
    Value<SyncStatus>? syncStatus,
    Value<String?>? syncError,
    Value<int>? rowid,
  }) {
    return ProfilesCompanion(
      userId: userId ?? this.userId,
      agrupamiento: agrupamiento ?? this.agrupamiento,
      updatedAt: updatedAt ?? this.updatedAt,
      revision: revision ?? this.revision,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError ?? this.syncError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (agrupamiento.present) {
      map['agrupamiento'] = Variable<String>(agrupamiento.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $ProfilesTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('userId: $userId, ')
          ..write('agrupamiento: $agrupamiento, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateData extends DataClass implements Insertable<SyncStateData> {
  final String key;
  final String value;
  const SyncStateData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(key: Value(key), value: Value(value));
  }

  factory SyncStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SyncStateData copyWith({String? key, String? value}) =>
      SyncStateData(key: key ?? this.key, value: value ?? this.value);
  SyncStateData copyWithCompanion(SyncStateCompanion data) {
    return SyncStateData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateData &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SyncStateData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncStateCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPhotosTable extends LocalPhotos
    with TableInfo<$LocalPhotosTable, LocalPhoto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<Uint8List> bytes = GeneratedColumn<Uint8List>(
    'bytes',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, bytes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalPhoto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    } else if (isInserting) {
      context.missing(_bytesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  LocalPhoto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPhoto(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}bytes'],
      )!,
    );
  }

  @override
  $LocalPhotosTable createAlias(String alias) {
    return $LocalPhotosTable(attachedDatabase, alias);
  }
}

class LocalPhoto extends DataClass implements Insertable<LocalPhoto> {
  final String key;
  final Uint8List bytes;
  const LocalPhoto({required this.key, required this.bytes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['bytes'] = Variable<Uint8List>(bytes);
    return map;
  }

  LocalPhotosCompanion toCompanion(bool nullToAbsent) {
    return LocalPhotosCompanion(key: Value(key), bytes: Value(bytes));
  }

  factory LocalPhoto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPhoto(
      key: serializer.fromJson<String>(json['key']),
      bytes: serializer.fromJson<Uint8List>(json['bytes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'bytes': serializer.toJson<Uint8List>(bytes),
    };
  }

  LocalPhoto copyWith({String? key, Uint8List? bytes}) =>
      LocalPhoto(key: key ?? this.key, bytes: bytes ?? this.bytes);
  LocalPhoto copyWithCompanion(LocalPhotosCompanion data) {
    return LocalPhoto(
      key: data.key.present ? data.key.value : this.key,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPhoto(')
          ..write('key: $key, ')
          ..write('bytes: $bytes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, $driftBlobEquality.hash(bytes));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPhoto &&
          other.key == this.key &&
          $driftBlobEquality.equals(other.bytes, this.bytes));
}

class LocalPhotosCompanion extends UpdateCompanion<LocalPhoto> {
  final Value<String> key;
  final Value<Uint8List> bytes;
  final Value<int> rowid;
  const LocalPhotosCompanion({
    this.key = const Value.absent(),
    this.bytes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPhotosCompanion.insert({
    required String key,
    required Uint8List bytes,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       bytes = Value(bytes);
  static Insertable<LocalPhoto> custom({
    Expression<String>? key,
    Expression<Uint8List>? bytes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (bytes != null) 'bytes': bytes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPhotosCompanion copyWith({
    Value<String>? key,
    Value<Uint8List>? bytes,
    Value<int>? rowid,
  }) {
    return LocalPhotosCompanion(
      key: key ?? this.key,
      bytes: bytes ?? this.bytes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<Uint8List>(bytes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPhotosCompanion(')
          ..write('key: $key, ')
          ..write('bytes: $bytes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TiposDocumentoGdeTable extends TiposDocumentoGde
    with TableInfo<$TiposDocumentoGdeTable, LocalTipoDocumento> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TiposDocumentoGdeTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codigoMeta = const VerificationMeta('codigo');
  @override
  late final GeneratedColumn<String> codigo = GeneratedColumn<String>(
    'codigo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descripcionMeta = const VerificationMeta(
    'descripcion',
  );
  @override
  late final GeneratedColumn<String> descripcion = GeneratedColumn<String>(
    'descripcion',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, String> syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SyncStatus>($TiposDocumentoGdeTable.$convertersyncStatus);
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    codigo,
    descripcion,
    deletedAt,
    updatedAt,
    revision,
    syncStatus,
    syncError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tipos_documento_gde';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalTipoDocumento> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('codigo')) {
      context.handle(
        _codigoMeta,
        codigo.isAcceptableOrUnknown(data['codigo']!, _codigoMeta),
      );
    } else if (isInserting) {
      context.missing(_codigoMeta);
    }
    if (data.containsKey('descripcion')) {
      context.handle(
        _descripcionMeta,
        descripcion.isAcceptableOrUnknown(
          data['descripcion']!,
          _descripcionMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalTipoDocumento map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTipoDocumento(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      codigo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo'],
      )!,
      descripcion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descripcion'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      syncStatus: $TiposDocumentoGdeTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
    );
  }

  @override
  $TiposDocumentoGdeTable createAlias(String alias) {
    return $TiposDocumentoGdeTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatus, String, String> $convertersyncStatus =
      const EnumNameConverter<SyncStatus>(SyncStatus.values);
}

class LocalTipoDocumento extends DataClass
    implements Insertable<LocalTipoDocumento> {
  /// uuid generado en el cliente.
  final String id;
  final String userId;
  final String codigo;
  final String? descripcion;
  final DateTime? deletedAt;
  final DateTime updatedAt;
  final int revision;
  final SyncStatus syncStatus;
  final String? syncError;
  const LocalTipoDocumento({
    required this.id,
    required this.userId,
    required this.codigo,
    this.descripcion,
    this.deletedAt,
    required this.updatedAt,
    required this.revision,
    required this.syncStatus,
    this.syncError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['codigo'] = Variable<String>(codigo);
    if (!nullToAbsent || descripcion != null) {
      map['descripcion'] = Variable<String>(descripcion);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['revision'] = Variable<int>(revision);
    {
      map['sync_status'] = Variable<String>(
        $TiposDocumentoGdeTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    return map;
  }

  TiposDocumentoGdeCompanion toCompanion(bool nullToAbsent) {
    return TiposDocumentoGdeCompanion(
      id: Value(id),
      userId: Value(userId),
      codigo: Value(codigo),
      descripcion: descripcion == null && nullToAbsent
          ? const Value.absent()
          : Value(descripcion),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      updatedAt: Value(updatedAt),
      revision: Value(revision),
      syncStatus: Value(syncStatus),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
    );
  }

  factory LocalTipoDocumento.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTipoDocumento(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      codigo: serializer.fromJson<String>(json['codigo']),
      descripcion: serializer.fromJson<String?>(json['descripcion']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      revision: serializer.fromJson<int>(json['revision']),
      syncStatus: $TiposDocumentoGdeTable.$convertersyncStatus.fromJson(
        serializer.fromJson<String>(json['syncStatus']),
      ),
      syncError: serializer.fromJson<String?>(json['syncError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'codigo': serializer.toJson<String>(codigo),
      'descripcion': serializer.toJson<String?>(descripcion),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'revision': serializer.toJson<int>(revision),
      'syncStatus': serializer.toJson<String>(
        $TiposDocumentoGdeTable.$convertersyncStatus.toJson(syncStatus),
      ),
      'syncError': serializer.toJson<String?>(syncError),
    };
  }

  LocalTipoDocumento copyWith({
    String? id,
    String? userId,
    String? codigo,
    Value<String?> descripcion = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? updatedAt,
    int? revision,
    SyncStatus? syncStatus,
    Value<String?> syncError = const Value.absent(),
  }) => LocalTipoDocumento(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    codigo: codigo ?? this.codigo,
    descripcion: descripcion.present ? descripcion.value : this.descripcion,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    revision: revision ?? this.revision,
    syncStatus: syncStatus ?? this.syncStatus,
    syncError: syncError.present ? syncError.value : this.syncError,
  );
  LocalTipoDocumento copyWithCompanion(TiposDocumentoGdeCompanion data) {
    return LocalTipoDocumento(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      codigo: data.codigo.present ? data.codigo.value : this.codigo,
      descripcion: data.descripcion.present
          ? data.descripcion.value
          : this.descripcion,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      revision: data.revision.present ? data.revision.value : this.revision,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTipoDocumento(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('codigo: $codigo, ')
          ..write('descripcion: $descripcion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    codigo,
    descripcion,
    deletedAt,
    updatedAt,
    revision,
    syncStatus,
    syncError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTipoDocumento &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.codigo == this.codigo &&
          other.descripcion == this.descripcion &&
          other.deletedAt == this.deletedAt &&
          other.updatedAt == this.updatedAt &&
          other.revision == this.revision &&
          other.syncStatus == this.syncStatus &&
          other.syncError == this.syncError);
}

class TiposDocumentoGdeCompanion extends UpdateCompanion<LocalTipoDocumento> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> codigo;
  final Value<String?> descripcion;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> updatedAt;
  final Value<int> revision;
  final Value<SyncStatus> syncStatus;
  final Value<String?> syncError;
  final Value<int> rowid;
  const TiposDocumentoGdeCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.codigo = const Value.absent(),
    this.descripcion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TiposDocumentoGdeCompanion.insert({
    required String id,
    required String userId,
    required String codigo,
    this.descripcion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required DateTime updatedAt,
    this.revision = const Value.absent(),
    required SyncStatus syncStatus,
    this.syncError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       codigo = Value(codigo),
       updatedAt = Value(updatedAt),
       syncStatus = Value(syncStatus);
  static Insertable<LocalTipoDocumento> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? codigo,
    Expression<String>? descripcion,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? revision,
    Expression<String>? syncStatus,
    Expression<String>? syncError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (codigo != null) 'codigo': codigo,
      if (descripcion != null) 'descripcion': descripcion,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (revision != null) 'revision': revision,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncError != null) 'sync_error': syncError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TiposDocumentoGdeCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? codigo,
    Value<String?>? descripcion,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? updatedAt,
    Value<int>? revision,
    Value<SyncStatus>? syncStatus,
    Value<String?>? syncError,
    Value<int>? rowid,
  }) {
    return TiposDocumentoGdeCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      codigo: codigo ?? this.codigo,
      descripcion: descripcion ?? this.descripcion,
      deletedAt: deletedAt ?? this.deletedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      revision: revision ?? this.revision,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError ?? this.syncError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (codigo.present) {
      map['codigo'] = Variable<String>(codigo.value);
    }
    if (descripcion.present) {
      map['descripcion'] = Variable<String>(descripcion.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $TiposDocumentoGdeTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TiposDocumentoGdeCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('codigo: $codigo, ')
          ..write('descripcion: $descripcion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BancoMovimientosTable extends BancoMovimientos
    with TableInfo<$BancoMovimientosTable, LocalMovimiento> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BancoMovimientosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _alcanceMeta = const VerificationMeta(
    'alcance',
  );
  @override
  late final GeneratedColumn<String> alcance = GeneratedColumn<String>(
    'alcance',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<String> fecha = GeneratedColumn<String>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minutosMeta = const VerificationMeta(
    'minutos',
  );
  @override
  late final GeneratedColumn<int> minutos = GeneratedColumn<int>(
    'minutos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _estadoMeta = const VerificationMeta('estado');
  @override
  late final GeneratedColumn<String> estado = GeneratedColumn<String>(
    'estado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('vigente'),
  );
  static const VerificationMeta _tipoDocumentoIdMeta = const VerificationMeta(
    'tipoDocumentoId',
  );
  @override
  late final GeneratedColumn<String> tipoDocumentoId = GeneratedColumn<String>(
    'tipo_documento_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numeroGdeMeta = const VerificationMeta(
    'numeroGde',
  );
  @override
  late final GeneratedColumn<String> numeroGde = GeneratedColumn<String>(
    'numero_gde',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _adjuntoPathMeta = const VerificationMeta(
    'adjuntoPath',
  );
  @override
  late final GeneratedColumn<String> adjuntoPath = GeneratedColumn<String>(
    'adjunto_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _adjuntoLocalMeta = const VerificationMeta(
    'adjuntoLocal',
  );
  @override
  late final GeneratedColumn<String> adjuntoLocal = GeneratedColumn<String>(
    'adjunto_local',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _observacionMeta = const VerificationMeta(
    'observacion',
  );
  @override
  late final GeneratedColumn<String> observacion = GeneratedColumn<String>(
    'observacion',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, String> syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SyncStatus>($BancoMovimientosTable.$convertersyncStatus);
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    tipo,
    alcance,
    fecha,
    minutos,
    estado,
    tipoDocumentoId,
    numeroGde,
    adjuntoPath,
    adjuntoLocal,
    observacion,
    deletedAt,
    updatedAt,
    revision,
    syncStatus,
    syncError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'banco_movimientos';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMovimiento> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('alcance')) {
      context.handle(
        _alcanceMeta,
        alcance.isAcceptableOrUnknown(data['alcance']!, _alcanceMeta),
      );
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('minutos')) {
      context.handle(
        _minutosMeta,
        minutos.isAcceptableOrUnknown(data['minutos']!, _minutosMeta),
      );
    } else if (isInserting) {
      context.missing(_minutosMeta);
    }
    if (data.containsKey('estado')) {
      context.handle(
        _estadoMeta,
        estado.isAcceptableOrUnknown(data['estado']!, _estadoMeta),
      );
    }
    if (data.containsKey('tipo_documento_id')) {
      context.handle(
        _tipoDocumentoIdMeta,
        tipoDocumentoId.isAcceptableOrUnknown(
          data['tipo_documento_id']!,
          _tipoDocumentoIdMeta,
        ),
      );
    }
    if (data.containsKey('numero_gde')) {
      context.handle(
        _numeroGdeMeta,
        numeroGde.isAcceptableOrUnknown(data['numero_gde']!, _numeroGdeMeta),
      );
    }
    if (data.containsKey('adjunto_path')) {
      context.handle(
        _adjuntoPathMeta,
        adjuntoPath.isAcceptableOrUnknown(
          data['adjunto_path']!,
          _adjuntoPathMeta,
        ),
      );
    }
    if (data.containsKey('adjunto_local')) {
      context.handle(
        _adjuntoLocalMeta,
        adjuntoLocal.isAcceptableOrUnknown(
          data['adjunto_local']!,
          _adjuntoLocalMeta,
        ),
      );
    }
    if (data.containsKey('observacion')) {
      context.handle(
        _observacionMeta,
        observacion.isAcceptableOrUnknown(
          data['observacion']!,
          _observacionMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalMovimiento map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMovimiento(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      alcance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alcance'],
      ),
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fecha'],
      )!,
      minutos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutos'],
      )!,
      estado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado'],
      )!,
      tipoDocumentoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo_documento_id'],
      ),
      numeroGde: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}numero_gde'],
      ),
      adjuntoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}adjunto_path'],
      ),
      adjuntoLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}adjunto_local'],
      ),
      observacion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observacion'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      syncStatus: $BancoMovimientosTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
    );
  }

  @override
  $BancoMovimientosTable createAlias(String alias) {
    return $BancoMovimientosTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatus, String, String> $convertersyncStatus =
      const EnumNameConverter<SyncStatus>(SyncStatus.values);
}

class LocalMovimiento extends DataClass implements Insertable<LocalMovimiento> {
  /// uuid generado en el cliente.
  final String id;
  final String userId;

  /// `acumulacion` | `usufructo` (enum `movimiento_tipo`).
  final String tipo;

  /// `total` | `parcial` solo en usufructos; `null` en acumulaciones
  /// (CHECK `banco_alcance_solo_usufructo`).
  final String? alcance;

  /// `yyyy-MM-dd`.
  final String fecha;
  final int minutos;

  /// `vigente` | `perdido` (enum `movimiento_estado`).
  final String estado;
  final String? tipoDocumentoId;
  final String? numeroGde;

  /// Ruta en el bucket `comprobantes` (se completa al subir el adjunto).
  final String? adjuntoPath;

  /// Referencia al adjunto guardado en el dispositivo (ver `PhotoStore`).
  /// El nombre termina en la extensión (`.jpg` o `.pdf`).
  final String? adjuntoLocal;
  final String? observacion;
  final DateTime? deletedAt;
  final DateTime updatedAt;
  final int revision;
  final SyncStatus syncStatus;
  final String? syncError;
  const LocalMovimiento({
    required this.id,
    required this.userId,
    required this.tipo,
    this.alcance,
    required this.fecha,
    required this.minutos,
    required this.estado,
    this.tipoDocumentoId,
    this.numeroGde,
    this.adjuntoPath,
    this.adjuntoLocal,
    this.observacion,
    this.deletedAt,
    required this.updatedAt,
    required this.revision,
    required this.syncStatus,
    this.syncError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['tipo'] = Variable<String>(tipo);
    if (!nullToAbsent || alcance != null) {
      map['alcance'] = Variable<String>(alcance);
    }
    map['fecha'] = Variable<String>(fecha);
    map['minutos'] = Variable<int>(minutos);
    map['estado'] = Variable<String>(estado);
    if (!nullToAbsent || tipoDocumentoId != null) {
      map['tipo_documento_id'] = Variable<String>(tipoDocumentoId);
    }
    if (!nullToAbsent || numeroGde != null) {
      map['numero_gde'] = Variable<String>(numeroGde);
    }
    if (!nullToAbsent || adjuntoPath != null) {
      map['adjunto_path'] = Variable<String>(adjuntoPath);
    }
    if (!nullToAbsent || adjuntoLocal != null) {
      map['adjunto_local'] = Variable<String>(adjuntoLocal);
    }
    if (!nullToAbsent || observacion != null) {
      map['observacion'] = Variable<String>(observacion);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['revision'] = Variable<int>(revision);
    {
      map['sync_status'] = Variable<String>(
        $BancoMovimientosTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    return map;
  }

  BancoMovimientosCompanion toCompanion(bool nullToAbsent) {
    return BancoMovimientosCompanion(
      id: Value(id),
      userId: Value(userId),
      tipo: Value(tipo),
      alcance: alcance == null && nullToAbsent
          ? const Value.absent()
          : Value(alcance),
      fecha: Value(fecha),
      minutos: Value(minutos),
      estado: Value(estado),
      tipoDocumentoId: tipoDocumentoId == null && nullToAbsent
          ? const Value.absent()
          : Value(tipoDocumentoId),
      numeroGde: numeroGde == null && nullToAbsent
          ? const Value.absent()
          : Value(numeroGde),
      adjuntoPath: adjuntoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(adjuntoPath),
      adjuntoLocal: adjuntoLocal == null && nullToAbsent
          ? const Value.absent()
          : Value(adjuntoLocal),
      observacion: observacion == null && nullToAbsent
          ? const Value.absent()
          : Value(observacion),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      updatedAt: Value(updatedAt),
      revision: Value(revision),
      syncStatus: Value(syncStatus),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
    );
  }

  factory LocalMovimiento.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMovimiento(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      tipo: serializer.fromJson<String>(json['tipo']),
      alcance: serializer.fromJson<String?>(json['alcance']),
      fecha: serializer.fromJson<String>(json['fecha']),
      minutos: serializer.fromJson<int>(json['minutos']),
      estado: serializer.fromJson<String>(json['estado']),
      tipoDocumentoId: serializer.fromJson<String?>(json['tipoDocumentoId']),
      numeroGde: serializer.fromJson<String?>(json['numeroGde']),
      adjuntoPath: serializer.fromJson<String?>(json['adjuntoPath']),
      adjuntoLocal: serializer.fromJson<String?>(json['adjuntoLocal']),
      observacion: serializer.fromJson<String?>(json['observacion']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      revision: serializer.fromJson<int>(json['revision']),
      syncStatus: $BancoMovimientosTable.$convertersyncStatus.fromJson(
        serializer.fromJson<String>(json['syncStatus']),
      ),
      syncError: serializer.fromJson<String?>(json['syncError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'tipo': serializer.toJson<String>(tipo),
      'alcance': serializer.toJson<String?>(alcance),
      'fecha': serializer.toJson<String>(fecha),
      'minutos': serializer.toJson<int>(minutos),
      'estado': serializer.toJson<String>(estado),
      'tipoDocumentoId': serializer.toJson<String?>(tipoDocumentoId),
      'numeroGde': serializer.toJson<String?>(numeroGde),
      'adjuntoPath': serializer.toJson<String?>(adjuntoPath),
      'adjuntoLocal': serializer.toJson<String?>(adjuntoLocal),
      'observacion': serializer.toJson<String?>(observacion),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'revision': serializer.toJson<int>(revision),
      'syncStatus': serializer.toJson<String>(
        $BancoMovimientosTable.$convertersyncStatus.toJson(syncStatus),
      ),
      'syncError': serializer.toJson<String?>(syncError),
    };
  }

  LocalMovimiento copyWith({
    String? id,
    String? userId,
    String? tipo,
    Value<String?> alcance = const Value.absent(),
    String? fecha,
    int? minutos,
    String? estado,
    Value<String?> tipoDocumentoId = const Value.absent(),
    Value<String?> numeroGde = const Value.absent(),
    Value<String?> adjuntoPath = const Value.absent(),
    Value<String?> adjuntoLocal = const Value.absent(),
    Value<String?> observacion = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? updatedAt,
    int? revision,
    SyncStatus? syncStatus,
    Value<String?> syncError = const Value.absent(),
  }) => LocalMovimiento(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    tipo: tipo ?? this.tipo,
    alcance: alcance.present ? alcance.value : this.alcance,
    fecha: fecha ?? this.fecha,
    minutos: minutos ?? this.minutos,
    estado: estado ?? this.estado,
    tipoDocumentoId: tipoDocumentoId.present
        ? tipoDocumentoId.value
        : this.tipoDocumentoId,
    numeroGde: numeroGde.present ? numeroGde.value : this.numeroGde,
    adjuntoPath: adjuntoPath.present ? adjuntoPath.value : this.adjuntoPath,
    adjuntoLocal: adjuntoLocal.present ? adjuntoLocal.value : this.adjuntoLocal,
    observacion: observacion.present ? observacion.value : this.observacion,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    revision: revision ?? this.revision,
    syncStatus: syncStatus ?? this.syncStatus,
    syncError: syncError.present ? syncError.value : this.syncError,
  );
  LocalMovimiento copyWithCompanion(BancoMovimientosCompanion data) {
    return LocalMovimiento(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      alcance: data.alcance.present ? data.alcance.value : this.alcance,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      minutos: data.minutos.present ? data.minutos.value : this.minutos,
      estado: data.estado.present ? data.estado.value : this.estado,
      tipoDocumentoId: data.tipoDocumentoId.present
          ? data.tipoDocumentoId.value
          : this.tipoDocumentoId,
      numeroGde: data.numeroGde.present ? data.numeroGde.value : this.numeroGde,
      adjuntoPath: data.adjuntoPath.present
          ? data.adjuntoPath.value
          : this.adjuntoPath,
      adjuntoLocal: data.adjuntoLocal.present
          ? data.adjuntoLocal.value
          : this.adjuntoLocal,
      observacion: data.observacion.present
          ? data.observacion.value
          : this.observacion,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      revision: data.revision.present ? data.revision.value : this.revision,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMovimiento(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('tipo: $tipo, ')
          ..write('alcance: $alcance, ')
          ..write('fecha: $fecha, ')
          ..write('minutos: $minutos, ')
          ..write('estado: $estado, ')
          ..write('tipoDocumentoId: $tipoDocumentoId, ')
          ..write('numeroGde: $numeroGde, ')
          ..write('adjuntoPath: $adjuntoPath, ')
          ..write('adjuntoLocal: $adjuntoLocal, ')
          ..write('observacion: $observacion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    tipo,
    alcance,
    fecha,
    minutos,
    estado,
    tipoDocumentoId,
    numeroGde,
    adjuntoPath,
    adjuntoLocal,
    observacion,
    deletedAt,
    updatedAt,
    revision,
    syncStatus,
    syncError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMovimiento &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.tipo == this.tipo &&
          other.alcance == this.alcance &&
          other.fecha == this.fecha &&
          other.minutos == this.minutos &&
          other.estado == this.estado &&
          other.tipoDocumentoId == this.tipoDocumentoId &&
          other.numeroGde == this.numeroGde &&
          other.adjuntoPath == this.adjuntoPath &&
          other.adjuntoLocal == this.adjuntoLocal &&
          other.observacion == this.observacion &&
          other.deletedAt == this.deletedAt &&
          other.updatedAt == this.updatedAt &&
          other.revision == this.revision &&
          other.syncStatus == this.syncStatus &&
          other.syncError == this.syncError);
}

class BancoMovimientosCompanion extends UpdateCompanion<LocalMovimiento> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> tipo;
  final Value<String?> alcance;
  final Value<String> fecha;
  final Value<int> minutos;
  final Value<String> estado;
  final Value<String?> tipoDocumentoId;
  final Value<String?> numeroGde;
  final Value<String?> adjuntoPath;
  final Value<String?> adjuntoLocal;
  final Value<String?> observacion;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> updatedAt;
  final Value<int> revision;
  final Value<SyncStatus> syncStatus;
  final Value<String?> syncError;
  final Value<int> rowid;
  const BancoMovimientosCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.tipo = const Value.absent(),
    this.alcance = const Value.absent(),
    this.fecha = const Value.absent(),
    this.minutos = const Value.absent(),
    this.estado = const Value.absent(),
    this.tipoDocumentoId = const Value.absent(),
    this.numeroGde = const Value.absent(),
    this.adjuntoPath = const Value.absent(),
    this.adjuntoLocal = const Value.absent(),
    this.observacion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BancoMovimientosCompanion.insert({
    required String id,
    required String userId,
    required String tipo,
    this.alcance = const Value.absent(),
    required String fecha,
    required int minutos,
    this.estado = const Value.absent(),
    this.tipoDocumentoId = const Value.absent(),
    this.numeroGde = const Value.absent(),
    this.adjuntoPath = const Value.absent(),
    this.adjuntoLocal = const Value.absent(),
    this.observacion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required DateTime updatedAt,
    this.revision = const Value.absent(),
    required SyncStatus syncStatus,
    this.syncError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       tipo = Value(tipo),
       fecha = Value(fecha),
       minutos = Value(minutos),
       updatedAt = Value(updatedAt),
       syncStatus = Value(syncStatus);
  static Insertable<LocalMovimiento> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? tipo,
    Expression<String>? alcance,
    Expression<String>? fecha,
    Expression<int>? minutos,
    Expression<String>? estado,
    Expression<String>? tipoDocumentoId,
    Expression<String>? numeroGde,
    Expression<String>? adjuntoPath,
    Expression<String>? adjuntoLocal,
    Expression<String>? observacion,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? revision,
    Expression<String>? syncStatus,
    Expression<String>? syncError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (tipo != null) 'tipo': tipo,
      if (alcance != null) 'alcance': alcance,
      if (fecha != null) 'fecha': fecha,
      if (minutos != null) 'minutos': minutos,
      if (estado != null) 'estado': estado,
      if (tipoDocumentoId != null) 'tipo_documento_id': tipoDocumentoId,
      if (numeroGde != null) 'numero_gde': numeroGde,
      if (adjuntoPath != null) 'adjunto_path': adjuntoPath,
      if (adjuntoLocal != null) 'adjunto_local': adjuntoLocal,
      if (observacion != null) 'observacion': observacion,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (revision != null) 'revision': revision,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncError != null) 'sync_error': syncError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BancoMovimientosCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? tipo,
    Value<String?>? alcance,
    Value<String>? fecha,
    Value<int>? minutos,
    Value<String>? estado,
    Value<String?>? tipoDocumentoId,
    Value<String?>? numeroGde,
    Value<String?>? adjuntoPath,
    Value<String?>? adjuntoLocal,
    Value<String?>? observacion,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? updatedAt,
    Value<int>? revision,
    Value<SyncStatus>? syncStatus,
    Value<String?>? syncError,
    Value<int>? rowid,
  }) {
    return BancoMovimientosCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tipo: tipo ?? this.tipo,
      alcance: alcance ?? this.alcance,
      fecha: fecha ?? this.fecha,
      minutos: minutos ?? this.minutos,
      estado: estado ?? this.estado,
      tipoDocumentoId: tipoDocumentoId ?? this.tipoDocumentoId,
      numeroGde: numeroGde ?? this.numeroGde,
      adjuntoPath: adjuntoPath ?? this.adjuntoPath,
      adjuntoLocal: adjuntoLocal ?? this.adjuntoLocal,
      observacion: observacion ?? this.observacion,
      deletedAt: deletedAt ?? this.deletedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      revision: revision ?? this.revision,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError ?? this.syncError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (alcance.present) {
      map['alcance'] = Variable<String>(alcance.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<String>(fecha.value);
    }
    if (minutos.present) {
      map['minutos'] = Variable<int>(minutos.value);
    }
    if (estado.present) {
      map['estado'] = Variable<String>(estado.value);
    }
    if (tipoDocumentoId.present) {
      map['tipo_documento_id'] = Variable<String>(tipoDocumentoId.value);
    }
    if (numeroGde.present) {
      map['numero_gde'] = Variable<String>(numeroGde.value);
    }
    if (adjuntoPath.present) {
      map['adjunto_path'] = Variable<String>(adjuntoPath.value);
    }
    if (adjuntoLocal.present) {
      map['adjunto_local'] = Variable<String>(adjuntoLocal.value);
    }
    if (observacion.present) {
      map['observacion'] = Variable<String>(observacion.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $BancoMovimientosTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BancoMovimientosCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('tipo: $tipo, ')
          ..write('alcance: $alcance, ')
          ..write('fecha: $fecha, ')
          ..write('minutos: $minutos, ')
          ..write('estado: $estado, ')
          ..write('tipoDocumentoId: $tipoDocumentoId, ')
          ..write('numeroGde: $numeroGde, ')
          ..write('adjuntoPath: $adjuntoPath, ')
          ..write('adjuntoLocal: $adjuntoLocal, ')
          ..write('observacion: $observacion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FichadasTable fichadas = $FichadasTable(this);
  late final $FeriadosTable feriados = $FeriadosTable(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final $LocalPhotosTable localPhotos = $LocalPhotosTable(this);
  late final $TiposDocumentoGdeTable tiposDocumentoGde =
      $TiposDocumentoGdeTable(this);
  late final $BancoMovimientosTable bancoMovimientos = $BancoMovimientosTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    fichadas,
    feriados,
    profiles,
    syncState,
    localPhotos,
    tiposDocumentoGde,
    bancoMovimientos,
  ];
}

typedef $$FichadasTableCreateCompanionBuilder = FichadasCompanion Function({
  required String id,
  required String userId,
  required String fecha,
  required int ingresoMin,
  Value<int?> egresoMin,
  Value<int?> ingresoOriginalMin,
  Value<int?> egresoOriginalMin,
  Value<bool> editado,
  Value<String?> fotoIngresoPath,
  Value<String?> fotoEgresoPath,
  Value<String?> fotoIngresoLocal,
  Value<String?> fotoEgresoLocal,
  Value<String?> observacion,
  Value<String> origen,
  Value<DateTime?> deletedAt,
  required DateTime updatedAt,
  Value<int> revision,
  required SyncStatus syncStatus,
  Value<String?> syncError,
  Value<int> rowid,
});
typedef $$FichadasTableUpdateCompanionBuilder = FichadasCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> fecha,
  Value<int> ingresoMin,
  Value<int?> egresoMin,
  Value<int?> ingresoOriginalMin,
  Value<int?> egresoOriginalMin,
  Value<bool> editado,
  Value<String?> fotoIngresoPath,
  Value<String?> fotoEgresoPath,
  Value<String?> fotoIngresoLocal,
  Value<String?> fotoEgresoLocal,
  Value<String?> observacion,
  Value<String> origen,
  Value<DateTime?> deletedAt,
  Value<DateTime> updatedAt,
  Value<int> revision,
  Value<SyncStatus> syncStatus,
  Value<String?> syncError,
  Value<int> rowid,
});

class $$FichadasTableFilterComposer
    extends Composer<_$AppDatabase, $FichadasTable> {
  $$FichadasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ingresoMin => $composableBuilder(
    column: $table.ingresoMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get egresoMin => $composableBuilder(
    column: $table.egresoMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ingresoOriginalMin => $composableBuilder(
    column: $table.ingresoOriginalMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get egresoOriginalMin => $composableBuilder(
    column: $table.egresoOriginalMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get editado => $composableBuilder(
    column: $table.editado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fotoIngresoPath => $composableBuilder(
    column: $table.fotoIngresoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fotoEgresoPath => $composableBuilder(
    column: $table.fotoEgresoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fotoIngresoLocal => $composableBuilder(
    column: $table.fotoIngresoLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fotoEgresoLocal => $composableBuilder(
    column: $table.fotoEgresoLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observacion => $composableBuilder(
    column: $table.observacion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origen => $composableBuilder(
    column: $table.origen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FichadasTableOrderingComposer
    extends Composer<_$AppDatabase, $FichadasTable> {
  $$FichadasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ingresoMin => $composableBuilder(
    column: $table.ingresoMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get egresoMin => $composableBuilder(
    column: $table.egresoMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ingresoOriginalMin => $composableBuilder(
    column: $table.ingresoOriginalMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get egresoOriginalMin => $composableBuilder(
    column: $table.egresoOriginalMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get editado => $composableBuilder(
    column: $table.editado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fotoIngresoPath => $composableBuilder(
    column: $table.fotoIngresoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fotoEgresoPath => $composableBuilder(
    column: $table.fotoEgresoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fotoIngresoLocal => $composableBuilder(
    column: $table.fotoIngresoLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fotoEgresoLocal => $composableBuilder(
    column: $table.fotoEgresoLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observacion => $composableBuilder(
    column: $table.observacion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origen => $composableBuilder(
    column: $table.origen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FichadasTableAnnotationComposer
    extends Composer<_$AppDatabase, $FichadasTable> {
  $$FichadasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<int> get ingresoMin => $composableBuilder(
    column: $table.ingresoMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get egresoMin =>
      $composableBuilder(column: $table.egresoMin, builder: (column) => column);

  GeneratedColumn<int> get ingresoOriginalMin => $composableBuilder(
    column: $table.ingresoOriginalMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get egresoOriginalMin => $composableBuilder(
    column: $table.egresoOriginalMin,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get editado =>
      $composableBuilder(column: $table.editado, builder: (column) => column);

  GeneratedColumn<String> get fotoIngresoPath => $composableBuilder(
    column: $table.fotoIngresoPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fotoEgresoPath => $composableBuilder(
    column: $table.fotoEgresoPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fotoIngresoLocal => $composableBuilder(
    column: $table.fotoIngresoLocal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fotoEgresoLocal => $composableBuilder(
    column: $table.fotoEgresoLocal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get observacion => $composableBuilder(
    column: $table.observacion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get origen =>
      $composableBuilder(column: $table.origen, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);
}

class $$FichadasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FichadasTable,
          LocalFichada,
          $$FichadasTableFilterComposer,
          $$FichadasTableOrderingComposer,
          $$FichadasTableAnnotationComposer,
          $$FichadasTableCreateCompanionBuilder,
          $$FichadasTableUpdateCompanionBuilder,
          (
            LocalFichada,
            BaseReferences<_$AppDatabase, $FichadasTable, LocalFichada>,
          ),
          LocalFichada,
          PrefetchHooks Function()
        > {
  $$FichadasTableTableManager(_$AppDatabase db, $FichadasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FichadasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FichadasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FichadasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> fecha = const Value.absent(),
                Value<int> ingresoMin = const Value.absent(),
                Value<int?> egresoMin = const Value.absent(),
                Value<int?> ingresoOriginalMin = const Value.absent(),
                Value<int?> egresoOriginalMin = const Value.absent(),
                Value<bool> editado = const Value.absent(),
                Value<String?> fotoIngresoPath = const Value.absent(),
                Value<String?> fotoEgresoPath = const Value.absent(),
                Value<String?> fotoIngresoLocal = const Value.absent(),
                Value<String?> fotoEgresoLocal = const Value.absent(),
                Value<String?> observacion = const Value.absent(),
                Value<String> origen = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FichadasCompanion(
                id: id,
                userId: userId,
                fecha: fecha,
                ingresoMin: ingresoMin,
                egresoMin: egresoMin,
                ingresoOriginalMin: ingresoOriginalMin,
                egresoOriginalMin: egresoOriginalMin,
                editado: editado,
                fotoIngresoPath: fotoIngresoPath,
                fotoEgresoPath: fotoEgresoPath,
                fotoIngresoLocal: fotoIngresoLocal,
                fotoEgresoLocal: fotoEgresoLocal,
                observacion: observacion,
                origen: origen,
                deletedAt: deletedAt,
                updatedAt: updatedAt,
                revision: revision,
                syncStatus: syncStatus,
                syncError: syncError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String fecha,
                required int ingresoMin,
                Value<int?> egresoMin = const Value.absent(),
                Value<int?> ingresoOriginalMin = const Value.absent(),
                Value<int?> egresoOriginalMin = const Value.absent(),
                Value<bool> editado = const Value.absent(),
                Value<String?> fotoIngresoPath = const Value.absent(),
                Value<String?> fotoEgresoPath = const Value.absent(),
                Value<String?> fotoIngresoLocal = const Value.absent(),
                Value<String?> fotoEgresoLocal = const Value.absent(),
                Value<String?> observacion = const Value.absent(),
                Value<String> origen = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required DateTime updatedAt,
                Value<int> revision = const Value.absent(),
                required SyncStatus syncStatus,
                Value<String?> syncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FichadasCompanion.insert(
                id: id,
                userId: userId,
                fecha: fecha,
                ingresoMin: ingresoMin,
                egresoMin: egresoMin,
                ingresoOriginalMin: ingresoOriginalMin,
                egresoOriginalMin: egresoOriginalMin,
                editado: editado,
                fotoIngresoPath: fotoIngresoPath,
                fotoEgresoPath: fotoEgresoPath,
                fotoIngresoLocal: fotoIngresoLocal,
                fotoEgresoLocal: fotoEgresoLocal,
                observacion: observacion,
                origen: origen,
                deletedAt: deletedAt,
                updatedAt: updatedAt,
                revision: revision,
                syncStatus: syncStatus,
                syncError: syncError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FichadasTable, LocalFichada>(table),
                  BaseReferences<_$AppDatabase, $FichadasTable, LocalFichada>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FichadasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FichadasTable,
      LocalFichada,
      $$FichadasTableFilterComposer,
      $$FichadasTableOrderingComposer,
      $$FichadasTableAnnotationComposer,
      $$FichadasTableCreateCompanionBuilder,
      $$FichadasTableUpdateCompanionBuilder,
      (
        LocalFichada,
        BaseReferences<_$AppDatabase, $FichadasTable, LocalFichada>,
      ),
      LocalFichada,
      PrefetchHooks Function()
    >;
typedef $$FeriadosTableCreateCompanionBuilder = FeriadosCompanion Function({
  required String fecha,
  required String nombre,
  Value<String> tipo,
  Value<int> rowid,
});
typedef $$FeriadosTableUpdateCompanionBuilder = FeriadosCompanion Function({
  Value<String> fecha,
  Value<String> nombre,
  Value<String> tipo,
  Value<int> rowid,
});

class $$FeriadosTableFilterComposer
    extends Composer<_$AppDatabase, $FeriadosTable> {
  $$FeriadosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FeriadosTableOrderingComposer
    extends Composer<_$AppDatabase, $FeriadosTable> {
  $$FeriadosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FeriadosTableAnnotationComposer
    extends Composer<_$AppDatabase, $FeriadosTable> {
  $$FeriadosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);
}

class $$FeriadosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FeriadosTable,
          LocalFeriado,
          $$FeriadosTableFilterComposer,
          $$FeriadosTableOrderingComposer,
          $$FeriadosTableAnnotationComposer,
          $$FeriadosTableCreateCompanionBuilder,
          $$FeriadosTableUpdateCompanionBuilder,
          (
            LocalFeriado,
            BaseReferences<_$AppDatabase, $FeriadosTable, LocalFeriado>,
          ),
          LocalFeriado,
          PrefetchHooks Function()
        > {
  $$FeriadosTableTableManager(_$AppDatabase db, $FeriadosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FeriadosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FeriadosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FeriadosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> fecha = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FeriadosCompanion(
                fecha: fecha,
                nombre: nombre,
                tipo: tipo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fecha,
                required String nombre,
                Value<String> tipo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FeriadosCompanion.insert(
                fecha: fecha,
                nombre: nombre,
                tipo: tipo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FeriadosTable, LocalFeriado>(table),
                  BaseReferences<_$AppDatabase, $FeriadosTable, LocalFeriado>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FeriadosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FeriadosTable,
      LocalFeriado,
      $$FeriadosTableFilterComposer,
      $$FeriadosTableOrderingComposer,
      $$FeriadosTableAnnotationComposer,
      $$FeriadosTableCreateCompanionBuilder,
      $$FeriadosTableUpdateCompanionBuilder,
      (
        LocalFeriado,
        BaseReferences<_$AppDatabase, $FeriadosTable, LocalFeriado>,
      ),
      LocalFeriado,
      PrefetchHooks Function()
    >;
typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  required String userId,
  Value<String?> agrupamiento,
  required DateTime updatedAt,
  Value<int> revision,
  required SyncStatus syncStatus,
  Value<String?> syncError,
  Value<int> rowid,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<String> userId,
  Value<String?> agrupamiento,
  Value<DateTime> updatedAt,
  Value<int> revision,
  Value<SyncStatus> syncStatus,
  Value<String?> syncError,
  Value<int> rowid,
});

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agrupamiento => $composableBuilder(
    column: $table.agrupamiento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agrupamiento => $composableBuilder(
    column: $table.agrupamiento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get agrupamiento => $composableBuilder(
    column: $table.agrupamiento,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          LocalProfile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (
            LocalProfile,
            BaseReferences<_$AppDatabase, $ProfilesTable, LocalProfile>,
          ),
          LocalProfile,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String?> agrupamiento = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion(
                userId: userId,
                agrupamiento: agrupamiento,
                updatedAt: updatedAt,
                revision: revision,
                syncStatus: syncStatus,
                syncError: syncError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                Value<String?> agrupamiento = const Value.absent(),
                required DateTime updatedAt,
                Value<int> revision = const Value.absent(),
                required SyncStatus syncStatus,
                Value<String?> syncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion.insert(
                userId: userId,
                agrupamiento: agrupamiento,
                updatedAt: updatedAt,
                revision: revision,
                syncStatus: syncStatus,
                syncError: syncError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfilesTable, LocalProfile>(table),
                  BaseReferences<_$AppDatabase, $ProfilesTable, LocalProfile>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      LocalProfile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (
        LocalProfile,
        BaseReferences<_$AppDatabase, $ProfilesTable, LocalProfile>,
      ),
      LocalProfile,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableCreateCompanionBuilder = SyncStateCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SyncStateTableUpdateCompanionBuilder = SyncStateCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateTable,
          SyncStateData,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            SyncStateData,
            BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>,
          ),
          SyncStateData,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SyncStateCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SyncStateCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncStateTable, SyncStateData>(table),
                  BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateTable,
      SyncStateData,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        SyncStateData,
        BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>,
      ),
      SyncStateData,
      PrefetchHooks Function()
    >;
typedef $$LocalPhotosTableCreateCompanionBuilder =
    LocalPhotosCompanion Function({
      required String key,
      required Uint8List bytes,
      Value<int> rowid,
    });
typedef $$LocalPhotosTableUpdateCompanionBuilder =
    LocalPhotosCompanion Function({
      Value<String> key,
      Value<Uint8List> bytes,
      Value<int> rowid,
    });

class $$LocalPhotosTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPhotosTable> {
  $$LocalPhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalPhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPhotosTable> {
  $$LocalPhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalPhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPhotosTable> {
  $$LocalPhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<Uint8List> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);
}

class $$LocalPhotosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalPhotosTable,
          LocalPhoto,
          $$LocalPhotosTableFilterComposer,
          $$LocalPhotosTableOrderingComposer,
          $$LocalPhotosTableAnnotationComposer,
          $$LocalPhotosTableCreateCompanionBuilder,
          $$LocalPhotosTableUpdateCompanionBuilder,
          (
            LocalPhoto,
            BaseReferences<_$AppDatabase, $LocalPhotosTable, LocalPhoto>,
          ),
          LocalPhoto,
          PrefetchHooks Function()
        > {
  $$LocalPhotosTableTableManager(_$AppDatabase db, $LocalPhotosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<Uint8List> bytes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => LocalPhotosCompanion(key: key, bytes: bytes, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required Uint8List bytes,
                Value<int> rowid = const Value.absent(),
              }) => LocalPhotosCompanion.insert(
                key: key,
                bytes: bytes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalPhotosTable, LocalPhoto>(table),
                  BaseReferences<_$AppDatabase, $LocalPhotosTable, LocalPhoto>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalPhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalPhotosTable,
      LocalPhoto,
      $$LocalPhotosTableFilterComposer,
      $$LocalPhotosTableOrderingComposer,
      $$LocalPhotosTableAnnotationComposer,
      $$LocalPhotosTableCreateCompanionBuilder,
      $$LocalPhotosTableUpdateCompanionBuilder,
      (
        LocalPhoto,
        BaseReferences<_$AppDatabase, $LocalPhotosTable, LocalPhoto>,
      ),
      LocalPhoto,
      PrefetchHooks Function()
    >;
typedef $$TiposDocumentoGdeTableCreateCompanionBuilder =
    TiposDocumentoGdeCompanion Function({
      required String id,
      required String userId,
      required String codigo,
      Value<String?> descripcion,
      Value<DateTime?> deletedAt,
      required DateTime updatedAt,
      Value<int> revision,
      required SyncStatus syncStatus,
      Value<String?> syncError,
      Value<int> rowid,
    });
typedef $$TiposDocumentoGdeTableUpdateCompanionBuilder =
    TiposDocumentoGdeCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> codigo,
      Value<String?> descripcion,
      Value<DateTime?> deletedAt,
      Value<DateTime> updatedAt,
      Value<int> revision,
      Value<SyncStatus> syncStatus,
      Value<String?> syncError,
      Value<int> rowid,
    });

class $$TiposDocumentoGdeTableFilterComposer
    extends Composer<_$AppDatabase, $TiposDocumentoGdeTable> {
  $$TiposDocumentoGdeTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codigo => $composableBuilder(
    column: $table.codigo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TiposDocumentoGdeTableOrderingComposer
    extends Composer<_$AppDatabase, $TiposDocumentoGdeTable> {
  $$TiposDocumentoGdeTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codigo => $composableBuilder(
    column: $table.codigo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TiposDocumentoGdeTableAnnotationComposer
    extends Composer<_$AppDatabase, $TiposDocumentoGdeTable> {
  $$TiposDocumentoGdeTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get codigo =>
      $composableBuilder(column: $table.codigo, builder: (column) => column);

  GeneratedColumn<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);
}

class $$TiposDocumentoGdeTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TiposDocumentoGdeTable,
          LocalTipoDocumento,
          $$TiposDocumentoGdeTableFilterComposer,
          $$TiposDocumentoGdeTableOrderingComposer,
          $$TiposDocumentoGdeTableAnnotationComposer,
          $$TiposDocumentoGdeTableCreateCompanionBuilder,
          $$TiposDocumentoGdeTableUpdateCompanionBuilder,
          (
            LocalTipoDocumento,
            BaseReferences<
              _$AppDatabase,
              $TiposDocumentoGdeTable,
              LocalTipoDocumento
            >,
          ),
          LocalTipoDocumento,
          PrefetchHooks Function()
        > {
  $$TiposDocumentoGdeTableTableManager(
    _$AppDatabase db,
    $TiposDocumentoGdeTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TiposDocumentoGdeTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TiposDocumentoGdeTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TiposDocumentoGdeTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> codigo = const Value.absent(),
                Value<String?> descripcion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TiposDocumentoGdeCompanion(
                id: id,
                userId: userId,
                codigo: codigo,
                descripcion: descripcion,
                deletedAt: deletedAt,
                updatedAt: updatedAt,
                revision: revision,
                syncStatus: syncStatus,
                syncError: syncError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String codigo,
                Value<String?> descripcion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required DateTime updatedAt,
                Value<int> revision = const Value.absent(),
                required SyncStatus syncStatus,
                Value<String?> syncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TiposDocumentoGdeCompanion.insert(
                id: id,
                userId: userId,
                codigo: codigo,
                descripcion: descripcion,
                deletedAt: deletedAt,
                updatedAt: updatedAt,
                revision: revision,
                syncStatus: syncStatus,
                syncError: syncError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TiposDocumentoGdeTable, LocalTipoDocumento>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $TiposDocumentoGdeTable,
                    LocalTipoDocumento
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TiposDocumentoGdeTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TiposDocumentoGdeTable,
      LocalTipoDocumento,
      $$TiposDocumentoGdeTableFilterComposer,
      $$TiposDocumentoGdeTableOrderingComposer,
      $$TiposDocumentoGdeTableAnnotationComposer,
      $$TiposDocumentoGdeTableCreateCompanionBuilder,
      $$TiposDocumentoGdeTableUpdateCompanionBuilder,
      (
        LocalTipoDocumento,
        BaseReferences<
          _$AppDatabase,
          $TiposDocumentoGdeTable,
          LocalTipoDocumento
        >,
      ),
      LocalTipoDocumento,
      PrefetchHooks Function()
    >;
typedef $$BancoMovimientosTableCreateCompanionBuilder =
    BancoMovimientosCompanion Function({
      required String id,
      required String userId,
      required String tipo,
      Value<String?> alcance,
      required String fecha,
      required int minutos,
      Value<String> estado,
      Value<String?> tipoDocumentoId,
      Value<String?> numeroGde,
      Value<String?> adjuntoPath,
      Value<String?> adjuntoLocal,
      Value<String?> observacion,
      Value<DateTime?> deletedAt,
      required DateTime updatedAt,
      Value<int> revision,
      required SyncStatus syncStatus,
      Value<String?> syncError,
      Value<int> rowid,
    });
typedef $$BancoMovimientosTableUpdateCompanionBuilder =
    BancoMovimientosCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> tipo,
      Value<String?> alcance,
      Value<String> fecha,
      Value<int> minutos,
      Value<String> estado,
      Value<String?> tipoDocumentoId,
      Value<String?> numeroGde,
      Value<String?> adjuntoPath,
      Value<String?> adjuntoLocal,
      Value<String?> observacion,
      Value<DateTime?> deletedAt,
      Value<DateTime> updatedAt,
      Value<int> revision,
      Value<SyncStatus> syncStatus,
      Value<String?> syncError,
      Value<int> rowid,
    });

class $$BancoMovimientosTableFilterComposer
    extends Composer<_$AppDatabase, $BancoMovimientosTable> {
  $$BancoMovimientosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alcance => $composableBuilder(
    column: $table.alcance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutos => $composableBuilder(
    column: $table.minutos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipoDocumentoId => $composableBuilder(
    column: $table.tipoDocumentoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get numeroGde => $composableBuilder(
    column: $table.numeroGde,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adjuntoPath => $composableBuilder(
    column: $table.adjuntoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adjuntoLocal => $composableBuilder(
    column: $table.adjuntoLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observacion => $composableBuilder(
    column: $table.observacion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BancoMovimientosTableOrderingComposer
    extends Composer<_$AppDatabase, $BancoMovimientosTable> {
  $$BancoMovimientosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alcance => $composableBuilder(
    column: $table.alcance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutos => $composableBuilder(
    column: $table.minutos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipoDocumentoId => $composableBuilder(
    column: $table.tipoDocumentoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get numeroGde => $composableBuilder(
    column: $table.numeroGde,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adjuntoPath => $composableBuilder(
    column: $table.adjuntoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adjuntoLocal => $composableBuilder(
    column: $table.adjuntoLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observacion => $composableBuilder(
    column: $table.observacion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BancoMovimientosTableAnnotationComposer
    extends Composer<_$AppDatabase, $BancoMovimientosTable> {
  $$BancoMovimientosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get alcance =>
      $composableBuilder(column: $table.alcance, builder: (column) => column);

  GeneratedColumn<String> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<int> get minutos =>
      $composableBuilder(column: $table.minutos, builder: (column) => column);

  GeneratedColumn<String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);

  GeneratedColumn<String> get tipoDocumentoId => $composableBuilder(
    column: $table.tipoDocumentoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get numeroGde =>
      $composableBuilder(column: $table.numeroGde, builder: (column) => column);

  GeneratedColumn<String> get adjuntoPath => $composableBuilder(
    column: $table.adjuntoPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get adjuntoLocal => $composableBuilder(
    column: $table.adjuntoLocal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get observacion => $composableBuilder(
    column: $table.observacion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);
}

class $$BancoMovimientosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BancoMovimientosTable,
          LocalMovimiento,
          $$BancoMovimientosTableFilterComposer,
          $$BancoMovimientosTableOrderingComposer,
          $$BancoMovimientosTableAnnotationComposer,
          $$BancoMovimientosTableCreateCompanionBuilder,
          $$BancoMovimientosTableUpdateCompanionBuilder,
          (
            LocalMovimiento,
            BaseReferences<
              _$AppDatabase,
              $BancoMovimientosTable,
              LocalMovimiento
            >,
          ),
          LocalMovimiento,
          PrefetchHooks Function()
        > {
  $$BancoMovimientosTableTableManager(
    _$AppDatabase db,
    $BancoMovimientosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BancoMovimientosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BancoMovimientosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BancoMovimientosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<String?> alcance = const Value.absent(),
                Value<String> fecha = const Value.absent(),
                Value<int> minutos = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<String?> tipoDocumentoId = const Value.absent(),
                Value<String?> numeroGde = const Value.absent(),
                Value<String?> adjuntoPath = const Value.absent(),
                Value<String?> adjuntoLocal = const Value.absent(),
                Value<String?> observacion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BancoMovimientosCompanion(
                id: id,
                userId: userId,
                tipo: tipo,
                alcance: alcance,
                fecha: fecha,
                minutos: minutos,
                estado: estado,
                tipoDocumentoId: tipoDocumentoId,
                numeroGde: numeroGde,
                adjuntoPath: adjuntoPath,
                adjuntoLocal: adjuntoLocal,
                observacion: observacion,
                deletedAt: deletedAt,
                updatedAt: updatedAt,
                revision: revision,
                syncStatus: syncStatus,
                syncError: syncError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String tipo,
                Value<String?> alcance = const Value.absent(),
                required String fecha,
                required int minutos,
                Value<String> estado = const Value.absent(),
                Value<String?> tipoDocumentoId = const Value.absent(),
                Value<String?> numeroGde = const Value.absent(),
                Value<String?> adjuntoPath = const Value.absent(),
                Value<String?> adjuntoLocal = const Value.absent(),
                Value<String?> observacion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required DateTime updatedAt,
                Value<int> revision = const Value.absent(),
                required SyncStatus syncStatus,
                Value<String?> syncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BancoMovimientosCompanion.insert(
                id: id,
                userId: userId,
                tipo: tipo,
                alcance: alcance,
                fecha: fecha,
                minutos: minutos,
                estado: estado,
                tipoDocumentoId: tipoDocumentoId,
                numeroGde: numeroGde,
                adjuntoPath: adjuntoPath,
                adjuntoLocal: adjuntoLocal,
                observacion: observacion,
                deletedAt: deletedAt,
                updatedAt: updatedAt,
                revision: revision,
                syncStatus: syncStatus,
                syncError: syncError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BancoMovimientosTable, LocalMovimiento>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $BancoMovimientosTable,
                    LocalMovimiento
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BancoMovimientosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BancoMovimientosTable,
      LocalMovimiento,
      $$BancoMovimientosTableFilterComposer,
      $$BancoMovimientosTableOrderingComposer,
      $$BancoMovimientosTableAnnotationComposer,
      $$BancoMovimientosTableCreateCompanionBuilder,
      $$BancoMovimientosTableUpdateCompanionBuilder,
      (
        LocalMovimiento,
        BaseReferences<_$AppDatabase, $BancoMovimientosTable, LocalMovimiento>,
      ),
      LocalMovimiento,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FichadasTableTableManager get fichadas =>
      $$FichadasTableTableManager(_db, _db.fichadas);
  $$FeriadosTableTableManager get feriados =>
      $$FeriadosTableTableManager(_db, _db.feriados);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
  $$LocalPhotosTableTableManager get localPhotos =>
      $$LocalPhotosTableTableManager(_db, _db.localPhotos);
  $$TiposDocumentoGdeTableTableManager get tiposDocumentoGde =>
      $$TiposDocumentoGdeTableTableManager(_db, _db.tiposDocumentoGde);
  $$BancoMovimientosTableTableManager get bancoMovimientos =>
      $$BancoMovimientosTableTableManager(_db, _db.bancoMovimientos);
}
