import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../../../../core/cache/cache_manager.dart';
import '../../data/datasources/analytics_datasource.dart';
import '../../data/models/analytics_models.dart';
import '../../domain/analytics_period.dart';

/// ChangeNotifier que centraliza el estado de analíticas con SWR cache.
///
/// Sigue el patrón de [AuthProvider]: estado privado + getters públicos,
/// helpers `_setLoading`/`_clearError`, `notifyListeners()` tras cambios.
///
/// Reemplaza el state + lógica SWR que actualmente vive en [AnalyticsScreen].
class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsDatasource _datasource;

  AnalyticsProvider({AnalyticsDatasource? datasource})
      : _datasource = datasource ?? AnalyticsDatasource();

  // ── Estado público ───────────────────────────────────────────────────────

  AnalyticsPeriod _period = AnalyticsPeriod.oneMonth;
  bool _isLoading = true;
  String? _error;
  bool _isUsingStaleData = false;
  bool _hasLoadedOnce = false;

  AnalyticsPeriod get period => _period;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isUsingStaleData => _isUsingStaleData;
  bool get hasLoadedOnce => _hasLoadedOnce;

  // Datos de analíticas
  AnalyticsSummaryModel? _summary;
  List<RecentPrModel> _recentPRs = [];
  List<TopExerciseModel> _topExercises = [];
  List<WeeklyVolumeModel> _weeklyVolume = [];
  List<WeeklyVolumeModel> _previousWeeklyVolume = [];
  List<MuscleDistributionModel> _muscleDistribution = [];
  ConsistencyModel? _consistency;
  DurationStatsModel? _durationStats;
  VolumeDensityModel? _volumeDensity;
  TrainingStyleModel? _trainingStyle;
  WeeklyRhythmModel? _weeklyRhythm;

  AnalyticsSummaryModel? get summary => _summary;
  List<RecentPrModel> get recentPRs => _recentPRs;
  List<TopExerciseModel> get topExercises => _topExercises;
  List<WeeklyVolumeModel> get weeklyVolume => _weeklyVolume;
  List<WeeklyVolumeModel> get previousWeeklyVolume => _previousWeeklyVolume;
  List<MuscleDistributionModel> get muscleDistribution => _muscleDistribution;
  ConsistencyModel? get consistency => _consistency;
  DurationStatsModel? get durationStats => _durationStats;
  VolumeDensityModel? get volumeDensity => _volumeDensity;
  TrainingStyleModel? get trainingStyle => _trainingStyle;
  WeeklyRhythmModel? get weeklyRhythm => _weeklyRhythm;

  // ── Inicialización ──────────────────────────────────────────────────────

  /// Carga inicial con SWR cache.
  void loadInitial() {
    _loadDataWithCache();
  }

  // ── Eventos públicos ─────────────────────────────────────────────────────

  /// Cambia el período y recarga datos con cache SWR.
  void changePeriod(AnalyticsPeriod newPeriod) {
    if (_period == newPeriod) return;
    _period = newPeriod;
    notifyListeners();
    _loadDataWithCache();
  }

  // ── Métodos de acceso a datasource para screens específicas ──────────

  /// Obtiene todos los ejercicios disponibles.
  Future<List<ExerciseModel>> getExercises() =>
      _datasource.getExercises();

  /// Busca ejercicios con filtros.
  Future<List<ExerciseModel>> getExercisesFiltered({
    String? name,
    String? muscleGroup,
    String? equipment,
    int page = 0,
    int size = 20,
  }) =>
      _datasource.getExercisesFiltered(
        name: name,
        muscleGroup: muscleGroup,
        equipment: equipment,
        page: page,
        size: size,
      );

  /// Obtiene la progresión 1RM de un ejercicio.
  Future<List<Progression1RMModel>> get1RMProgression(int exerciseId) =>
      _datasource.get1RMProgression(exerciseId);

  /// Fuerza refresco ignorando cache (pull-to-refresh).
  Future<void> forceRefresh() async {
    await CacheManager.clearAllCache();
    _hasLoadedOnce = false;
    await _loadAllData();
  }

  // ── Helpers internos ─────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _handleError(Object e) {
    debugPrint('[AnalyticsProvider] Error: $e');
    _error = 'Error al cargar las analíticas';
    _isLoading = false;
    notifyListeners();
  }

  // ── Carga pull-to-refresh (sin cache) ────────────────────────────────────

  Future<void> _loadAllData() async {
    _setLoading(true);
    _clearError();
    _isUsingStaleData = false;
    notifyListeners();

    final range = _period.dateRange();
    final duration = range.to.difference(range.from);
    final prevFrom = range.from.subtract(duration);
    final prevTo = range.from;

    try {
      final results = await Future.wait([
        _datasource.getSummary(range.from, range.to),
        _datasource.getRecentPRs(range.from, range.to),
        _datasource.getTopExercises(limit: 5),
        _datasource.getWeeklyVolume(range.from, range.to),
        _datasource.getWeeklyVolume(prevFrom, prevTo),
        _datasource.getMuscleDistribution(range.from, range.to),
        _datasource.getTrainingDays(range.from, range.to),
        _datasource.getDurationStats(range.from, range.to),
        _datasource.getVolumeDensity(),
        _datasource.getTrainingStyle(range.from, range.to),
        _datasource.getWeeklyRhythm(),
      ]);

      _summary = results[0] as AnalyticsSummaryModel;
      _recentPRs = results[1] as List<RecentPrModel>;
      _topExercises = results[2] as List<TopExerciseModel>;
      _weeklyVolume = results[3] as List<WeeklyVolumeModel>;
      _previousWeeklyVolume = results[4] as List<WeeklyVolumeModel>;
      _muscleDistribution = results[5] as List<MuscleDistributionModel>;
      _consistency = results[6] as ConsistencyModel;
      _durationStats = results[7] as DurationStatsModel;
      _volumeDensity = results[8] as VolumeDensityModel;
      _trainingStyle = results[9] as TrainingStyleModel;
      _weeklyRhythm = results[10] as WeeklyRhythmModel;

      _isLoading = false;
      _hasLoadedOnce = true;
      notifyListeners();
    } catch (e, st) {
      debugPrint('[AnalyticsProvider] Error loading all: $e\n$st');
      _handleError(e);
    }
  }

  // ── Carga con SWR cache (init + period change) ──────────────────────────

  Future<void> _loadDataWithCache() async {
    final hadData = _hasLoadedOnce;

    if (hadData) {
      _error = null;
      _isUsingStaleData = true;
      notifyListeners();
    } else {
      _setLoading(true);
      _clearError();
    }

    final range = _period.dateRange();
    final duration = range.to.difference(range.from);
    final prevFrom = range.from.subtract(duration);
    final prevTo = range.from;

    try {
      final summary = await _cachedOrFallback(
        () => _datasource.getSummaryCached(range.from, range.to),
        () => _datasource.getSummary(range.from, range.to),
      );
      final recentPRs = await _cachedOrFallback(
        () => _datasource.getRecentPRsCached(range.from, range.to),
        () => _datasource.getRecentPRs(range.from, range.to),
      );
      final topExercises = await _cachedOrFallback(
        () => _datasource.getTopExercisesCached(limit: 5),
        () => _datasource.getTopExercises(limit: 5),
      );
      final weeklyVolume = await _cachedOrFallback(
        () => _datasource.getWeeklyVolumeCached(range.from, range.to),
        () => _datasource.getWeeklyVolume(range.from, range.to),
      );
      final previousWeeklyVolume = await _cachedOrFallback(
        () => _datasource.getWeeklyVolumeCached(prevFrom, prevTo),
        () => _datasource.getWeeklyVolume(prevFrom, prevTo),
      );
      final volumeDensity = await _cachedOrFallback(
        () => _datasource.getVolumeDensityCached(),
        () => _datasource.getVolumeDensity(),
      );
      final weeklyRhythm = await _cachedOrFallback(
        () => _datasource.getWeeklyRhythmCached(),
        () => _datasource.getWeeklyRhythm(),
      );

      final muscleDistribution =
          await _datasource.getMuscleDistribution(range.from, range.to);
      final consistency =
          await _datasource.getTrainingDays(range.from, range.to);
      final durationStats =
          await _datasource.getDurationStats(range.from, range.to);
      final trainingStyle =
          await _datasource.getTrainingStyle(range.from, range.to);

      _summary = summary;
      _recentPRs = recentPRs;
      _topExercises = topExercises;
      _weeklyVolume = weeklyVolume;
      _previousWeeklyVolume = previousWeeklyVolume;
      _muscleDistribution = muscleDistribution;
      _consistency = consistency;
      _durationStats = durationStats;
      _volumeDensity = volumeDensity;
      _trainingStyle = trainingStyle;
      _weeklyRhythm = weeklyRhythm;
      _isLoading = false;
      _hasLoadedOnce = true;
      notifyListeners();

      await _checkStaleState();
    } catch (e, st) {
      debugPrint('[AnalyticsProvider] Cache load error: $e\n$st');
      _handleError(e);
    }
  }

  /// Intenta método cached; si falla, cae al método original.
  Future<T> _cachedOrFallback<T>(
    Future<T> Function() cachedFn,
    Future<T> Function() fallbackFn,
  ) async {
    try {
      return await cachedFn();
    } catch (e) {
      debugPrint('[AnalyticsProvider] Cached failed, using fallback: $e');
      return await fallbackFn();
    }
  }

  /// Verifica si hay datos stale y programa rechequeo del indicador.
  Future<void> _checkStaleState() async {
    final range = _period.dateRange();
    final fromUtc = range.from.toUtc().toIso8601String();
    final toUtc = range.to.toUtc().toIso8601String();

    final staleChecks = await Future.wait([
      CacheManager.getStale('analytics_summary_${fromUtc}_$toUtc'),
      CacheManager.getStale('analytics_recent_prs_${fromUtc}_$toUtc'),
      CacheManager.getStale('analytics_top_exercises_5'),
      CacheManager.getStale('analytics_volume_density'),
      CacheManager.getStale('analytics_weekly_rhythm'),
    ]);

    _isUsingStaleData = staleChecks.any((entry) => entry?.isExpired == true);
    notifyListeners();

    // Rechequeo a los 5s para limpiar indicador si ya refrescó
    Future.delayed(const Duration(seconds: 5), () async {
      final recheck = await Future.wait([
        CacheManager.getStale('analytics_summary_${fromUtc}_$toUtc'),
        CacheManager.getStale('analytics_volume_density'),
      ]);
      final stillStale = recheck.any((entry) => entry?.isExpired == true);
      if (_isUsingStaleData && !stillStale) {
        _isUsingStaleData = false;
        notifyListeners();
      }
    });
  }
}
