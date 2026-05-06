import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_analytics_mobile/features/analytics/data/models/analytics_models.dart';
import 'package:gym_analytics_mobile/features/analytics/domain/analytics_period.dart';
import 'package:gym_analytics_mobile/features/analytics/domain/analytics_repository.dart';
import 'package:gym_analytics_mobile/features/analytics/presentation/providers/analytics_provider.dart';

class _FakeAnalyticsRepository implements IAnalyticsRepository {
  final AnalyticsSummaryModel _summary;
  final List<RecentPrModel> _recentPRs;
  final List<TopExerciseModel> _topExercises;
  final List<WeeklyVolumeModel> _weeklyVolume;
  final List<MuscleDistributionModel> _muscleDistribution;
  final ConsistencyModel _consistency;
  final DurationStatsModel _durationStats;
  final VolumeDensityModel _volumeDensity;
  final TrainingStyleModel _trainingStyle;
  final WeeklyRhythmModel _weeklyRhythm;
  final Exception? _exception;

  _FakeAnalyticsRepository({
    AnalyticsSummaryModel? summary,
    List<RecentPrModel>? recentPRs,
    List<TopExerciseModel>? topExercises,
    List<WeeklyVolumeModel>? weeklyVolume,
    List<MuscleDistributionModel>? muscleDistribution,
    ConsistencyModel? consistency,
    DurationStatsModel? durationStats,
    VolumeDensityModel? volumeDensity,
    TrainingStyleModel? trainingStyle,
    WeeklyRhythmModel? weeklyRhythm,
    Exception? exception,
  })  : _summary = summary ??
            const AnalyticsSummaryModel(sessionCount: 0, totalVolume: 0),
        _recentPRs = recentPRs ?? const [],
        _topExercises = topExercises ?? const [],
        _weeklyVolume = weeklyVolume ?? const [],
        _muscleDistribution = muscleDistribution ?? const [],
        _consistency = consistency ??
            const ConsistencyModel(
              currentStreak: 0,
              bestStreak: 0,
              avgDaysPerWeek: 0,
              trainingDays: [],
            ),
        _durationStats = durationStats ??
            const DurationStatsModel(avgMinutes: 0, longestMinutes: 0),
        _volumeDensity = volumeDensity ??
            const VolumeDensityModel(
              currentDensity: 0,
              previousDensity: 0,
              changePercent: 0,
            ),
        _trainingStyle = trainingStyle ??
            const TrainingStyleModel(
              strengthSets: 0,
              hypertrophySets: 0,
              enduranceSets: 0,
            ),
        _weeklyRhythm = weeklyRhythm ??
            const WeeklyRhythmModel(
              sessionsByDayOfWeek: [0, 0, 0, 0, 0, 0, 0],
            ),
        _exception = exception;

  @override
  Future<AnalyticsSummaryModel> getSummary(DateTime from, DateTime to) async {
    if (_exception != null) throw _exception;
    return _summary;
  }

  @override
  Future<List<RecentPrModel>> getRecentPRs(DateTime from, DateTime to) async {
    if (_exception != null) throw _exception;
    return _recentPRs;
  }

  @override
  Future<List<TopExerciseModel>> getTopExercises({int limit = 5}) async {
    if (_exception != null) throw _exception;
    return _topExercises;
  }

  @override
  Future<List<WeeklyVolumeModel>> getWeeklyVolume(
    DateTime from,
    DateTime to,
  ) async {
    if (_exception != null) throw _exception;
    return _weeklyVolume;
  }

  @override
  Future<List<MuscleDistributionModel>> getMuscleDistribution(
    DateTime from,
    DateTime to,
  ) async {
    if (_exception != null) throw _exception;
    return _muscleDistribution;
  }

  @override
  Future<ConsistencyModel> getTrainingDays(DateTime from, DateTime to) async {
    if (_exception != null) throw _exception;
    return _consistency;
  }

  @override
  Future<DurationStatsModel> getDurationStats(
    DateTime from,
    DateTime to,
  ) async {
    if (_exception != null) throw _exception;
    return _durationStats;
  }

  @override
  Future<VolumeDensityModel> getVolumeDensity() async {
    if (_exception != null) throw _exception;
    return _volumeDensity;
  }

  @override
  Future<TrainingStyleModel> getTrainingStyle(
    DateTime from,
    DateTime to,
  ) async {
    if (_exception != null) throw _exception;
    return _trainingStyle;
  }

  @override
  Future<WeeklyRhythmModel> getWeeklyRhythm() async {
    if (_exception != null) throw _exception;
    return _weeklyRhythm;
  }

  @override
  Future<List<ExerciseModel>> getExercises() async {
    if (_exception != null) throw _exception;
    return const [];
  }

  @override
  Future<List<ExerciseModel>> getExercisesFiltered({
    String? name,
    String? muscleGroup,
    String? equipment,
    int page = 0,
    int size = 20,
  }) async {
    if (_exception != null) throw _exception;
    return const [];
  }

  @override
  Future<List<Progression1RMModel>> get1RMProgression(int exerciseId) async {
    if (_exception != null) throw _exception;
    return const [];
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AnalyticsProvider', () {
    test('loadInitial() → campos de datos pueblan con valores del fake',
        () async {
      final repo = _FakeAnalyticsRepository(
        summary: const AnalyticsSummaryModel(sessionCount: 5, totalVolume: 1000),
        recentPRs: [
          RecentPrModel(
            exerciseName: 'Bench',
            maxWeight: 100,
            date: DateTime(2024, 1, 1),
          ),
        ],
        topExercises: [
          const TopExerciseModel(rank: 1, exerciseName: 'Squat', best1Rm: 150),
        ],
        weeklyVolume: [
          WeeklyVolumeModel(
            weekStart: DateTime(2024, 1, 1),
            totalVolume: 500,
          ),
        ],
        muscleDistribution: [
          const MuscleDistributionModel(
            muscleGroup: 'Chest',
            sets: 10,
            percentage: 50,
          ),
        ],
        consistency: const ConsistencyModel(
          currentStreak: 3,
          bestStreak: 10,
          avgDaysPerWeek: 4,
          trainingDays: [],
        ),
        durationStats: const DurationStatsModel(
          avgMinutes: 60,
          longestMinutes: 90,
        ),
        volumeDensity: const VolumeDensityModel(
          currentDensity: 10,
          previousDensity: 8,
          changePercent: 25,
        ),
        trainingStyle: const TrainingStyleModel(
          strengthSets: 5,
          hypertrophySets: 10,
          enduranceSets: 2,
        ),
        weeklyRhythm: const WeeklyRhythmModel(
          sessionsByDayOfWeek: [1, 2, 3, 0, 0, 0, 0],
        ),
      );
      final provider = AnalyticsProvider(repository: repo);

      provider.loadInitial();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.summary?.sessionCount, 5);
      expect(provider.recentPRs.length, 1);
      expect(provider.topExercises.first.exerciseName, 'Squat');
      expect(provider.weeklyVolume.first.totalVolume, 500);
      expect(provider.muscleDistribution.first.muscleGroup, 'Chest');
      expect(provider.consistency?.currentStreak, 3);
      expect(provider.durationStats?.avgMinutes, 60);
      expect(provider.volumeDensity?.currentDensity, 10);
      expect(provider.trainingStyle?.strengthSets, 5);
      expect(provider.weeklyRhythm?.sessionsByDayOfWeek, [1, 2, 3, 0, 0, 0, 0]);
    });

    test('changePeriod() → período cambia y datos se recargan', () async {
      final repo = _FakeAnalyticsRepository(
        summary: const AnalyticsSummaryModel(
          sessionCount: 1,
          totalVolume: 100,
        ),
      );
      final provider = AnalyticsProvider(repository: repo);

      provider.loadInitial();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.period, AnalyticsPeriod.oneMonth);
      expect(provider.hasLoadedOnce, true);

      provider.changePeriod(AnalyticsPeriod.threeMonths);
      expect(provider.period, AnalyticsPeriod.threeMonths);

      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.isLoading, false);
      expect(provider.hasLoadedOnce, true);
    });

    test('forceRefresh() → datos recargados', () async {
      final repo = _FakeAnalyticsRepository(
        summary: const AnalyticsSummaryModel(
          sessionCount: 3,
          totalVolume: 300,
        ),
      );
      final provider = AnalyticsProvider(repository: repo);

      await provider.forceRefresh();

      expect(provider.isLoading, false);
      expect(provider.summary?.sessionCount, 3);
      expect(provider.hasLoadedOnce, true);
    });

    test('Error en repo → _error no nulo, _isLoading=false', () async {
      final repo = _FakeAnalyticsRepository(
        exception: Exception('Boom'),
      );
      final provider = AnalyticsProvider(repository: repo);

      await provider.forceRefresh();

      expect(provider.isLoading, false);
      expect(provider.error, isNotNull);
      expect(provider.error, 'Error al cargar las analíticas');
    });
  });
}
