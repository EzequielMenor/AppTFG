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

  @override
  Future<List<ExerciseModel>> getExercises() => _remote.getExercises();

  @override
  Future<List<ExerciseModel>> getExercisesFiltered({
    String? name,
    String? muscleGroup,
    String? equipment,
    int page = 0,
    int size = 20,
  }) => _remote.getExercisesFiltered(
    name: name,
    muscleGroup: muscleGroup,
    equipment: equipment,
    page: page,
    size: size,
  );

  @override
  Future<List<Progression1RMModel>> get1RMProgression(int exerciseId) =>
      _remote.get1RMProgression(exerciseId);

  // ── Period-dependent endpoints (con cache SWR) ───────────────────────────

  @override
  Future<AnalyticsSummaryModel> getSummary(DateTime from, DateTime to) {
    final fromUtc = from.toUtc().toIso8601String();
    final toUtc = to.toUtc().toIso8601String();
    return _swr<AnalyticsSummaryModel>(
      cacheKey: 'analytics_summary_${fromUtc}_$toUtc',
      fetch: () => _remote.getSummary(from, to),
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
      ttl: const Duration(minutes: 5),
    );
  }

  @override
  Future<List<WeeklyVolumeModel>> getWeeklyVolume(DateTime from, DateTime to) {
    final fromUtc = from.toUtc().toIso8601String();
    final toUtc = to.toUtc().toIso8601String();
    return _swr<List<WeeklyVolumeModel>>(
      cacheKey: 'analytics_weekly_volume_${fromUtc}_$toUtc',
      fetch: () => _remote.getWeeklyVolume(from, to),
      ttl: const Duration(minutes: 5),
    );
  }

  @override
  Future<List<MuscleDistributionModel>> getMuscleDistribution(
    DateTime from,
    DateTime to,
  ) {
    final fromUtc = from.toUtc().toIso8601String();
    final toUtc = to.toUtc().toIso8601String();
    return _swr<List<MuscleDistributionModel>>(
      cacheKey: 'analytics_muscle_distribution_${fromUtc}_$toUtc',
      fetch: () => _remote.getMuscleDistribution(from, to),
      ttl: const Duration(minutes: 5),
    );
  }

  @override
  Future<ConsistencyModel> getTrainingDays(DateTime from, DateTime to) {
    final fromUtc = from.toUtc().toIso8601String();
    final toUtc = to.toUtc().toIso8601String();
    return _swr<ConsistencyModel>(
      cacheKey: 'analytics_training_days_${fromUtc}_$toUtc',
      fetch: () => _remote.getTrainingDays(from, to),
      ttl: const Duration(minutes: 5),
    );
  }

  @override
  Future<DurationStatsModel> getDurationStats(DateTime from, DateTime to) {
    final fromUtc = from.toUtc().toIso8601String();
    final toUtc = to.toUtc().toIso8601String();
    return _swr<DurationStatsModel>(
      cacheKey: 'analytics_duration_stats_${fromUtc}_$toUtc',
      fetch: () => _remote.getDurationStats(from, to),
      ttl: const Duration(minutes: 5),
    );
  }

  @override
  Future<TrainingStyleModel> getTrainingStyle(DateTime from, DateTime to) {
    final fromUtc = from.toUtc().toIso8601String();
    final toUtc = to.toUtc().toIso8601String();
    return _swr<TrainingStyleModel>(
      cacheKey: 'analytics_training_style_${fromUtc}_$toUtc',
      fetch: () => _remote.getTrainingStyle(from, to),
      ttl: const Duration(minutes: 5),
    );
  }

  // ── Global endpoints (con cache SWR, TTL mayor) ──────────────────────────

  @override
  Future<List<TopExerciseModel>> getTopExercises({int limit = 5}) {
    return _swr<List<TopExerciseModel>>(
      cacheKey: 'analytics_top_exercises_$limit',
      fetch: () => _remote.getTopExercises(limit: limit),
      ttl: const Duration(minutes: 30),
    );
  }

  @override
  Future<VolumeDensityModel> getVolumeDensity() {
    return _swr<VolumeDensityModel>(
      cacheKey: 'analytics_volume_density',
      fetch: () => _remote.getVolumeDensity(),
      ttl: const Duration(minutes: 30),
    );
  }

  @override
  Future<WeeklyRhythmModel> getWeeklyRhythm() {
    return _swr<WeeklyRhythmModel>(
      cacheKey: 'analytics_weekly_rhythm',
      fetch: () => _remote.getWeeklyRhythm(),
      ttl: const Duration(minutes: 30),
    );
  }

  // ── SWR cache wrapper ────────────────────────────────────────────────────

  Future<T> _swr<T>({
    required String cacheKey,
    required Future<T> Function() fetch,
    required Duration ttl,
  }) async {
    final cached = await CacheManager.getStale<dynamic>(cacheKey);
    if (cached != null && cached.data != null) {
      debugPrint(
        cached.isExpired
            ? '[AnalyticsRepo] Stale HIT: $cacheKey'
            : '[AnalyticsRepo] Fresh HIT: $cacheKey',
      );
      unawaited(
        _fetchAndCache(fetch, cacheKey, ttl).then((_) {
          debugPrint('[AnalyticsRepo] Background refresh done: $cacheKey');
        }).catchError((e) {
          debugPrint('[AnalyticsRepo] Background refresh failed: $cacheKey: $e');
        }),
      );
      return _fromJson<T>(cached.data);
    }

    debugPrint('[AnalyticsRepo] Cache MISS: $cacheKey');
    return _fetchAndCache(fetch, cacheKey, ttl);
  }

  Future<T> _fetchAndCache<T>(
    Future<T> Function() fetch,
    String cacheKey,
    Duration ttl,
  ) async {
    try {
      final data = await fetch();
      await CacheManager.setCache(cacheKey, data, cacheDuration: ttl);
      return data;
    } catch (e) {
      debugPrint('[AnalyticsRepo] Fetch error for $cacheKey: $e');
      rethrow;
    }
  }

  T _fromJson<T>(dynamic data) {
    if (T == AnalyticsSummaryModel) {
      return AnalyticsSummaryModel.fromJson(
        data as Map<String, dynamic>,
      ) as T;
    }
    if (T == List<RecentPrModel>) {
      return (data as List<dynamic>)
          .map((e) => RecentPrModel.fromJson(e as Map<String, dynamic>))
          .toList() as T;
    }
    if (T == List<TopExerciseModel>) {
      return (data as List<dynamic>)
          .map((e) => TopExerciseModel.fromJson(e as Map<String, dynamic>))
          .toList() as T;
    }
    if (T == List<WeeklyVolumeModel>) {
      return (data as List<dynamic>)
          .map((e) => WeeklyVolumeModel.fromJson(e as Map<String, dynamic>))
          .toList() as T;
    }
    if (T == List<MuscleDistributionModel>) {
      return (data as List<dynamic>)
          .map(
            (e) => MuscleDistributionModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() as T;
    }
    if (T == ConsistencyModel) {
      return ConsistencyModel.fromJson(data as Map<String, dynamic>) as T;
    }
    if (T == DurationStatsModel) {
      return DurationStatsModel.fromJson(data as Map<String, dynamic>) as T;
    }
    if (T == TrainingStyleModel) {
      return TrainingStyleModel.fromJson(data as Map<String, dynamic>) as T;
    }
    if (T == VolumeDensityModel) {
      return VolumeDensityModel.fromJson(data as Map<String, dynamic>) as T;
    }
    if (T == WeeklyRhythmModel) {
      return WeeklyRhythmModel.fromJson(data as Map<String, dynamic>) as T;
    }
    throw Exception('Unknown type for _fromJson: $T');
  }
}
