import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../../domain/workout_repository.dart';
import '../../domain/workout_tracker_repository.dart';
import '../models/workout_models.dart';

/// Centraliza las llamadas HTTP relacionadas con workouts.
///
/// Implementa [IWorkoutRepository] (lectura/borrado) e
/// [IWorkoutTrackerRepository] (creación/actualización) para
/// inversión de dependencias desde los providers.
///
/// Sigue el patrón de [RoutineDatasource] y [AnalyticsDatasource].
class WorkoutDatasource implements IWorkoutRepository, IWorkoutTrackerRepository {
  @override
  Future<List<WorkoutModel>> getWorkouts({int page = 0, int size = 20}) async {
    final response = await ApiClient.get(
      '/api/workouts',
      queryParams: {'page': page.toString(), 'size': size.toString()},
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> content = data['content'] ?? [];
      return content
          .map((e) => WorkoutModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Error al obtener workouts: ${response.statusCode}');
  }

  @override
  Future<WorkoutModel> getWorkout(int id) async {
    final response = await ApiClient.get('/api/workouts/$id');
    if (response.statusCode == 200) {
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return WorkoutModel.fromJson(data);
    }
    throw Exception('Error al obtener workout $id: ${response.statusCode}');
  }

  @override
  Future<WorkoutModel> createWorkout(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/api/workouts', body: data);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return WorkoutModel.fromJson(body);
    }
    throw Exception('Error al crear workout: ${response.statusCode}');
  }

  @override
  Future<WorkoutModel> updateWorkout(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await ApiClient.put('/api/workouts/$id', body: data);
    if (response.statusCode == 200) {
      final body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return WorkoutModel.fromJson(body);
    }
    throw Exception('Error al actualizar workout $id: ${response.statusCode}');
  }

  @override
  Future<void> deleteWorkout(int id) async {
    final response = await ApiClient.delete('/api/workouts/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al borrar workout $id: ${response.statusCode}');
    }
  }
}
