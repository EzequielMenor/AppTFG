import 'dart:async' show unawaited;
import 'package:flutter/foundation.dart' show debugPrint;
import 'drift_cache_store.dart';

/// Entrada tipada de caché para soporte de stale-while-revalidate.
///
/// [data]       — datos almacenados (puede ser null si no hay caché)
/// [timestamp]  — cuándo se guardó (epoch ms)
/// [expiresAt]  — cuándo expira la frescura (epoch ms)
/// [isExpired]  — true si ya superó su tiempo de frescura
class CacheEntry<T> {
  final T? data;
  final int timestamp;
  final int expiresAt;

  const CacheEntry({
    required this.data,
    required this.timestamp,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;

  /// Edad del dato en cache.
  Duration get age =>
      Duration(milliseconds: DateTime.now().millisecondsSinceEpoch - timestamp);
}

/// Cache genérico con patrón Stale-While-Revalidate.
///
/// Respaldado por [DriftCacheStore] para persistencia SQLite.
class SwrCache<T> {
  final DriftCacheStore _store;

  SwrCache(this._store);

  /// Obtiene datos del caché. Retorna null si no existe o está expirado.
  Future<CacheEntry<T>?> get(String key, {bool forceFresh = false}) async {
    if (forceFresh) return null;
    final entry = await _store.getStale(key);
    if (entry == null) return null;
    return CacheEntry<T>(
      data: entry.data as T?,
      timestamp: entry.timestamp,
      expiresAt: entry.expiresAt,
    );
  }

  /// Guarda datos en caché con TTL.
  Future<void> set(String key, T data, Duration ttl) async {
    await _store.put(key, data, ttl: ttl);
  }

  /// Invalida una entrada específica.
  Future<void> invalidate(String key) async {
    await _store.remove(key);
  }

  /// Limpia todo el caché.
  Future<void> clear() async {
    await _store.removeAll();
  }

  /// Patrón Stale-While-Revalidate.
  ///
  /// 1. Retorna stale data inmediatamente si disponible.
  /// 2. Ejecuta [fetch] en background.
  /// 3. Actualiza caché con datos frescos.
  Future<CacheEntry<T>> withStaleRevalidate(
    String key,
    Future<T> Function() fetch, {
    Duration? ttl,
    Duration staleTolerance = const Duration(days: 7),
  }) async {
    final stale = await _store.getStale(key);

    // Si hay datos frescos, retornarlos directo
    if (stale != null && !stale.isExpired) {
      debugPrint('[SwrCache] → fresh cache, no fetch: $key');
      return CacheEntry<T>(
        data: stale.data as T?,
        timestamp: stale.timestamp,
        expiresAt: stale.expiresAt,
      );
    }

    // Determinar si fetch es obligatorio
    final shouldFetch = stale == null || _isBeyondTolerance(stale, staleTolerance);

    if (shouldFetch) {
      debugPrint('[SwrCache] → forcing fetch: $key');
      return _fetchAndCache(key, fetch, ttl);
    }

    // Retornar stale + fetch en background
    debugPrint('[SwrCache] → returning stale, revalidating: $key');
    final staleEntry = CacheEntry<T>(
      data: stale.data as T?,
      timestamp: stale.timestamp,
      expiresAt: stale.expiresAt,
    );
    unawaited(_fetchAndCache(key, fetch, ttl).catchError((e) {
      debugPrint('[SwrCache] background fetch failed for $key: $e');
      return staleEntry;
    }));

    return staleEntry;
  }

  bool _isBeyondTolerance(StaleCacheEntry entry, Duration tolerance) {
    final staleAge = DateTime.now().millisecondsSinceEpoch - entry.expiresAt;
    return staleAge > tolerance.inMilliseconds;
  }

  Future<CacheEntry<T>> _fetchAndCache(
    String key,
    Future<T> Function() fetch,
    Duration? ttl,
  ) async {
    final data = await fetch();
    final effectiveTtl = ttl ?? const Duration(hours: 24);
    await _store.put(key, data, ttl: effectiveTtl);
    final now = DateTime.now().millisecondsSinceEpoch;
    return CacheEntry<T>(
      data: data,
      timestamp: now,
      expiresAt: now + effectiveTtl.inMilliseconds,
    );
  }
}
