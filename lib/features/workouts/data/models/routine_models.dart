import '../../../analytics/data/models/analytics_models.dart';

// ── Routine Series Model ──────────────────────────────────────────────────────

class RoutineSeriesModel {
  final int setOrder;
  final double? targetWeight;
  final int? targetRepsMin;
  final int? targetRepsMax;

  const RoutineSeriesModel({
    required this.setOrder,
    this.targetWeight,
    this.targetRepsMin,
    this.targetRepsMax,
  });

  factory RoutineSeriesModel.fromJson(Map<String, dynamic> json) {
    return RoutineSeriesModel(
      setOrder: json['setOrder'] as int,
      targetWeight: (json['targetWeight'] as num?)?.toDouble(),
      targetRepsMin: json['targetRepsMin'] as int?,
      targetRepsMax: json['targetRepsMax'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'setOrder': setOrder,
    if (targetWeight != null) 'targetWeight': targetWeight,
    if (targetRepsMin != null) 'targetRepsMin': targetRepsMin,
    if (targetRepsMax != null) 'targetRepsMax': targetRepsMax,
  };

  String get displayText {
    final weight = targetWeight != null ? '${targetWeight}kg × ' : '';
    final reps = _repsRange();
    return weight + reps;
  }

  String _repsRange() {
    final min = targetRepsMin;
    final max = targetRepsMax;
    if (min == null && max == null) return '—';
    if (min == max) return '$min';
    if (min == null) return '≤$max';
    if (max == null) return '$min+';
    return '$min-$max';
  }
}

// ── Routine Exercise Model ────────────────────────────────────────────────────

// Parses a dynamic value into a List of Strings.
// Handles: List → filter strings, String → split by comma, null/other → [].
List<String> _parseStringList(dynamic value) {
  if (value == null) return [];
  if (value is List) return value.whereType<String>().toList();
  if (value is String) {
    return value
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
  return [];
}

class RoutineExerciseModel {
  final int id;
  final int exerciseId;
  final int exerciseOrder;
  final String exerciseName;
  final String? muscleGroup;
  final List<String> secondaryMuscles;
  final String? thumbnailUrl;
  final String? notes;
  final List<RoutineSeriesModel> series;

  const RoutineExerciseModel({
    required this.id,
    required this.exerciseId,
    required this.exerciseOrder,
    required this.exerciseName,
    this.muscleGroup,
    this.secondaryMuscles = const [],
    this.thumbnailUrl,
    this.notes,
    this.series = const [],
  });

  /// Cantidad de series (compatibilidad con código que esperaba targetSeries).
  int get targetSeries => series.isEmpty ? 0 : series.length;

  factory RoutineExerciseModel.fromJson(Map<String, dynamic> json) {
    // Parsear series: puede venir como lista de objetos o no existir.
    final rawSeries = json['series'] as List<dynamic>?;
    final series =
        rawSeries
            ?.map((s) => RoutineSeriesModel.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];

    // Fallback: si el backend sigue mandando targetSeries como int (legacy),
    // generar series vacías con el setOrder correspondiente.
    final legacyTarget = json['targetSeries'] as int?;
    final effectiveSeries = series.isNotEmpty
        ? series
        : (legacyTarget != null
              ? List.generate(
                  legacyTarget,
                  (i) => RoutineSeriesModel(setOrder: i + 1),
                )
              : <RoutineSeriesModel>[]);

    return RoutineExerciseModel(
      id: json['id'] as int,
      exerciseId: json['exerciseId'] as int,
      exerciseOrder: json['exerciseOrder'] as int,
      exerciseName: json['exerciseName'] as String,
      muscleGroup: json['muscleGroup'] as String?,
      secondaryMuscles: _parseStringList(json['secondaryMuscles']),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      notes: json['notes'] as String?,
      series: effectiveSeries,
    );
  }

  ExerciseModel toExerciseModel() {
    return ExerciseModel(
      id: exerciseId,
      name: exerciseName,
      muscleGroup: muscleGroup,
      secondaryMuscles: secondaryMuscles,
      thumbnailUrl: thumbnailUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'exerciseId': exerciseId,
    'exerciseOrder': exerciseOrder,
    'exerciseName': exerciseName,
    if (muscleGroup != null) 'muscleGroup': muscleGroup,
    'secondaryMuscles': secondaryMuscles,
    if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
    if (notes != null) 'notes': notes,
    'series': series.map((s) => s.toJson()).toList(),
  };
}

class RoutineModel {
  final int id;
  final String name;
  final String? description;
  final List<RoutineExerciseModel> exercises;

  const RoutineModel({
    required this.id,
    required this.name,
    this.description,
    required this.exercises,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  factory RoutineModel.fromJson(Map<String, dynamic> json) {
    final rawExercises = json['exercises'] as List<dynamic>? ?? [];
    return RoutineModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      exercises: rawExercises
          .map((e) => RoutineExerciseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WorkoutStartData {
  final List<ExerciseModel> exercises;
  final Map<int, int> targetSeries; // exerciseId → suggested sets count
  final Map<int, List<RoutineSeriesModel>>
  targetSeriesDetail; // exerciseId → series con peso/reps
  final String? routineName;

  const WorkoutStartData({
    required this.exercises,
    required this.targetSeries,
    this.targetSeriesDetail = const {},
    this.routineName,
  });

  factory WorkoutStartData.fromRoutine(RoutineModel routine) {
    final exercises = routine.exercises
        .map((re) => re.toExerciseModel())
        .toList();
    final targetSeries = <int, int>{};
    final targetSeriesDetail = <int, List<RoutineSeriesModel>>{};

    for (final re in routine.exercises) {
      if (re.series.isNotEmpty) {
        targetSeries[re.exerciseId] = re.series.length;
        targetSeriesDetail[re.exerciseId] = re.series;
      }
    }

    return WorkoutStartData(
      exercises: exercises,
      targetSeries: targetSeries,
      targetSeriesDetail: targetSeriesDetail,
      routineName: routine.name,
    );
  }

  static WorkoutStartData empty() {
    return const WorkoutStartData(exercises: [], targetSeries: {});
  }
}
