import '../../../analytics/data/models/analytics_models.dart';

class RoutineExerciseModel {
  final int id;
  final int exerciseId;
  final int exerciseOrder;
  final String exerciseName;
  final String? muscleGroup;
  final String? thumbnailUrl;
  final String? notes;
  final int? targetSeries;

  const RoutineExerciseModel({
    required this.id,
    required this.exerciseId,
    required this.exerciseOrder,
    required this.exerciseName,
    this.muscleGroup,
    this.thumbnailUrl,
    this.notes,
    this.targetSeries,
  });

  factory RoutineExerciseModel.fromJson(Map<String, dynamic> json) {
    return RoutineExerciseModel(
      id: json['id'] as int,
      exerciseId: json['exerciseId'] as int,
      exerciseOrder: json['exerciseOrder'] as int,
      exerciseName: json['exerciseName'] as String,
      muscleGroup: json['muscleGroup'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      notes: json['notes'] as String?,
      targetSeries: json['targetSeries'] as int?,
    );
  }

  ExerciseModel toExerciseModel() {
    return ExerciseModel(
      id: exerciseId,
      name: exerciseName,
      muscleGroup: muscleGroup,
      thumbnailUrl: thumbnailUrl,
    );
  }
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
  final Map<int, int> targetSeries; // exerciseId → suggested sets

  const WorkoutStartData({
    required this.exercises,
    required this.targetSeries,
  });

  factory WorkoutStartData.fromRoutine(RoutineModel routine) {
    final exercises = routine.exercises
        .map((re) => re.toExerciseModel())
        .toList();
    final targetSeries = <int, int>{
      for (final re in routine.exercises)
        if (re.targetSeries != null) re.exerciseId: re.targetSeries!,
    };
    return WorkoutStartData(exercises: exercises, targetSeries: targetSeries);
  }

  static WorkoutStartData empty() {
    return const WorkoutStartData(exercises: [], targetSeries: {});
  }
}
