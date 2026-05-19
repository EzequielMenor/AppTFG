import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../../domain/routine_repository.dart';
import '../models/routine_models.dart';

/// Centraliza las llamadas HTTP relacionadas con rutinas.
///
/// Implementa [IRoutineRepository] para inversión de dependencias
/// desde [RoutineProvider].
class RoutineDatasource implements IRoutineRepository {
  @override
  Future<List<RoutineModel>> getRoutines() async {
    final response = await ApiClientLegacy.get('/api/routines');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data
          .map((e) => RoutineModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Error al obtener rutinas: ${response.statusCode}');
  }

  @override
  Future<RoutineModel> createRoutine({
    required String name,
    String? description,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final body = {
      'name': name,
      if (description != null && description.isNotEmpty)
        'description': description,
      'exercises': exercises,
    };
    final response = await ApiClientLegacy.post('/api/routines', body: body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return RoutineModel.fromJson(data);
    }
    throw Exception('Error al crear rutina: ${response.statusCode}');
  }

  @override
  Future<RoutineModel> updateRoutine({
    required int id,
    required String name,
    String? description,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final body = {
      'name': name,
      if (description != null && description.isNotEmpty)
        'description': description,
      'exercises': exercises,
    };
    final response = await ApiClientLegacy.put('/api/routines/$id', body: body);
    if (response.statusCode == 200) {
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return RoutineModel.fromJson(data);
    }
    throw Exception('Error al actualizar rutina: ${response.statusCode}');
  }

  @override
  Future<void> deleteRoutine(int id) async {
    final response = await ApiClientLegacy.delete('/api/routines/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al borrar rutina: ${response.statusCode}');
    }
  }
}
