import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/datasources/workout_datasource.dart';
import '../../data/models/routine_models.dart';

/// Representa un set activo en el tracker (datos editables, sin controllers).
class TrackerSetData {
  double? weight;
  int? reps;
  double? rpe;
  bool isWarmup;
  bool isDone;

  TrackerSetData({
    this.weight,
    this.reps,
    this.rpe,
    this.isWarmup = false,
    this.isDone = false,
  });
}

/// Representa un ejercicio activo en el tracker.
class TrackerExerciseData {
  final int exerciseId;
  final String exerciseName;
  final int targetSeries;
  final List<TrackerSetData> sets;

  TrackerExerciseData({
    required this.exerciseId,
    required this.exerciseName,
    this.targetSeries = 1,
    List<TrackerSetData>? sets,
  }) : sets = sets ??
            List.generate(
              targetSeries > 0 ? targetSeries : 1,
              (_) => TrackerSetData(),
            );
}

/// ChangeNotifier que gestiona el estado del workout activo.
///
/// Maneja: ejercicios activos, sets, timer de descanso, RPE, notas,
/// y el guardado del workout completo al finalizar.
class WorkoutTrackerProvider extends ChangeNotifier {
  final WorkoutDatasource _datasource;

  WorkoutTrackerProvider({WorkoutDatasource? datasource})
      : _datasource = datasource ?? WorkoutDatasource();

  // ── Estado del workout activo ────────────────────────────────────────────

  List<TrackerExerciseData> _exercises = [];
  DateTime? _startTime;
  int _currentIndex = 0;
  int _elapsedSeconds = 0;
  String? _routineName;
  bool _isSaving = false;
  bool _isWorkoutActive = false;
  Timer? _timer;

  List<TrackerExerciseData> get exercises => _exercises;
  DateTime? get startTime => _startTime;
  int get currentIndex => _currentIndex;
  int get elapsedSeconds => _elapsedSeconds;
  String? get routineName => _routineName;
  bool get isSaving => _isSaving;
  bool get isWorkoutActive => _isWorkoutActive;

  TrackerExerciseData? get currentExercise =>
      _exercises.isNotEmpty && _currentIndex < _exercises.length
          ? _exercises[_currentIndex]
          : null;

  // ── Inicio del workout ──────────────────────────────────────────────────

  /// Inicia un workout con los datos de [WorkoutStartData].
  void startWorkout(WorkoutStartData startData) {
    _exercises = startData.exercises.map((ex) {
      final ts = startData.targetSeries[ex.id] ?? 1;
      return TrackerExerciseData(
        exerciseId: ex.id,
        exerciseName: ex.name,
        targetSeries: ts,
      );
    }).toList();
    _startTime = DateTime.now();
    _currentIndex = 0;
    _elapsedSeconds = 0;
    _routineName = startData.routineName;
    _isWorkoutActive = true;
    _isSaving = false;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      notifyListeners();
    });

    notifyListeners();
  }

  /// Agrega un ejercicio manualmente al workout activo.
  void addExercise(TrackerExerciseData exercise) {
    _exercises.add(exercise);
    notifyListeners();
  }

  // ── Navegación entre ejercicios ─────────────────────────────────────────

  void goToPrevExercise() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void goToNextExercise() {
    if (_currentIndex < _exercises.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  // ── Gestión de sets ─────────────────────────────────────────────────────

  /// Agrega un set vacío al ejercicio actual.
  void addSet() {
    if (currentExercise == null) return;
    currentExercise!.sets.add(TrackerSetData());
    notifyListeners();
  }

  /// Marca/desmarca un set como completado.
  void toggleSetDone(int exerciseIndex, int setIndex) {
    if (exerciseIndex >= _exercises.length) return;
    final ex = _exercises[exerciseIndex];
    if (setIndex >= ex.sets.length) return;
    ex.sets[setIndex].isDone = !ex.sets[setIndex].isDone;
    notifyListeners();
  }

  /// Actualiza el peso de un set.
  void updateSetWeight(int exerciseIndex, int setIndex, double? weight) {
    if (exerciseIndex >= _exercises.length) return;
    final ex = _exercises[exerciseIndex];
    if (setIndex >= ex.sets.length) return;
    ex.sets[setIndex].weight = weight;
    // No notificamos en cada keystroke — se actualiza al salir del campo
  }

  /// Actualiza las reps de un set.
  void updateSetReps(int exerciseIndex, int setIndex, int? reps) {
    if (exerciseIndex >= _exercises.length) return;
    final ex = _exercises[exerciseIndex];
    if (setIndex >= ex.sets.length) return;
    ex.sets[setIndex].reps = reps;
  }

  /// Actualiza el RPE de un set.
  void updateSetRpe(int exerciseIndex, int setIndex, double? rpe) {
    if (exerciseIndex >= _exercises.length) return;
    final ex = _exercises[exerciseIndex];
    if (setIndex >= ex.sets.length) return;
    ex.sets[setIndex].rpe = rpe;
  }

  /// Marca/desmarca un set como warmup.
  void toggleSetWarmup(int exerciseIndex, int setIndex) {
    if (exerciseIndex >= _exercises.length) return;
    final ex = _exercises[exerciseIndex];
    if (setIndex >= ex.sets.length) return;
    ex.sets[setIndex].isWarmup = !ex.sets[setIndex].isWarmup;
    notifyListeners();
  }

  // ── Timer de descanso ───────────────────────────────────────────────────

  /// Inicia el timer de descanso. [duration] en segundos.
  /// Retorna un Stream que emite segundos restantes y completa al llegar a 0.
  Stream<int> startRestTimer(int duration) {
    return Stream.periodic(const Duration(seconds: 1), (i) => duration - i - 1)
        .take(duration + 1);
  }

  // ── Finalizar workout ──────────────────────────────────────────────────

  /// Finaliza el workout activo, lo persiste via datasource y limpia estado.
  Future<bool> finishWorkout({
    required DateTime startTime,
    required DateTime endTime,
    required List<Map<String, dynamic>> exercisesPayload,
  }) async {
    _isSaving = true;
    notifyListeners();

    final now = startTime;
    final autoName =
        'Entrenamiento ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    final payload = {
      'name': autoName,
      'startTime': startTime.toUtc().toIso8601String(),
      'endTime': endTime.toUtc().toIso8601String(),
      'exercises': exercisesPayload,
    };

    try {
      await _datasource.createWorkout(payload);
      _clearActiveWorkout();
      return true;
    } catch (e) {
      debugPrint('[WorkoutTrackerProvider] Error saving workout: $e');
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Cancela el workout activo (descarta cambios).
  void cancelWorkout() {
    _clearActiveWorkout();
  }

  void _clearActiveWorkout() {
    _timer?.cancel();
    _timer = null;
    _exercises = [];
    _startTime = null;
    _currentIndex = 0;
    _elapsedSeconds = 0;
    _routineName = null;
    _isSaving = false;
    _isWorkoutActive = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
