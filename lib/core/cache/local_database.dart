import 'package:drift/drift.dart';

part 'local_database.g.dart';

/// Tabla de entradas de caché con soporte de TTL y compresión.
class CacheEntries extends Table {
  TextColumn get key => text()();
  BlobColumn get data => blob()();
  IntColumn get timestamp => integer()();
  IntColumn get expiresAt => integer()();
  BoolColumn get compressed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {key};
}

/// Base de datos local Drift para el caché offline.
///
/// Schema: cache_entries (key, data BLOB, timestamp, expires_at, compressed)
@DriftDatabase(tables: [CacheEntries])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
