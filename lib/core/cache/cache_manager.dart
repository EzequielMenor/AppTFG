import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'local_database.dart';
import 'drift_cache_store.dart';
import 'swr_cache.dart' as swr;

export 'swr_cache.dart' show CacheEntry, SwrCache;

/// Gestor de caché local con soporte stale-while-revalidate.
///
/// Backed by Drift/SQLite con migración automática desde SharedPreferences.
class CacheManager {
  static const String _cacheKeyPrefix = 'gym_cache_';
  static const Duration _defaultCacheDuration = Duration(hours: 24);

  static LocalDatabase? _db;
  static DriftCacheStore? _store;

  /// Inicializa la base de datos Drift. Debe llamarse una vez al inicio de la app.
  static Future<void> initialize() async {
    if (_db != null) return;
    final dir = await getApplicationDocumentsDirectory();
    final dbFile = p.join(dir.path, 'gym_cache.db');
    _db = LocalDatabase(NativeDatabase.createInBackground(File(dbFile)));
    _store = DriftCacheStore(_db!);
    await _migrateFromSharedPreferences();
  }

  /// Obtiene el store Drift (inicializa si es necesario).
  static Future<DriftCacheStore> _getStore() async {
    if (_store == null) await initialize();
    return _store!;
  }

  // ── Métodos originales (compatibilidad total) ──────────────────────

  static Future<void> setCache(
    String key,
    dynamic data, {
    Duration cacheDuration = _defaultCacheDuration,
  }) async {
    final store = await _getStore();
    await store.put(key, data, ttl: cacheDuration);
  }

  static Future<dynamic> getCache(String key) async {
    final store = await _getStore();
    return store.get(key);
  }

  static Future<void> clearCache(String key) async {
    final store = await _getStore();
    await store.remove(key);
  }

  static Future<void> clearAllCache() async {
    final store = await _getStore();
    await store.removeAll();
  }

  // ── Stale-While-Revalidate ─────────────────────────────────────────

  static Future<swr.CacheEntry<T>?> getStale<T>(String key) async {
    final store = await _getStore();
    final entry = await store.getStale(key);
    if (entry == null) return null;
    return swr.CacheEntry<T>(
      data: entry.data as T?,
      timestamp: entry.timestamp,
      expiresAt: entry.expiresAt,
    );
  }

  static Future<swr.CacheEntry<T>> withStaleRevalidate<T>(
    String key,
    Future<T> Function() fetch, {
    Duration duration = _defaultCacheDuration,
    Duration staleTolerance = const Duration(days: 7),
  }) async {
    final store = await _getStore();
    final cache = swr.SwrCache<T>(store);
    return cache.withStaleRevalidate(
      key,
      fetch,
      ttl: duration,
      staleTolerance: staleTolerance,
    );
  }

  // ── Migración desde SharedPreferences ──────────────────────────────

  static const String _migrationKey = 'gym_cache_migration_done';

  static Future<void> _migrateFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_migrationKey) == true) {
        debugPrint('[CacheManager] Migration already done');
        return;
      }

      final keys = prefs.getKeys().where((k) => k.startsWith(_cacheKeyPrefix));
      if (keys.isEmpty) {
        await prefs.setBool(_migrationKey, true);
        debugPrint('[CacheManager] No SharedPreferences cache to migrate');
        return;
      }

      int migrated = 0;
      int skipped = 0;

      for (final spKey in keys) {
        try {
          final cached = prefs.getString(spKey);
          if (cached == null) {
            skipped++;
            continue;
          }

          final cacheData = jsonDecode(cached) as Map<String, dynamic>;
          final cacheKey = spKey.substring(_cacheKeyPrefix.length);
          final data = cacheData['data'];
          final timestamp = cacheData['timestamp'] as int;
          final expires = cacheData['expires'] as int;

          await _store!.put(
            cacheKey,
            data,
            ttl: Duration(milliseconds: expires - timestamp),
          );
          await prefs.remove(spKey);
          migrated++;
        } catch (e) {
          debugPrint('[CacheManager] ⚠ Failed to migrate $spKey: $e');
          skipped++;
        }
      }

      await prefs.setBool(_migrationKey, true);
      debugPrint('[CacheManager] ✓ Migration complete: $migrated migrated, $skipped skipped');
    } catch (e) {
      debugPrint('[CacheManager] ✗ Migration failed: $e');
    }
  }

  // ── Cleanup ────────────────────────────────────────────────────────

  /// Cierra la conexión a la base de datos.
  static Future<void> close() async {
    await _db?.close();
    _db = null;
    _store = null;
  }
}
