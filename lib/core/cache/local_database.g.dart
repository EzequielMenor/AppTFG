// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $CacheEntriesTable extends CacheEntries
    with TableInfo<$CacheEntriesTable, CacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<Uint8List> data = GeneratedColumn<Uint8List>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<int> expiresAt = GeneratedColumn<int>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _compressedMeta = const VerificationMeta(
    'compressed',
  );
  @override
  late final GeneratedColumn<bool> compressed = GeneratedColumn<bool>(
    'compressed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("compressed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    key,
    data,
    timestamp,
    expiresAt,
    compressed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheEntry> instance, {
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
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('compressed')) {
      context.handle(
        _compressedMeta,
        compressed.isAcceptableOrUnknown(data['compressed']!, _compressedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  CacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}data'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expires_at'],
      )!,
      compressed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}compressed'],
      )!,
    );
  }

  @override
  $CacheEntriesTable createAlias(String alias) {
    return $CacheEntriesTable(attachedDatabase, alias);
  }
}

class CacheEntry extends DataClass implements Insertable<CacheEntry> {
  final String key;
  final Uint8List data;
  final int timestamp;
  final int expiresAt;
  final bool compressed;
  const CacheEntry({
    required this.key,
    required this.data,
    required this.timestamp,
    required this.expiresAt,
    required this.compressed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['data'] = Variable<Uint8List>(data);
    map['timestamp'] = Variable<int>(timestamp);
    map['expires_at'] = Variable<int>(expiresAt);
    map['compressed'] = Variable<bool>(compressed);
    return map;
  }

  CacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return CacheEntriesCompanion(
      key: Value(key),
      data: Value(data),
      timestamp: Value(timestamp),
      expiresAt: Value(expiresAt),
      compressed: Value(compressed),
    );
  }

  factory CacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheEntry(
      key: serializer.fromJson<String>(json['key']),
      data: serializer.fromJson<Uint8List>(json['data']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      expiresAt: serializer.fromJson<int>(json['expiresAt']),
      compressed: serializer.fromJson<bool>(json['compressed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'data': serializer.toJson<Uint8List>(data),
      'timestamp': serializer.toJson<int>(timestamp),
      'expiresAt': serializer.toJson<int>(expiresAt),
      'compressed': serializer.toJson<bool>(compressed),
    };
  }

  CacheEntry copyWith({
    String? key,
    Uint8List? data,
    int? timestamp,
    int? expiresAt,
    bool? compressed,
  }) => CacheEntry(
    key: key ?? this.key,
    data: data ?? this.data,
    timestamp: timestamp ?? this.timestamp,
    expiresAt: expiresAt ?? this.expiresAt,
    compressed: compressed ?? this.compressed,
  );
  CacheEntry copyWithCompanion(CacheEntriesCompanion data) {
    return CacheEntry(
      key: data.key.present ? data.key.value : this.key,
      data: data.data.present ? data.data.value : this.data,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      compressed: data.compressed.present
          ? data.compressed.value
          : this.compressed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheEntry(')
          ..write('key: $key, ')
          ..write('data: $data, ')
          ..write('timestamp: $timestamp, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('compressed: $compressed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    key,
    $driftBlobEquality.hash(data),
    timestamp,
    expiresAt,
    compressed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheEntry &&
          other.key == this.key &&
          $driftBlobEquality.equals(other.data, this.data) &&
          other.timestamp == this.timestamp &&
          other.expiresAt == this.expiresAt &&
          other.compressed == this.compressed);
}

class CacheEntriesCompanion extends UpdateCompanion<CacheEntry> {
  final Value<String> key;
  final Value<Uint8List> data;
  final Value<int> timestamp;
  final Value<int> expiresAt;
  final Value<bool> compressed;
  final Value<int> rowid;
  const CacheEntriesCompanion({
    this.key = const Value.absent(),
    this.data = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.compressed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CacheEntriesCompanion.insert({
    required String key,
    required Uint8List data,
    required int timestamp,
    required int expiresAt,
    this.compressed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       data = Value(data),
       timestamp = Value(timestamp),
       expiresAt = Value(expiresAt);
  static Insertable<CacheEntry> custom({
    Expression<String>? key,
    Expression<Uint8List>? data,
    Expression<int>? timestamp,
    Expression<int>? expiresAt,
    Expression<bool>? compressed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (data != null) 'data': data,
      if (timestamp != null) 'timestamp': timestamp,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (compressed != null) 'compressed': compressed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CacheEntriesCompanion copyWith({
    Value<String>? key,
    Value<Uint8List>? data,
    Value<int>? timestamp,
    Value<int>? expiresAt,
    Value<bool>? compressed,
    Value<int>? rowid,
  }) {
    return CacheEntriesCompanion(
      key: key ?? this.key,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      expiresAt: expiresAt ?? this.expiresAt,
      compressed: compressed ?? this.compressed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (data.present) {
      map['data'] = Variable<Uint8List>(data.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<int>(expiresAt.value);
    }
    if (compressed.present) {
      map['compressed'] = Variable<bool>(compressed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheEntriesCompanion(')
          ..write('key: $key, ')
          ..write('data: $data, ')
          ..write('timestamp: $timestamp, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('compressed: $compressed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $CacheEntriesTable cacheEntries = $CacheEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [cacheEntries];
}

typedef $$CacheEntriesTableCreateCompanionBuilder =
    CacheEntriesCompanion Function({
      required String key,
      required Uint8List data,
      required int timestamp,
      required int expiresAt,
      Value<bool> compressed,
      Value<int> rowid,
    });
typedef $$CacheEntriesTableUpdateCompanionBuilder =
    CacheEntriesCompanion Function({
      Value<String> key,
      Value<Uint8List> data,
      Value<int> timestamp,
      Value<int> expiresAt,
      Value<bool> compressed,
      Value<int> rowid,
    });

class $$CacheEntriesTableFilterComposer
    extends Composer<_$LocalDatabase, $CacheEntriesTable> {
  $$CacheEntriesTableFilterComposer({
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

  ColumnFilters<Uint8List> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get compressed => $composableBuilder(
    column: $table.compressed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CacheEntriesTableOrderingComposer
    extends Composer<_$LocalDatabase, $CacheEntriesTable> {
  $$CacheEntriesTableOrderingComposer({
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

  ColumnOrderings<Uint8List> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get compressed => $composableBuilder(
    column: $table.compressed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CacheEntriesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $CacheEntriesTable> {
  $$CacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<Uint8List> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<bool> get compressed => $composableBuilder(
    column: $table.compressed,
    builder: (column) => column,
  );
}

class $$CacheEntriesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $CacheEntriesTable,
          CacheEntry,
          $$CacheEntriesTableFilterComposer,
          $$CacheEntriesTableOrderingComposer,
          $$CacheEntriesTableAnnotationComposer,
          $$CacheEntriesTableCreateCompanionBuilder,
          $$CacheEntriesTableUpdateCompanionBuilder,
          (
            CacheEntry,
            BaseReferences<_$LocalDatabase, $CacheEntriesTable, CacheEntry>,
          ),
          CacheEntry,
          PrefetchHooks Function()
        > {
  $$CacheEntriesTableTableManager(_$LocalDatabase db, $CacheEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CacheEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CacheEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<Uint8List> data = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
                Value<int> expiresAt = const Value.absent(),
                Value<bool> compressed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheEntriesCompanion(
                key: key,
                data: data,
                timestamp: timestamp,
                expiresAt: expiresAt,
                compressed: compressed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required Uint8List data,
                required int timestamp,
                required int expiresAt,
                Value<bool> compressed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheEntriesCompanion.insert(
                key: key,
                data: data,
                timestamp: timestamp,
                expiresAt: expiresAt,
                compressed: compressed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $CacheEntriesTable,
      CacheEntry,
      $$CacheEntriesTableFilterComposer,
      $$CacheEntriesTableOrderingComposer,
      $$CacheEntriesTableAnnotationComposer,
      $$CacheEntriesTableCreateCompanionBuilder,
      $$CacheEntriesTableUpdateCompanionBuilder,
      (
        CacheEntry,
        BaseReferences<_$LocalDatabase, $CacheEntriesTable, CacheEntry>,
      ),
      CacheEntry,
      PrefetchHooks Function()
    >;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$CacheEntriesTableTableManager get cacheEntries =>
      $$CacheEntriesTableTableManager(_db, _db.cacheEntries);
}
