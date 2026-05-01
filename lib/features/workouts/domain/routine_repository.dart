import '../data/models/routine_models.dart';

/// Interfaz abstracta para el CRUD de rutinas.
///
/// Define el contrato para gestionar plantillas de entrenamiento.
/// Implementada por [RoutineDatasource] en `data/datasources/`.
abstract class IRoutineRepository {
  Future<List<RoutineModel>> getRoutines();
  Future<RoutineModel> createRoutine({
    required String name,
    String? description,
    required List<Map<String, dynamic>> exercises,
  });
  Future<RoutineModel> updateRoutine({
    required int id,
    required String name,
    String? description,
    required List<Map<String, dynamic>> exercises,
  });
  Future<void> deleteRoutine(int id);
}
