import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;

import '../../../../core/cache/cache_manager.dart';
import '../../../../core/network/api_client.dart';
import '../models/analytics_models.dart';

class AnalyticsDatasource {
  /// Obtiene todos los ejercicios disponibles en el sistema.
  Future<List<ExerciseModel>> getExercises() async {
    final response = await ApiClient.get(
      '/api/exercises',
      queryParams: {'size': '200'},
    );
    if (response.statusCode != 200) {
      throw Exception('Error al cargar ejercicios: ${response.statusCode}');
    }
    final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
    return data
        .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Busca ejercicios con filtros opcionales y paginación.
  Future<List<ExerciseModel>> getExercisesFiltered({
    String? name,
    String? muscleGroup,
    String? equipment,
    int page = 0,
    int size = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
      if (name != null && name.isNotEmpty) 'name': name,
      'muscleGroup': ?muscleGroup,
      'equipment': ?equipment,
    };
    final response = await ApiClient.get('/api/exercises', queryParams: params);
    if (response.statusCode != 200) {
      throw Exception('Error al buscar ejercicios: ${response.statusCode}');
    }
    final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
    return data
        .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Devuelve la progresión de 1RM estimado para [exerciseId].
  Future<List<Progression1RMModel>> get1RMProgression(int exerciseId) async {
    try {
      final response = await ApiClient.get(
        '/api/v1/analytics/1rm-progression',
        queryParams: {'exerciseId': exerciseId.toString()},
      );

      if (response.statusCode != 200) {
        return [];
      }

      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data
          .map((e) => Progression1RMModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<AnalyticsSummaryModel> getSummary(DateTime from, DateTime to) async {
    try {
      final response = await ApiClient.get(
        '/api/v1/analytics/summary',
        queryParams: {
          'from': from.toUtc().toIso8601String(),
          'to': to.toUtc().toIso8601String(),
        },
      );

      if (response.statusCode != 200) {
        return const AnalyticsSummaryModel(sessionCount: 0, totalVolume: 0);
      }

      return AnalyticsSummaryModel.fromJson(
        json.decode(utf8.decode(response.bodyBytes)),
      );
    } catch (_) {
      return const AnalyticsSummaryModel(sessionCount: 0, totalVolume: 0);
    }
  }

  Future<List<RecentPrModel>> getRecentPRs(DateTime from, DateTime to) async {
    try {
      final response = await ApiClient.get(
        '/api/v1/analytics/recent-prs',
        queryParams: {
          'from': from.toUtc().toIso8601String(),
          'to': to.toUtc().toIso8601String(),
        },
      );

      if (response.statusCode != 200) {
        return [];
      }

      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data
          .map((e) => RecentPrModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<TopExerciseModel>> getTopExercises({int limit = 5}) async {
    try {
      final response = await ApiClient.get(
        '/api/v1/analytics/top-exercises',
        queryParams: {'limit': limit.toString()},
      );

      if (response.statusCode != 200) {
        return [];
      }

      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data
          .map((e) => TopExerciseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<WeeklyVolumeModel>> getWeeklyVolume(
    DateTime from,
    DateTime to,
  ) async {
    try {
      final response = await ApiClient.get(
        '/api/v1/analytics/weekly-volume',
        queryParams: {
          'from': from.toUtc().toIso8601String(),
          'to': to.toUtc().toIso8601String(),
        },
      );

      if (response.statusCode != 200) {
        return [];
      }

      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data
          .map((e) => WeeklyVolumeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<MuscleDistributionModel>> getMuscleDistribution(
    DateTime from,
    DateTime to,
  ) async {
    try {
      final response = await ApiClient.get(
        '/api/v1/analytics/muscle-distribution',
        queryParams: {
          'from': from.toUtc().toIso8601String(),
          'to': to.toUtc().toIso8601String(),
        },
      );

      if (response.statusCode != 200) {
        return [];
      }

      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data
          .map(
            (e) => MuscleDistributionModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<ConsistencyModel> getTrainingDays(DateTime from, DateTime to) async {
    try {
      final response = await ApiClient.get(
        '/api/v1/analytics/training-days',
        queryParams: {
          'from': from.toUtc().toIso8601String(),
          'to': to.toUtc().toIso8601String(),
        },
      );

      if (response.statusCode != 200) {
        return const ConsistencyModel(
          currentStreak: 0,
          bestStreak: 0,
          avgDaysPerWeek: 0.0,
          trainingDays: [],
        );
      }

      return ConsistencyModel.fromJson(
        json.decode(utf8.decode(response.bodyBytes)),
      );
    } catch (_) {
      return const ConsistencyModel(
        currentStreak: 0,
        bestStreak: 0,
        avgDaysPerWeek: 0.0,
        trainingDays: [],
      );
    }
  }

  Future<DurationStatsModel> getDurationStats(
    DateTime from,
    DateTime to,
  ) async {
    try {
      final response = await ApiClient.get(
        '/api/v1/analytics/duration-stats',
        queryParams: {
          'from': from.toUtc().toIso8601String(),
          'to': to.toUtc().toIso8601String(),
        },
      );

      if (response.statusCode != 200) {
        return const DurationStatsModel(avgMinutes: 0, longestMinutes: 0);
      }

      return DurationStatsModel.fromJson(
        json.decode(utf8.decode(response.bodyBytes)),
      );
    } catch (_) {
      return const DurationStatsModel(avgMinutes: 0, longestMinutes: 0);
    }
  }

  // ── EZE-168 ────────────────────────────────────────────────────────────────

  Future<VolumeDensityModel> getVolumeDensity() async {
    try {
      final response = await ApiClient.get('/api/v1/analytics/volume-density');
      if (response.statusCode != 200) {
        return const VolumeDensityModel(
          currentDensity: 0,
          previousDensity: 0,
          changePercent: 0,
        );
      }
      return VolumeDensityModel.fromJson(
        json.decode(utf8.decode(response.bodyBytes)),
      );
    } catch (_) {
      return const VolumeDensityModel(
        currentDensity: 0,
        previousDensity: 0,
        changePercent: 0,
      );
    }
  }

  Future<TrainingStyleModel> getTrainingStyle(
    DateTime from,
    DateTime to,
  ) async {
    try {
      final response = await ApiClient.get(
        '/api/v1/analytics/training-style',
        queryParams: {
          'from': from.toUtc().toIso8601String(),
          'to': to.toUtc().toIso8601String(),
        },
      );
      if (response.statusCode != 200) {
        return const TrainingStyleModel(
          strengthSets: 0,
          hypertrophySets: 0,
          enduranceSets: 0,
        );
      }
      return TrainingStyleModel.fromJson(
        json.decode(utf8.decode(response.bodyBytes)),
      );
    } catch (_) {
      return const TrainingStyleModel(
        strengthSets: 0,
        hypertrophySets: 0,
        enduranceSets: 0,
      );
    }
  }

  Future<WeeklyRhythmModel> getWeeklyRhythm() async {
    try {
      final response = await ApiClient.get('/api/v1/analytics/weekly-rhythm');
      if (response.statusCode != 200) {
        return const WeeklyRhythmModel(
          sessionsByDayOfWeek: [0, 0, 0, 0, 0, 0, 0],
        );
      }
      return WeeklyRhythmModel.fromJson(
        json.decode(utf8.decode(response.bodyBytes)),
      );
    } catch (_) {
      return const WeeklyRhythmModel(
        sessionsByDayOfWeek: [0, 0, 0, 0, 0, 0, 0],
      );
    }
  }

  // ── EZE-169 ────────────────────────────────────────────────────────────────

  Future<ExerciseTrendModel> getExerciseTrend(int exerciseId) async {
    try {
      final response = await ApiClient.get(
        '/api/v1/analytics/exercise/$exerciseId/trend',
      );
      if (response.statusCode != 200) {
        return const ExerciseTrendModel(status: 'NEW', seed: '');
      }
      return ExerciseTrendModel.fromJson(
        json.decode(utf8.decode(response.bodyBytes)),
      );
    } catch (_) {
      return const ExerciseTrendModel(status: 'NEW', seed: '');
    }
  }

  // ── Stale-While-Revalidate cache wrapper ─────────────────────────────

  /// Ejecuta una llamada API con caché SWR.
  /// Si hay cache hit → devuelve datos cacheados inmediatamente + refresco en background.
  /// Si cache miss → fetch síncrono, cachea y devuelve.
  Future<T> _swr<T>({
    required String cacheKey,
    required String endpoint,
    Map<String, String>? queryParams,
    required T Function(dynamic json) fromJson,
    required T defaultValue,
    required Duration ttl,
  }) async {
    // 1. Intentar leer del cache
    final cached = await CacheManager.getCache(cacheKey);
    if (cached != null) {
      debugPrint('[AnalyticsSWR] Cache HIT: $cacheKey');
      // Refresco en background sin bloquear
      unawaited(
        _fetchAndCache(
          endpoint,
          queryParams,
          fromJson,
          defaultValue,
          cacheKey,
          ttl,
        ).catchError((_) => defaultValue),
      );
      return fromJson(cached);
    }

    // 2. Cache miss → fetch síncrono
    debugPrint('[AnalyticsSWR] Cache MISS: $cacheKey');
    return _fetchAndCache(
      endpoint,
      queryParams,
      fromJson,
      defaultValue,
      cacheKey,
      ttl,
    );
  }

  /// Fetch real + guardar en cache. Usado tanto para cache miss como para background refresh.
  Future<T> _fetchAndCache<T>(
    String endpoint,
    Map<String, String>? queryParams,
    T Function(dynamic json) fromJson,
    T defaultValue,
    String cacheKey,
    Duration ttl,
  ) async {
    try {
      final response = await ApiClient.get(endpoint, queryParams: queryParams);
      if (response.statusCode != 200) return defaultValue;
      final data = json.decode(utf8.decode(response.bodyBytes));
      // Guardar en cache con TTL
      await CacheManager.setCache(cacheKey, data, cacheDuration: ttl);
      return fromJson(data);
    } catch (e) {
      debugPrint('[AnalyticsSWR] Fetch error for $cacheKey: $e');
      return defaultValue;
    }
  }

  // ── Cached methods (TTL 5 min — dependen del período) ────────────────

  Future<AnalyticsSummaryModel> getSummaryCached(DateTime from, DateTime to) {
    final fromUtc = from.toUtc().toIso8601String();
    final toUtc = to.toUtc().toIso8601String();
    return _swr<AnalyticsSummaryModel>(
      cacheKey: 'analytics_summary_${fromUtc}_$toUtc',
      endpoint: '/api/v1/analytics/summary',
      queryParams: {'from': fromUtc, 'to': toUtc},
      fromJson: (j) =>
          AnalyticsSummaryModel.fromJson(j as Map<String, dynamic>),
      defaultValue: const AnalyticsSummaryModel(
        sessionCount: 0,
        totalVolume: 0,
      ),
      ttl: const Duration(minutes: 5),
    );
  }

  Future<List<RecentPrModel>> getRecentPRsCached(DateTime from, DateTime to) {
    final fromUtc = from.toUtc().toIso8601String();
    final toUtc = to.toUtc().toIso8601String();
    return _swr<List<RecentPrModel>>(
      cacheKey: 'analytics_recent_prs_${fromUtc}_$toUtc',
      endpoint: '/api/v1/analytics/recent-prs',
      queryParams: {'from': fromUtc, 'to': toUtc},
      fromJson: (j) => (j as List<dynamic>)
          .map((e) => RecentPrModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      defaultValue: const <RecentPrModel>[],
      ttl: const Duration(minutes: 5),
    );
  }

  Future<List<WeeklyVolumeModel>> getWeeklyVolumeCached(
    DateTime from,
    DateTime to,
  ) {
    final fromUtc = from.toUtc().toIso8601String();
    final toUtc = to.toUtc().toIso8601String();
    return _swr<List<WeeklyVolumeModel>>(
      cacheKey: 'analytics_weekly_volume_${fromUtc}_$toUtc',
      endpoint: '/api/v1/analytics/weekly-volume',
      queryParams: {'from': fromUtc, 'to': toUtc},
      fromJson: (j) => (j as List<dynamic>)
          .map((e) => WeeklyVolumeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      defaultValue: const <WeeklyVolumeModel>[],
      ttl: const Duration(minutes: 5),
    );
  }

  // ── Cached methods (TTL 30 min — globales, sin dependencia de período) ─

  Future<List<TopExerciseModel>> getTopExercisesCached({int limit = 5}) {
    return _swr<List<TopExerciseModel>>(
      cacheKey: 'analytics_top_exercises_$limit',
      endpoint: '/api/v1/analytics/top-exercises',
      queryParams: {'limit': limit.toString()},
      fromJson: (j) => (j as List<dynamic>)
          .map((e) => TopExerciseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      defaultValue: const <TopExerciseModel>[],
      ttl: const Duration(minutes: 30),
    );
  }

  Future<VolumeDensityModel> getVolumeDensityCached() {
    return _swr<VolumeDensityModel>(
      cacheKey: 'analytics_volume_density',
      endpoint: '/api/v1/analytics/volume-density',
      queryParams: null,
      fromJson: (j) => VolumeDensityModel.fromJson(j as Map<String, dynamic>),
      defaultValue: const VolumeDensityModel(
        currentDensity: 0,
        previousDensity: 0,
        changePercent: 0,
      ),
      ttl: const Duration(minutes: 30),
    );
  }

  Future<WeeklyRhythmModel> getWeeklyRhythmCached() {
    return _swr<WeeklyRhythmModel>(
      cacheKey: 'analytics_weekly_rhythm',
      endpoint: '/api/v1/analytics/weekly-rhythm',
      queryParams: null,
      fromJson: (j) => WeeklyRhythmModel.fromJson(j as Map<String, dynamic>),
      defaultValue: const WeeklyRhythmModel(
        sessionsByDayOfWeek: [0, 0, 0, 0, 0, 0, 0],
      ),
      ttl: const Duration(minutes: 30),
    );
  }
}
