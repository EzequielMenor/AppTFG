import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

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

/// Gestor de caché local para datos que no cambian frecuentemente.
/// Permite mostrar datos cacheados mientras se intenta cargar datos frescos del backend.
///
/// Soporta stale-while-revalidate vía [getStale] y [withStaleRevalidate].
class CacheManager {
  static const String _cacheKeyPrefix = 'gym_cache_';
  static const Duration _defaultCacheDuration = Duration(hours: 24);

  // ── Métodos originales (compatibilidad total) ──────────────────────

  static Future<void> setCache(
    String key,
    dynamic data, {
    Duration cacheDuration = _defaultCacheDuration,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expires': DateTime.now().add(cacheDuration).millisecondsSinceEpoch,
      };
      await prefs.setString('$_cacheKeyPrefix$key', jsonEncode(cacheData));
      debugPrint('[CacheManager] ✓ Cached: $key');
    } catch (e) {
      debugPrint('[CacheManager] ✗ Failed to cache $key: $e');
    }
  }

  static Future<dynamic> getCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('$_cacheKeyPrefix$key');

      if (cached == null) {
        debugPrint('[CacheManager] ✗ No cache found for: $key');
        return null;
      }

      final cacheData = jsonDecode(cached) as Map<String, dynamic>;
      final expiresAt = cacheData['expires'] as int;

      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        debugPrint('[CacheManager] ✗ Cache expired for: $key');
        await clearCache(key);
        return null;
      }

      debugPrint('[CacheManager] ✓ Cache hit for: $key');
      return cacheData['data'];
    } catch (e) {
      debugPrint('[CacheManager] ✗ Failed to get cache for $key: $e');
      return null;
    }
  }

  static Future<void> clearCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cacheKeyPrefix$key');
      debugPrint('[CacheManager] ✓ Cleared cache for: $key');
    } catch (e) {
      debugPrint('[CacheManager] ✗ Failed to clear cache for $key: $e');
    }
  }

  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_cacheKeyPrefix)) {
          await prefs.remove(key);
        }
      }
      debugPrint('[CacheManager] ✓ Cleared all cache');
    } catch (e) {
      debugPrint('[CacheManager] ✗ Failed to clear all cache: $e');
    }
  }

  // ── Stale-While-Revalidate ─────────────────────────────────────────

  /// Retorna la entrada de caché AUNQUE esté expirada.
  ///
  /// A diferencia de [getCache], este método **nunca borra** datos
  /// expirados — los retorna como [CacheEntry] para que el caller
  /// pueda mostrarlos inmediatamente mientras revalida en background.
  ///
  /// Retorna `null` si no existe absolutamente ningún dato para [key].
  static Future<CacheEntry<T>?> getStale<T>(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('$_cacheKeyPrefix$key');

      if (cached == null) {
        debugPrint('[CacheManager] ✗ No stale entry for: $key');
        return null;
      }

      final cacheData = jsonDecode(cached) as Map<String, dynamic>;
      final entry = CacheEntry<T>(
        data: cacheData['data'] as T?,
        timestamp: cacheData['timestamp'] as int,
        expiresAt: cacheData['expires'] as int,
      );

      if (entry.isExpired) {
        debugPrint(
          '[CacheManager] ⚠ Stale hit (expired ${entry.age.inMinutes}m ago): $key',
        );
      } else {
        debugPrint('[CacheManager] ✓ Fresh hit: $key');
      }

      return entry;
    } catch (e) {
      debugPrint('[CacheManager] ✗ Failed to get stale for $key: $e');
      return null;
    }
  }

  /// Patrón Stale-While-Revalidate.
  ///
  /// 1. Intenta leer del caché (fresco o stale).
  /// 2. Retorna inmediatamente los datos disponibles (pueden ser stale).
  /// 3. Si los datos están expirados o ausentes, ejecuta [fetch] en
  ///    background y actualiza el caché con la respuesta.
  /// 4. Retorna un [Future] que resuelve con los datos más recientes
  ///    disponibles — primero los stale, luego los frescos tras [fetch].
  ///
  /// [fetch]     — función async que obtiene datos del backend.
  /// [duration]  — tiempo de frescura del caché (default: 24h).
  /// [staleTolerance] — cuánto tiempo extra se acepta un stale antes
  ///                    de forzar un fetch sí o sí (default: 7 días).
  ///
  /// Retorna un [CacheEntry] con los datos y metadatos de expiración.
  /// El caller puede usar [CacheEntry.isExpired] para saber si los
  /// datos son frescos o stale.
  static Future<CacheEntry<T>> withStaleRevalidate<T>(
    String key,
    Future<T> Function() fetch, {
    Duration duration = _defaultCacheDuration,
    Duration staleTolerance = const Duration(days: 7),
  }) async {
    // 1. Leer lo que haya en caché (sin borrar)
    final stale = await getStale<T>(key);

    // 2. Si hay datos frescos, retornarlos directo
    if (stale != null && !stale.isExpired) {
      debugPrint('[CacheManager] SWR → fresh cache, no fetch: $key');
      return stale;
    }

    // 3. Determinar si ejecutamos fetch o retornamos stale
    final bool shouldFetch =
        stale == null || _isBeyondTolerance(stale, staleTolerance);

    if (shouldFetch) {
      // No hay datos o el stale supera la tolerancia — fetch obligatorio
      debugPrint(
        '[CacheManager] SWR → forcing fetch (no data or beyond tolerance): $key',
      );
      return _fetchAndCache<T>(key, fetch, duration);
    }

    // 4. Hay stale dentro de tolerancia — retornar stale + fetch en background
    debugPrint(
      '[CacheManager] SWR → returning stale, revalidating in background: $key',
    );
    // Fire-and-forget: actualiza caché sin bloquear al caller
    _fetchAndCache<T>(key, fetch, duration).catchError((e) {
      debugPrint('[CacheManager] SWR background fetch failed for $key: $e');
      // Retorna el stale como fallback
      return stale;
    });

    return stale;
  }

  /// Verifica si un [CacheEntry] excede la tolerancia de staleness.
  static bool _isBeyondTolerance(CacheEntry entry, Duration tolerance) {
    final staleAge = DateTime.now().millisecondsSinceEpoch - entry.expiresAt;
    return staleAge > tolerance.inMilliseconds;
  }

  /// Ejecuta [fetch], guarda en caché y retorna un [CacheEntry] fresco.
  static Future<CacheEntry<T>> _fetchAndCache<T>(
    String key,
    Future<T> Function() fetch,
    Duration duration,
  ) async {
    final data = await fetch();
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiresAt = now + duration.inMilliseconds;

    // Guardar en caché (reutiliza setCache existente)
    await setCache(key, data, cacheDuration: duration);

    debugPrint('[CacheManager] SWR → fetch complete, cached: $key');
    return CacheEntry<T>(data: data, timestamp: now, expiresAt: expiresAt);
  }
}
