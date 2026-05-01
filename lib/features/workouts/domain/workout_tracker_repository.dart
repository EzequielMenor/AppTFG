import '../data/models/workout_models.dart';

/// Interfaz abstracta para creación y actualización de workouts activos.
///
/// Define el contrato para operaciones de escritura durante un
/// entrenamiento en curso (tracker). Separada de [IWorkoutRepository]
/// siguiendo el principio de segregación de interfaces (ISP).
///
/// Implementada por [WorkoutDatasource] en `data/datasources/`.
abstract class IWorkoutTrackerRepository {
  Future<WorkoutModel> createWorkout(Map<String, dynamic> data);
  Future<WorkoutModel> updateWorkout(int id, Map<String, dynamic> data);
}
