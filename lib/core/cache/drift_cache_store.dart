import 'dart:convert';
import 'dart:io' show gzip;
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'local_database.dart';

/// Almacén de caché basado en Drift/SQLite.
///
/// Soporta:
/// - TTL con expiración por entrada
/// - Compresión gzip para payloads > 1KB
/// - Evicción LRU por timestamp (máx 2000 entradas / 50MB)
/// - Lectura stale (retorna datos expirados sin borrarlos)
class DriftCacheStore {
  final LocalDatabase _db;
  static const int _maxEntries = 2000;
  static const int _compressionThreshold = 1024; // 1KB

  DriftCacheStore(this._db);

  /// Guarda una entrada en caché con TTL opcional.
  Future<void> put(String key, dynamic data, {Duration? ttl}) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiresAt = now + (ttl ?? const Duration(hours: 24)).inMilliseconds;

      final bytes = _encodeData(data);
      final shouldCompress = bytes.length > _compressionThreshold;
      final storedBytes = shouldCompress ? gzip.encode(bytes) : bytes;

      await _db.into(_db.cacheEntries).insertOnConflictUpdate(
            CacheEntriesCompanion(
              key: Value(key),
              data: Value(Uint8List.fromList(storedBytes)),
              timestamp: Value(now),
              expiresAt: Value(expiresAt),
              compressed: Value(shouldCompress),
            ),
          );

      await _evictExpired();
      await _enforceEntryLimit();

      debugPrint('[DriftCacheStore] ✓ put: $key (${bytes.length} bytes, compressed: $shouldCompress)');
    } catch (e) {
      debugPrint('[DriftCacheStore] ✗ Failed to put $key: $e');
    }
  }

  /// Obtiene una entrada fresca. Retorna null si no existe o está expirada.
  Future<dynamic> get(String key) async {
    try {
      final entry = await (_db.select(_db.cacheEntries)
            ..where((t) => t.key.equals(key)))
          .getSingleOrNull();

      if (entry == null) return null;

      final now = DateTime.now().millisecondsSinceEpoch;
      if (now > entry.expiresAt) {
        await (_db.delete(_db.cacheEntries)..where((t) => t.key.equals(key))).go();
        debugPrint('[DriftCacheStore] ✗ Expired, deleted: $key');
        return null;
      }

      final data = _decodeData(entry.data, entry.compressed);
      debugPrint('[DriftCacheStore] ✓ get: $key');
      return data;
    } catch (e) {
      debugPrint('[DriftCacheStore] ✗ Failed to get $key: $e');
      return null;
    }
  }

  /// Obtiene una entrada stale (retorna incluso si está expirada).
  Future<StaleCacheEntry?> getStale(String key) async {
    try {
      final entry = await (_db.select(_db.cacheEntries)
            ..where((t) => t.key.equals(key)))
          .getSingleOrNull();

      if (entry == null) {
        debugPrint('[DriftCacheStore] ✗ No stale entry for: $key');
        return null;
      }

      final data = _decodeData(entry.data, entry.compressed);
      final cacheEntry = StaleCacheEntry(
        data: data,
        timestamp: entry.timestamp,
        expiresAt: entry.expiresAt,
      );

      if (cacheEntry.isExpired) {
        debugPrint('[DriftCacheStore] ⚠ Stale hit (expired ${cacheEntry.age.inMinutes}m ago): $key');
      } else {
        debugPrint('[DriftCacheStore] ✓ Fresh hit: $key');
      }

      return cacheEntry;
    } catch (e) {
      debugPrint('[DriftCacheStore] ✗ Failed to get stale for $key: $e');
      return null;
    }
  }

  /// Elimina una entrada por clave.
  Future<void> remove(String key) async {
    try {
      await (_db.delete(_db.cacheEntries)..where((t) => t.key.equals(key))).go();
      debugPrint('[DriftCacheStore] ✓ Removed: $key');
    } catch (e) {
      debugPrint('[DriftCacheStore] ✗ Failed to remove $key: $e');
    }
  }

  /// Elimina todas las entradas del caché.
  Future<void> removeAll() async {
    try {
      await _db.delete(_db.cacheEntries).go();
      debugPrint('[DriftCacheStore] ✓ Cleared all cache');
    } catch (e) {
      debugPrint('[DriftCacheStore] ✗ Failed to clear all: $e');
    }
  }

  /// Evicta las [count] entradas más antiguas por timestamp.
  Future<void> evict(int count) async {
    try {
      final oldest = await (_db.select(_db.cacheEntries)
            ..orderBy([(t) => OrderingTerm.asc(t.timestamp)])
            ..limit(count))
          .get();

      for (final entry in oldest) {
        await (_db.delete(_db.cacheEntries)..where((t) => t.key.equals(entry.key))).go();
      }
      debugPrint('[DriftCacheStore] ✓ Evicted $count entries');
    } catch (e) {
      debugPrint('[DriftCacheStore] ✗ Failed to evict: $e');
    }
  }

  // ── Internal helpers ────────────────────────────────────────────────

  Future<void> _evictExpired() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.delete(_db.cacheEntries)
          ..where((t) => t.expiresAt.isSmallerThanValue(now)))
        .go();
  }

  Future<void> _enforceEntryLimit() async {
    final all = await _db.select(_db.cacheEntries).get();
    if (all.length > _maxEntries) {
      await evict(all.length - _maxEntries);
    }
  }

  List<int> _encodeData(dynamic data) {
    if (data is String) return utf8.encode(data);
    return utf8.encode(jsonEncode(data));
  }

  dynamic _decodeData(Uint8List bytes, bool compressed) {
    final decoded = compressed ? gzip.decode(bytes) : bytes;
    final str = utf8.decode(decoded);
    try {
      return jsonDecode(str);
    } on FormatException {
      return str;
    }
  }
}

/// Entrada de caché para uso interno del store (sin genéricos).
class StaleCacheEntry {
  final dynamic data;
  final int timestamp;
  final int expiresAt;

  const StaleCacheEntry({
    required this.data,
    required this.timestamp,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;
  Duration get age =>
      Duration(milliseconds: DateTime.now().millisecondsSinceEpoch - timestamp);
}
