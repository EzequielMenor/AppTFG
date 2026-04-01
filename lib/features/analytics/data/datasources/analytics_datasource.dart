import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../models/analytics_models.dart';

class AnalyticsDatasource {
  /// Obtiene todos los ejercicios disponibles en el sistema.
  Future<List<ExerciseModel>> getExercises() async {
    final response = await ApiClient.get('/api/exercises', queryParams: {'size': '200'});
    if (response.statusCode != 200) {
      throw Exception('Error al cargar ejercicios: ${response.statusCode}');
    }
    final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
    return data
        .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Busca ejercicios con filtros opcionales y paginación.
  Future<List<ExerciseModel>> getExercisesFiltered({
    String? name,
    String? muscleGroup,
    String? equipment,
    int page = 0,
    int size = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
      if (name != null && name.isNotEmpty) 'name': name,
      if (muscleGroup != null) 'muscleGroup': muscleGroup,
      if (equipment != null) 'equipment': equipment,
    };
    final response = await ApiClient.get('/api/exercises', queryParams: params);
    if (response.statusCode != 200) {
      throw Exception('Error al buscar ejercicios: ${response.statusCode}');
    }
    final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
    return data
        .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Devuelve la progresión de 1RM estimado para [exerciseId].
  Future<List<Progression1RMModel>> get1RMProgression(int exerciseId) async {
    final response = await ApiClient.get(
      '/api/v1/analytics/1rm-progression',
      queryParams: {
        'exerciseId': exerciseId.toString(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al cargar progresión 1RM: ${response.statusCode}');
    }

    final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
    return data
        .map((e) => Progression1RMModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AnalyticsSummaryModel> getSummary(DateTime from, DateTime to) async {
    final response = await ApiClient.get(
      '/api/v1/analytics/summary',
      queryParams: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al cargar resumen: ${response.statusCode}');
    }

    return AnalyticsSummaryModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
  }

  Future<List<RecentPrModel>> getRecentPRs(DateTime from, DateTime to) async {
    final response = await ApiClient.get(
      '/api/v1/analytics/recent-prs',
      queryParams: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al cargar PRs recientes: ${response.statusCode}');
    }

    final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
    return data.map((e) => RecentPrModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<TopExerciseModel>> getTopExercises({int limit = 5}) async {
    final response = await ApiClient.get(
      '/api/v1/analytics/top-exercises',
      queryParams: {
        'limit': limit.toString(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al cargar top ejercicios: ${response.statusCode}');
    }

    final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
    return data.map((e) => TopExerciseModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<WeeklyVolumeModel>> getWeeklyVolume(DateTime from, DateTime to) async {
    final response = await ApiClient.get(
      '/api/v1/analytics/weekly-volume',
      queryParams: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al cargar volumen semanal: ${response.statusCode}');
    }

    final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
    return data.map((e) => WeeklyVolumeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MuscleDistributionModel>> getMuscleDistribution(DateTime from, DateTime to) async {
    final response = await ApiClient.get(
      '/api/v1/analytics/muscle-distribution',
      queryParams: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al cargar distribución muscular: ${response.statusCode}');
    }

    final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
    return data.map((e) => MuscleDistributionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ConsistencyModel> getTrainingDays(DateTime from, DateTime to) async {
    final response = await ApiClient.get(
      '/api/v1/analytics/training-days',
      queryParams: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al cargar días de entrenamiento: ${response.statusCode}');
    }

    return ConsistencyModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
  }

  Future<DurationStatsModel> getDurationStats(DateTime from, DateTime to) async {
    final response = await ApiClient.get(
      '/api/v1/analytics/duration-stats',
      queryParams: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al cargar estadísticas de duración: ${response.statusCode}');
    }

    return DurationStatsModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
  }

  // ── EZE-168 ────────────────────────────────────────────────────────────────

  Future<VolumeDensityModel> getVolumeDensity() async {
    final response = await ApiClient.get('/api/v1/analytics/volume-density');
    if (response.statusCode != 200) {
      throw Exception('Error al cargar densidad de volumen: ${response.statusCode}');
    }
    return VolumeDensityModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
  }

  Future<TrainingStyleModel> getTrainingStyle(DateTime from, DateTime to) async {
    final response = await ApiClient.get(
      '/api/v1/analytics/training-style',
      queryParams: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Error al cargar estilo de entrenamiento: ${response.statusCode}');
    }
    return TrainingStyleModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
  }

  Future<WeeklyRhythmModel> getWeeklyRhythm() async {
    final response = await ApiClient.get('/api/v1/analytics/weekly-rhythm');
    if (response.statusCode != 200) {
      throw Exception('Error al cargar ritmo semanal: ${response.statusCode}');
    }
    return WeeklyRhythmModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
  }

  // ── EZE-169 ────────────────────────────────────────────────────────────────

  Future<ExerciseTrendModel> getExerciseTrend(int exerciseId) async {
    final response = await ApiClient.get('/api/v1/analytics/exercise/$exerciseId/trend');
    if (response.statusCode != 200) {
      throw Exception('Error al cargar tendencia del ejercicio: ${response.statusCode}');
    }
    return ExerciseTrendModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
  }
}
