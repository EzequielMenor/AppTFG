import 'package:flutter_test/flutter_test.dart';
import 'package:gym_analytics_mobile/features/analytics/data/models/analytics_models.dart';
import 'package:gym_analytics_mobile/features/analytics/domain/analytics_period.dart';
import 'package:gym_analytics_mobile/features/analytics/domain/analytics_repository.dart';
import 'package:gym_analytics_mobile/features/analytics/presentation/providers/exercise_detail_provider.dart';

class _FakeAnalyticsRepository implements IAnalyticsRepository {
  final List<Progression1RMModel> _progressionData;
  final Exception? _exception;

  _FakeAnalyticsRepository({
    List<Progression1RMModel>? progressionData,
    Exception? exception,
  })  : _progressionData = progressionData ?? [],
        _exception = exception;

  @override
  Future<AnalyticsSummaryModel> getSummary(DateTime from, DateTime to) async {
    throw UnimplementedError();
  }

  @override
  Future<List<RecentPrModel>> getRecentPRs(DateTime from, DateTime to) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TopExerciseModel>> getTopExercises({int limit = 5}) async {
    throw UnimplementedError();
  }

  @override
  Future<List<WeeklyVolumeModel>> getWeeklyVolume(
      DateTime from, DateTime to) async {
    throw UnimplementedError();
  }

  @override
  Future<List<MuscleDistributionModel>> getMuscleDistribution(
      DateTime from, DateTime to) async {
    throw UnimplementedError();
  }

  @override
  Future<ConsistencyModel> getTrainingDays(DateTime from, DateTime to) async {
    throw UnimplementedError();
  }

  @override
  Future<DurationStatsModel> getDurationStats(
      DateTime from, DateTime to) async {
    throw UnimplementedError();
  }

  @override
  Future<VolumeDensityModel> getVolumeDensity() async {
    throw UnimplementedError();
  }

  @override
  Future<TrainingStyleModel> getTrainingStyle(
      DateTime from, DateTime to) async {
    throw UnimplementedError();
  }

  @override
  Future<WeeklyRhythmModel> getWeeklyRhythm() async {
    throw UnimplementedError();
  }

  @override
  Future<List<ExerciseModel>> getExercises() async {
    throw UnimplementedError();
  }

  @override
  Future<List<ExerciseModel>> getExercisesFiltered({
    String? name,
    String? muscleGroup,
    String? equipment,
    int page = 0,
    int size = 20,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Progression1RMModel>> get1RMProgression(int exerciseId) async {
    if (_exception != null) throw _exception;
    return _progressionData;
  }
}

void main() {
  group('ExerciseDetailProvider', () {
    test('loadProgression con datos → isLoading=false, filteredData poblado, best1Rm correcto', () async {
      final data = [
        Progression1RMModel(date: DateTime(2024, 1, 1), estimated1Rm: 100.0),
        Progression1RMModel(date: DateTime(2024, 2, 1), estimated1Rm: 110.0),
        Progression1RMModel(date: DateTime(2024, 3, 1), estimated1Rm: 105.0),
      ];
      final repo = _FakeAnalyticsRepository(progressionData: data);
      final provider = ExerciseDetailProvider(repository: repo);

      expect(provider.isLoading, true);

      await provider.loadProgression(1);

      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.filteredData.length, 3);
      expect(provider.best1Rm, 110.0);
      expect(provider.totalEntries, 3);
    });

    test('loadProgression con excepción → error no nulo, isLoading=false', () async {
      final repo = _FakeAnalyticsRepository(
        exception: Exception('Network error'),
      );
      final provider = ExerciseDetailProvider(repository: repo);

      await provider.loadProgression(1);

      expect(provider.isLoading, false);
      expect(provider.error, isNotNull);
      expect(provider.error, 'No se pudo cargar la progresión.');
      expect(provider.filteredData, isEmpty);
    });

    test('changePeriod filtra correctamente sin network call', () async {
      final now = DateTime.now();
      final data = [
        Progression1RMModel(date: now.subtract(const Duration(days: 10)), estimated1Rm: 100.0),
        Progression1RMModel(date: now.subtract(const Duration(days: 40)), estimated1Rm: 90.0),
        Progression1RMModel(date: now.subtract(const Duration(days: 100)), estimated1Rm: 80.0),
      ];
      final repo = _FakeAnalyticsRepository(progressionData: data);
      final provider = ExerciseDetailProvider(repository: repo);

      await provider.loadProgression(1);
      expect(provider.filteredData.length, 3);

      provider.changePeriod(AnalyticsPeriod.oneMonth);
      expect(provider.filteredData.length, 1);
      expect(provider.filteredData.first.estimated1Rm, 100.0);

      provider.changePeriod(AnalyticsPeriod.threeMonths);
      expect(provider.filteredData.length, 2);
    });

    test('best1Rm y totalEntries se recalculan al cambiar período', () async {
      final now = DateTime.now();
      final data = [
        Progression1RMModel(date: now.subtract(const Duration(days: 5)), estimated1Rm: 120.0),
        Progression1RMModel(date: now.subtract(const Duration(days: 20)), estimated1Rm: 130.0),
        Progression1RMModel(date: now.subtract(const Duration(days: 50)), estimated1Rm: 110.0),
      ];
      final repo = _FakeAnalyticsRepository(progressionData: data);
      final provider = ExerciseDetailProvider(repository: repo);

      await provider.loadProgression(1);

      expect(provider.best1Rm, 130.0);
      expect(provider.totalEntries, 3);

      provider.changePeriod(AnalyticsPeriod.oneMonth);
      expect(provider.best1Rm, 130.0);
      expect(provider.totalEntries, 2);

      provider.changePeriod(AnalyticsPeriod.all);
      expect(provider.best1Rm, 130.0);
      expect(provider.totalEntries, 3);
    });
  });
}
