import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;

import '../../../../core/cache/cache_manager.dart';
import '../../domain/analytics_repository.dart';
import '../datasources/analytics_datasource.dart';
import '../models/analytics_models.dart';

class AnalyticsRepositoryImpl implements IAnalyticsRepository {
  final AnalyticsDatasource _remote;

  AnalyticsRepositoryImpl({required AnalyticsDatasource remote})
      : _remote = remote;

  // ── Sin cache ────────────────────────────────────────────────────────────

  @override
  Future<List<ExerciseModel>> getExercises() => _remote.getExercises();

  @override
  Future<List<ExerciseModel>> getExercisesFiltered({
    String? name,
    String? muscleGroup,
    String? equipment,
    int page = 0,
    int size = 20,
  }) =>
      _remote.getExercisesFiltered(
        name: name,
        muscleGroup: muscleGroup,
        equipment: equipment,
        page: page,
        size: size,
      );

  @override
  Future<List<Progression1RMModel>> get1RMProgression(int exerciseId) =>
      _remote.get1RMProgression(exerciseId);

  @override
  Future<List<MuscleDistributionModel>> getMuscleDistribution(
    DateTime from,
    DateTime to,
  ) =>
      _remote.getMuscleDistribution(from, to);

  @override
  Future<ConsistencyModel> getTrainingDays(DateTime from, DateTime to) =>
      _remote.getTrainingDays(from, to);

  @override
  Future<DurationStatsModel> getDurationStats(DateTime from, DateTime to) =>
      _remote.getDurationStats(from, to);

  @override
  Future<TrainingStyleModel> getTrainingStyle(DateTime from, DateTime to) =>
      _remote.getTrainingStyle(from, to);

  // ── Con cache — TTL 5 min ────────────────────────────────────────────────

  @override
  Future<AnalyticsSummaryModel> getSummary(DateTime from, DateTime to) {
    final fromUtc = from.toUtc().toIso8601String();
    final toUtc = to.toUtc().toIso8601String();
    return _swr<AnalyticsSummaryModel>(
      cacheKey: 'analytics_summary_${fromUtc}_$toUtc',
      fetch: () => _remote.getSummary(from, to),
      fromJson: (j) =>
          AnalyticsSummaryModel.fromJson(j as Map<String, dynamic>),
      defaultValue: const AnalyticsSummaryModel(
        sessionCount: 0,
        totalVolume: 0,
      ),
      ttl: const Duration(minutes: 5),
    );
  }

  @override
  Future<List<RecentPrModel>> getRecentPRs(DateTime from, DateTime to) {
    final fromUtc = from.toUtc().toIso8601String();
    final toUtc = to.toUtc().toIso8601String();
    return _swr<List<RecentPrModel>>(
      cacheKey: 'analytics_recent_prs_${fromUtc}_$toUtc',
      fetch: () => _remote.getRecentPRs(from, to),
      fromJson: (j) => (j as List<dynamic>)
          .map((e) => RecentPrModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      defaultValue: const <RecentPrModel>[],
      ttl: const Duration(minutes: 5),
    );
  }

  @override
  Future<List<TopExerciseModel>> getTopExercises({int limit = 5}) {
    return _swr<List<TopExerciseModel>>(
      cacheKey: 'analytics_top_exercises_$limit',
      fetch: () => _remote.getTopExercises(limit: limit),
      fromJson: (j) => (j as List<dynamic>)
          .map((e) => TopExerciseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      defaultValue: const <TopExerciseModel>[],
      ttl: const Duration(minutes: 5),
    );
  }

  @override
  Future<List<WeeklyVolumeModel>> getWeeklyVolume(
    DateTime from,
    DateTime to,
  ) {
    final fromUtc = from.toUtc().toIso8601String();
    final toUtc = to.toUtc().toIso8601String();
    return _swr<List<WeeklyVolumeModel>>(
      cacheKey: 'analytics_weekly_volume_${fromUtc}_$toUtc',
      fetch: () => _remote.getWeeklyVolume(from, to),
      fromJson: (j) => (j as List<dynamic>)
          .map((e) => WeeklyVolumeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      defaultValue: const <WeeklyVolumeModel>[],
      ttl: const Duration(minutes: 5),
    );
  }

  // ── Con cache — TTL 30 min ───────────────────────────────────────────────

  @override
  Future<VolumeDensityModel> getVolumeDensity() {
    return _swr<VolumeDensityModel>(
      cacheKey: 'analytics_volume_density',
      fetch: () => _remote.getVolumeDensity(),
      fromJson: (j) => VolumeDensityModel.fromJson(j as Map<String, dynamic>),
      defaultValue: const VolumeDensityModel(
        currentDensity: 0,
        previousDensity: 0,
        changePercent: 0,
      ),
      ttl: const Duration(minutes: 30),
    );
  }

  @override
  Future<WeeklyRhythmModel> getWeeklyRhythm() {
    return _swr<WeeklyRhythmModel>(
      cacheKey: 'analytics_weekly_rhythm',
      fetch: () => _remote.getWeeklyRhythm(),
      fromJson: (j) => WeeklyRhythmModel.fromJson(j as Map<String, dynamic>),
      defaultValue: const WeeklyRhythmModel(
        sessionsByDayOfWeek: [0, 0, 0, 0, 0, 0, 0],
      ),
      ttl: const Duration(minutes: 30),
    );
  }

  // ── Stale-While-Revalidate cache wrapper ─────────────────────────────

  /// Ejecuta una llamada API con caché SWR.
  /// Si hay cache hit → devuelve datos cacheados inmediatamente + refresco en background.
  /// Si cache miss → fetch síncrono, cachea y devuelve.
  Future<T> _swr<T>({
    required String cacheKey,
    required Future<T> Function() fetch,
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
          fetch,
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
      fetch,
      defaultValue,
      cacheKey,
      ttl,
    );
  }

  /// Fetch real + guardar en cache. Usado tanto para cache miss como para background refresh.
  Future<T> _fetchAndCache<T>(
    Future<T> Function() fetch,
    T defaultValue,
    String cacheKey,
    Duration ttl,
  ) async {
    try {
      final data = await fetch();
      // Guardar en cache con TTL
      await CacheManager.setCache(cacheKey, data, cacheDuration: ttl);
      return data;
    } catch (e) {
      debugPrint('[AnalyticsSWR] Fetch error for $cacheKey: $e');
      return defaultValue;
    }
  }
}
