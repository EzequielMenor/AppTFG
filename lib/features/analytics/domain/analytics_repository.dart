import '../data/models/analytics_models.dart';

abstract class IAnalyticsRepository {
  // Dashboard data
  Future<AnalyticsSummaryModel> getSummary(DateTime from, DateTime to);
  Future<List<RecentPrModel>> getRecentPRs(DateTime from, DateTime to);
  Future<List<TopExerciseModel>> getTopExercises({int limit = 5});
  Future<List<WeeklyVolumeModel>> getWeeklyVolume(DateTime from, DateTime to);
  Future<List<MuscleDistributionModel>> getMuscleDistribution(
    DateTime from,
    DateTime to,
  );
  Future<ConsistencyModel> getTrainingDays(DateTime from, DateTime to);
  Future<DurationStatsModel> getDurationStats(DateTime from, DateTime to);
  Future<VolumeDensityModel> getVolumeDensity();
  Future<TrainingStyleModel> getTrainingStyle(DateTime from, DateTime to);
  Future<WeeklyRhythmModel> getWeeklyRhythm();

  // Exercise data
  Future<List<ExerciseModel>> getExercises();
  Future<List<ExerciseModel>> getExercisesFiltered({
    String? name,
    String? muscleGroup,
    String? equipment,
    int page = 0,
    int size = 20,
  });
  Future<List<Progression1RMModel>> get1RMProgression(int exerciseId);
}
