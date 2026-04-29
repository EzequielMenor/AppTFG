// ── Series Model ──────────────────────────────────────────────────────────────

class SeriesModel {
  final int? id;
  final int setOrder;
  final double? weight;
  final int? reps;
  final double? rpe;
  final bool isWarmup;
  final bool done;

  const SeriesModel({
    this.id,
    required this.setOrder,
    this.weight,
    this.reps,
    this.rpe,
    this.isWarmup = false,
    this.done = false,
  });

  factory SeriesModel.fromJson(Map<String, dynamic> json) {
    return SeriesModel(
      id: json['id'] as int?,
      setOrder: (json['setOrder'] as num?)?.toInt() ?? 1,
      weight: (json['weight'] as num?)?.toDouble(),
      reps: (json['reps'] as num?)?.toInt(),
      rpe: (json['rpe'] as num?)?.toDouble(),
      isWarmup: json['isWarmup'] == true,
      done: json['done'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'setOrder': setOrder,
    if (weight != null) 'weight': weight,
    if (reps != null) 'reps': reps,
    if (rpe != null) 'rpe': rpe,
    'isWarmup': isWarmup,
    'done': done,
  };
}

// ── Workout Exercise Model ────────────────────────────────────────────────────

class WorkoutExerciseModel {
  final int id;
  final int exerciseId;
  final String exerciseName;
  final String? muscleGroup;
  final int order;
  final List<SeriesModel> sets;
  final String? thumbnailUrl;
  final String? videoUrl;

  const WorkoutExerciseModel({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    this.muscleGroup,
    this.order = 1,
    this.sets = const [],
    this.thumbnailUrl,
    this.videoUrl,
  });

  factory WorkoutExerciseModel.fromJson(Map<String, dynamic> json) {
    // El API devuelve ejercicio anidado en clave 'exercise'
    final exerciseData = json['exercise'] as Map<String, dynamic>? ?? {};
    final rawSets = json['series'] as List<dynamic>? ?? [];

    final exerciseId = (exerciseData['id'] as num?)?.toInt() ?? 0;

    return WorkoutExerciseModel(
      id: exerciseId,
      exerciseId: exerciseId,
      exerciseName: exerciseData['name'] as String? ?? '',
      muscleGroup: exerciseData['muscleGroup'] as String?,
      order: (json['exerciseOrder'] as num?)?.toInt() ??
          (json['order'] as num?)?.toInt() ??
          1,
      sets: rawSets
          .map((s) => SeriesModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      thumbnailUrl: exerciseData['thumbnailUrl'] as String?,
      videoUrl: exerciseData['videoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'exerciseOrder': order,
    'series': sets.map((s) => s.toJson()).toList(),
  };
}

// ── Workout Model ─────────────────────────────────────────────────────────────

class WorkoutModel {
  final int id;
  final String? name;
  final DateTime startTime;
  final DateTime? endTime;
  final double? totalVolume;
  final String? notes;
  final List<WorkoutExerciseModel> exercises;

  const WorkoutModel({
    required this.id,
    this.name,
    required this.startTime,
    this.endTime,
    this.totalVolume,
    this.notes,
    this.exercises = const [],
  });

  factory WorkoutModel.fromJson(Map<String, dynamic> json) {
    final rawExercises = json['exercises'] as List<dynamic>? ?? [];

    return WorkoutModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String?,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      totalVolume: (json['totalVolume'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      exercises: rawExercises
          .map((e) => WorkoutExerciseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != 0) 'id': id,
    if (name != null) 'name': name,
    'startTime': startTime.toUtc().toIso8601String(),
    if (endTime != null) 'endTime': endTime!.toUtc().toIso8601String(),
    if (totalVolume != null) 'totalVolume': totalVolume,
    if (notes != null) 'notes': notes,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };
}
