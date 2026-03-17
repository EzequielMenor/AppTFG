import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

/// Gestor de caché local para datos que no cambian frecuentemente.
/// Permite mostrar datos cacheados mientras se intenta cargar datos frescos del backend.
class CacheManager {
  static const String _cacheKeyPrefix = 'gym_cache_';
  static const Duration _defaultCacheDuration = Duration(hours: 24);

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
      await prefs.setString(
        '$_cacheKeyPrefix$key',
        jsonEncode(cacheData),
      );
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
}
