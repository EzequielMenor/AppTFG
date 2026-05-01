import '../data/models/workout_models.dart';

/// Interfaz abstracta para consulta y eliminación de workouts.
///
/// Define el contrato para operaciones de lectura del historial
/// de entrenamientos. Separada de [IWorkoutTrackerRepository]
/// siguiendo el principio de segregación de interfaces (ISP).
///
/// Implementada por [WorkoutDatasource] en `data/datasources/`.
abstract class IWorkoutRepository {
  Future<List<WorkoutModel>> getWorkouts({int page = 0, int size = 20});
  Future<WorkoutModel> getWorkout(int id);
  Future<void> deleteWorkout(int id);
}
