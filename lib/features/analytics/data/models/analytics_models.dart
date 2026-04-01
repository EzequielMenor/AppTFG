class ExerciseModel {
  final int id;
  final String name;
  final String? muscleGroup;
  final String? thumbnailUrl;
  final String? videoUrl;
  final List<String> aliases;

  const ExerciseModel({
    required this.id,
    required this.name,
    this.muscleGroup,
    this.thumbnailUrl,
    this.videoUrl,
    this.aliases = const [],
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) => ExerciseModel(
        id: json['id'] as int,
        name: json['name'] as String,
        muscleGroup: json['muscleGroup'] as String?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        videoUrl: json['videoUrl'] as String?,
        aliases: (json['aliases'] as List<dynamic>?)
                ?.whereType<String>()
                .toList() ??
            [],
      );

  bool matchesName(String query) {
    final q = normalize(query);
    if (normalize(name) == q) return true;
    return aliases.any((a) => normalize(a) == q);
  }

  static String normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('à', 'a')
        .replaceAll('è', 'e')
        .replaceAll('ì', 'i')
        .replaceAll('ò', 'o')
        .replaceAll('ù', 'u');
  }

  @override
  String toString() => name;
}

class Progression1RMModel {
  final DateTime date;
  final double estimated1Rm;

  const Progression1RMModel({required this.date, required this.estimated1Rm});

  factory Progression1RMModel.fromJson(Map<String, dynamic> json) =>
      Progression1RMModel(
        date: DateTime.parse(json['date'] as String),
        estimated1Rm: (json['estimated1Rm'] as num).toDouble(),
      );
}

class AnalyticsSummaryModel {
  final int sessionCount;
  final double totalVolume;

  const AnalyticsSummaryModel({required this.sessionCount, required this.totalVolume});

  factory AnalyticsSummaryModel.fromJson(Map<String, dynamic> json) =>
      AnalyticsSummaryModel(
        sessionCount: (json['sessionCount'] as num? ?? 0).toInt(),
        totalVolume: (json['totalVolume'] as num? ?? 0).toDouble(),
      );
}

class RecentPrModel {
  final String exerciseName;
  final double maxWeight;
  final DateTime date;

  const RecentPrModel({
    required this.exerciseName,
    required this.maxWeight,
    required this.date,
  });

  factory RecentPrModel.fromJson(Map<String, dynamic> json) => RecentPrModel(
        exerciseName: json['exerciseName'] as String,
        maxWeight: (json['estimated1Rm'] as num? ?? json['maxWeight'] as num? ?? 0).toDouble(),
        date: DateTime.parse(json['date'] as String),
      );
}

class TopExerciseModel {
  final int rank;
  final String exerciseName;
  final double best1Rm;

  const TopExerciseModel({
    required this.rank,
    required this.exerciseName,
    required this.best1Rm,
  });

  factory TopExerciseModel.fromJson(Map<String, dynamic> json) => TopExerciseModel(
        rank: json['rank'] as int,
        exerciseName: json['exerciseName'] as String,
        best1Rm: (json['best1Rm'] as num).toDouble(),
      );
}

class WeeklyVolumeModel {
  final DateTime weekStart;
  final double totalVolume;

  const WeeklyVolumeModel({required this.weekStart, required this.totalVolume});

  factory WeeklyVolumeModel.fromJson(Map<String, dynamic> json) =>
      WeeklyVolumeModel(
        weekStart: DateTime.parse(json['weekStart'] as String),
        totalVolume: (json['totalVolume'] as num? ?? 0).toDouble(),
      );
}

class MuscleDistributionModel {
  final String muscleGroup;
  final int sets;
  final double percentage;

  const MuscleDistributionModel({
    required this.muscleGroup,
    required this.sets,
    required this.percentage,
  });

  factory MuscleDistributionModel.fromJson(Map<String, dynamic> json) =>
      MuscleDistributionModel(
        muscleGroup: json['muscleGroup'] as String,
        sets: json['sets'] as int,
        percentage: (json['percentage'] as num).toDouble(),
      );
}

class ConsistencyModel {
  final int currentStreak;
  final int bestStreak;
  final double avgDaysPerWeek;
  final List<DateTime> trainingDays;

  const ConsistencyModel({
    required this.currentStreak,
    required this.bestStreak,
    required this.avgDaysPerWeek,
    required this.trainingDays,
  });

  factory ConsistencyModel.fromJson(Map<String, dynamic> json) {
    final trainingDays = (json['trainingDays'] as List)
        .map((d) => DateTime.parse(d as String))
        .toList();
    
    // avgDaysPerWeek is often calculated in client if needed, or taken from json if present
    // According to spec, it is calculated in client: trainingDays.length / (periodoEnDías / 7)
    // But for the model, we can just take it if provided or leave it to the screen.
    return ConsistencyModel(
      currentStreak: json['currentStreak'] as int,
      bestStreak: json['bestStreak'] as int,
      avgDaysPerWeek: (json['avgDaysPerWeek'] as num? ?? 0.0).toDouble(),
      trainingDays: trainingDays,
    );
  }
}

class DurationStatsModel {
  final int avgMinutes;
  final int longestMinutes;

  const DurationStatsModel({required this.avgMinutes, required this.longestMinutes});

  factory DurationStatsModel.fromJson(Map<String, dynamic> json) =>
      DurationStatsModel(
        avgMinutes: json['avgMinutes'] as int? ?? 0,
        longestMinutes: json['longestMinutes'] as int? ?? 0,
      );
}

// ── EZE-168 models ────────────────────────────────────────────────────────────

class VolumeDensityModel {
  final double currentDensity;
  final double previousDensity;
  final double changePercent;

  const VolumeDensityModel({
    required this.currentDensity,
    required this.previousDensity,
    required this.changePercent,
  });

  factory VolumeDensityModel.fromJson(Map<String, dynamic> json) =>
      VolumeDensityModel(
        currentDensity: (json['currentDensity'] as num? ?? 0).toDouble(),
        previousDensity: (json['previousDensity'] as num? ?? 0).toDouble(),
        changePercent: (json['changePercent'] as num? ?? 0).toDouble(),
      );
}

class TrainingStyleModel {
  final int strengthSets;
  final int hypertrophySets;
  final int enduranceSets;

  const TrainingStyleModel({
    required this.strengthSets,
    required this.hypertrophySets,
    required this.enduranceSets,
  });

  factory TrainingStyleModel.fromJson(Map<String, dynamic> json) =>
      TrainingStyleModel(
        strengthSets: (json['strengthSets'] as num? ?? 0).toInt(),
        hypertrophySets: (json['hypertrophySets'] as num? ?? 0).toInt(),
        enduranceSets: (json['enduranceSets'] as num? ?? 0).toInt(),
      );
}

class WeeklyRhythmModel {
  /// Length 7: index 0=Mon … 6=Sun
  final List<int> sessionsByDayOfWeek;

  const WeeklyRhythmModel({required this.sessionsByDayOfWeek});

  factory WeeklyRhythmModel.fromJson(Map<String, dynamic> json) {
    final raw = (json['sessionsByDayOfWeek'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        List.filled(7, 0);
    return WeeklyRhythmModel(sessionsByDayOfWeek: raw);
  }
}

// ── EZE-169 model ─────────────────────────────────────────────────────────────

class ExerciseTrendModel {
  /// NEW | OVERLOAD | STAGNANT | REGRESSION
  final String status;
  final String seed;

  const ExerciseTrendModel({required this.status, required this.seed});

  factory ExerciseTrendModel.fromJson(Map<String, dynamic> json) =>
      ExerciseTrendModel(
        status: json['status'] as String? ?? 'NEW',
        seed: json['seed'] as String? ?? '',
      );
}
