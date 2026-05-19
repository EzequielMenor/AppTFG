import 'package:flutter/material.dart';

import '../../../../core/cache/cache_manager.dart';
import '../../../../core/network/cancel_token.dart';
import '../../data/models/analytics_models.dart';
import '../../domain/analytics_period.dart';
import '../../domain/analytics_repository.dart';

/// ChangeNotifier que centraliza el estado de analíticas con SWR cache.
///
/// Optimización clave: distingue endpoints **globales** (independientes del período)
/// de los **dependientes del período**. Al cambiar período, solo se refrescan
/// los dependientes; los globales se revalidan en background sin bloquear UI.
class AnalyticsProvider extends ChangeNotifier {
  final IAnalyticsRepository _repository;

  AnalyticsProvider({required IAnalyticsRepository repository})
    : _repository = repository;

  // ── Estado público ───────────────────────────────────────────────────────

  AnalyticsPeriod _period = AnalyticsPeriod.oneMonth;
  bool _isLoading = true;
  String? _error;
  bool _isUsingStaleData = false;
  bool _hasLoadedOnce = false;
  bool _periodLoading = false;
  bool _globalsStale = false;
  CancelToken? _cancelToken;

  AnalyticsPeriod get period => _period;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isUsingStaleData => _isUsingStaleData;
  bool get hasLoadedOnce => _hasLoadedOnce;
  bool get periodLoading => _periodLoading;
  bool get globalsStale => _globalsStale;

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

  /// Cambia el período y recarga SOLO endpoints dependientes del período.
  /// Los globales se mantienen y se revalidan en background.
  void changePeriod(AnalyticsPeriod newPeriod) {
    if (_period == newPeriod) return;
    _period = newPeriod;

    // Cancelar request anterior si existe
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    final token = _cancelToken!;

    _periodLoading = true;
    _isUsingStaleData = true;
    notifyListeners();

    // Fetch solo period-dependent en paralelo
    _loadPeriodDependent(token);

    // Background revalidation de globales (fire-and-forget)
    _revalidateGlobalsInBackground();
  }

  // ── Métodos de acceso a datasource para screens específicas ──────────

  Future<List<ExerciseModel>> getExercises() => _repository.getExercises();

  Future<List<ExerciseModel>> getExercisesFiltered({
    String? name,
    String? muscleGroup,
    String? equipment,
    int page = 0,
    int size = 20,
  }) => _repository.getExercisesFiltered(
    name: name,
    muscleGroup: muscleGroup,
    equipment: equipment,
    page: page,
    size: size,
  );

  Future<List<Progression1RMModel>> get1RMProgression(int exerciseId) =>
      _repository.get1RMProgression(exerciseId);

  /// Fuerza refresco completo ignorando cache.
  Future<void> forceRefresh() async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    await _loadDataWithCache();
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
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
    _periodLoading = false;
    notifyListeners();
  }

  // ── Carga completa con SWR (primera carga) ──────────────────────────────

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
      // Period-dependent endpoints (fetch)
      final summary = await _repository.getSummary(range.from, range.to);
      final recentPRs = await _repository.getRecentPRs(range.from, range.to);
      final weeklyVolume = await _repository.getWeeklyVolume(
        range.from,
        range.to,
      );
      final previousWeeklyVolume = await _repository.getWeeklyVolume(
        prevFrom,
        prevTo,
      );
      final muscleDistribution = await _repository.getMuscleDistribution(
        range.from,
        range.to,
      );
      final consistency = await _repository.getTrainingDays(
        range.from,
        range.to,
      );
      final durationStats = await _repository.getDurationStats(
        range.from,
        range.to,
      );
      final trainingStyle = await _repository.getTrainingStyle(
        range.from,
        range.to,
      );

      // Global endpoints (fetch on initial load)
      final topExercises = await _repository.getTopExercises(limit: 5);
      final volumeDensity = await _repository.getVolumeDensity();
      final weeklyRhythm = await _repository.getWeeklyRhythm();

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
      _periodLoading = false;
      _hasLoadedOnce = true;
      notifyListeners();

      await _checkStaleState();
    } catch (e, st) {
      debugPrint('[AnalyticsProvider] Cache load error: $e\n$st');
      _handleError(e);
    }
  }

  // ── Fetch solo period-dependent endpoints ────────────────────────────────

  Future<void> _loadPeriodDependent(CancelToken token) async {
    final range = _period.dateRange();
    final duration = range.to.difference(range.from);
    final prevFrom = range.from.subtract(duration);
    final prevTo = range.from;

    try {
      final futures = Future.wait([
        _repository.getSummary(range.from, range.to),
        _repository.getRecentPRs(range.from, range.to),
        _repository.getWeeklyVolume(range.from, range.to),
        _repository.getWeeklyVolume(prevFrom, prevTo),
        _repository.getMuscleDistribution(range.from, range.to),
        _repository.getTrainingDays(range.from, range.to),
        _repository.getDurationStats(range.from, range.to),
        _repository.getTrainingStyle(range.from, range.to),
      ]);

      token.throwIfCancelled();
      final results = await futures;

      _summary = results[0] as AnalyticsSummaryModel;
      _recentPRs = results[1] as List<RecentPrModel>;
      _weeklyVolume = results[2] as List<WeeklyVolumeModel>;
      _previousWeeklyVolume = results[3] as List<WeeklyVolumeModel>;
      _muscleDistribution = results[4] as List<MuscleDistributionModel>;
      _consistency = results[5] as ConsistencyModel;
      _durationStats = results[6] as DurationStatsModel;
      _trainingStyle = results[7] as TrainingStyleModel;

      _periodLoading = false;
      notifyListeners();
    } catch (e) {
      if (e is RequestCancelledException) return;
      debugPrint('[AnalyticsProvider] Period load error: $e');
      _periodLoading = false;
      notifyListeners();
    }
  }

  // ── Background revalidation de endpoints globales ───────────────────────

  Future<void> _revalidateGlobalsInBackground() async {
    try {
      final futures = Future.wait([
        _repository.getTopExercises(limit: 5),
        _repository.getVolumeDensity(),
        _repository.getWeeklyRhythm(),
      ]);

      final results = await futures;
      _topExercises = results[0] as List<TopExerciseModel>;
      _volumeDensity = results[1] as VolumeDensityModel;
      _weeklyRhythm = results[2] as WeeklyRhythmModel;
      _globalsStale = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[AnalyticsProvider] Global revalidation error: $e');
      _globalsStale = true;
      notifyListeners();
    }
  }

  // ── Stale state check ───────────────────────────────────────────────────

  Future<void> _checkStaleState() async {
    final range = _period.dateRange();
    final fromUtc = range.from.toUtc().toIso8601String();
    final toUtc = range.to.toUtc().toIso8601String();

    final staleChecks = await Future.wait([
      CacheManager.getStale('analytics_summary_${fromUtc}_$toUtc'),
      CacheManager.getStale('analytics_recent_prs_${fromUtc}_$toUtc'),
      CacheManager.getStale('analytics_top_exercises_5'),
      CacheManager.getStale('analytics_weekly_volume_${fromUtc}_$toUtc'),
      CacheManager.getStale('analytics_training_days_${fromUtc}_$toUtc'),
      CacheManager.getStale('analytics_volume_density'),
      CacheManager.getStale('analytics_weekly_rhythm'),
    ]);

    _isUsingStaleData = staleChecks.any((entry) => entry?.isExpired == true);
    notifyListeners();

    Future.delayed(const Duration(seconds: 5), () async {
      final recheck = await Future.wait([
        CacheManager.getStale('analytics_summary_${fromUtc}_$toUtc'),
        CacheManager.getStale('analytics_weekly_volume_${fromUtc}_$toUtc'),
        CacheManager.getStale('analytics_training_days_${fromUtc}_$toUtc'),
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
