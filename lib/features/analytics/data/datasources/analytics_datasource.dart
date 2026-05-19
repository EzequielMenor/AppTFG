import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../models/analytics_models.dart';

class AnalyticsDatasource {
  /// Obtiene todos los ejercicios disponibles en el sistema.
  Future<List<ExerciseModel>> getExercises() async {
    final response = await ApiClientLegacy.get(
      '/api/exercises',
      queryParams: {'size': '200'},
    );
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
      'muscleGroup': ?muscleGroup,
      'equipment': ?equipment,
    };
    final response = await ApiClientLegacy.get('/api/exercises', queryParams: params);
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
    try {
      final response = await ApiClientLegacy.get(
        '/api/v1/analytics/1rm-progression',
        queryParams: {'exerciseId': exerciseId.toString()},
      );

      if (response.statusCode != 200) {
        return [];
      }

      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data
          .map((e) => Progression1RMModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<AnalyticsSummaryModel> getSummary(DateTime from, DateTime to) async {
    try {
      final response = await ApiClientLegacy.get(
        '/api/v1/analytics/summary',
        queryParams: {
          'from': from.toUtc().toIso8601String(),
          'to': to.toUtc().toIso8601String(),
        },
      );

      if (response.statusCode != 200) {
        return const AnalyticsSummaryModel(sessionCount: 0, totalVolume: 0);
      }

      return AnalyticsSummaryModel.fromJson(
        json.decode(utf8.decode(response.bodyBytes)),
      );
    } catch (_) {
      return const AnalyticsSummaryModel(sessionCount: 0, totalVolume: 0);
    }
  }

  Future<List<RecentPrModel>> getRecentPRs(DateTime from, DateTime to) async {
    try {
      final response = await ApiClientLegacy.get(
        '/api/v1/analytics/recent-prs',
        queryParams: {
          'from': from.toUtc().toIso8601String(),
          'to': to.toUtc().toIso8601String(),
        },
      );

      if (response.statusCode != 200) {
        return [];
      }

      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data
          .map((e) => RecentPrModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<TopExerciseModel>> getTopExercises({int limit = 5}) async {
    try {
      final response = await ApiClientLegacy.get(
        '/api/v1/analytics/top-exercises',
        queryParams: {'limit': limit.toString()},
      );

      if (response.statusCode != 200) {
        return [];
      }

      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data
          .map((e) => TopExerciseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<WeeklyVolumeModel>> getWeeklyVolume(
    DateTime from,
    DateTime to,
  ) async {
    try {
      final response = await ApiClientLegacy.get(
        '/api/v1/analytics/weekly-volume',
        queryParams: {
          'from': from.toUtc().toIso8601String(),
          'to': to.toUtc().toIso8601String(),
        },
      );

      if (response.statusCode != 200) {
        return [];
      }

      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data
          .map((e) => WeeklyVolumeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<MuscleDistributionModel>> getMuscleDistribution(
    DateTime from,
    DateTime to,
  ) async {
    try {
      final response = await ApiClientLegacy.get(
        '/api/v1/analytics/muscle-distribution',
        queryParams: {
          'from': from.toUtc().toIso8601String(),
          'to': to.toUtc().toIso8601String(),
        },
      );

      if (response.statusCode != 200) {
        return [];
      }

      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data
          .map(
            (e) => MuscleDistributionModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<ConsistencyModel> getTrainingDays(DateTime from, DateTime to) async {
    try {
      final response = await ApiClientLegacy.get(
        '/api/v1/analytics/training-days',
        queryParams: {
          'from': from.toUtc().toIso8601String(),
          'to': to.toUtc().toIso8601String(),
        },
      );

      if (response.statusCode != 200) {
        return const ConsistencyModel(
          currentStreak: 0,
          bestStreak: 0,
          avgDaysPerWeek: 0.0,
          trainingDays: [],
        );
      }

      return ConsistencyModel.fromJson(
        json.decode(utf8.decode(response.bodyBytes)),
      );
    } catch (_) {
      return const ConsistencyModel(
        currentStreak: 0,
        bestStreak: 0,
        avgDaysPerWeek: 0.0,
        trainingDays: [],
      );
    }
  }

  Future<DurationStatsModel> getDurationStats(
    DateTime from,
    DateTime to,
  ) async {
    try {
      final response = await ApiClientLegacy.get(
        '/api/v1/analytics/duration-stats',
        queryParams: {
          'from': from.toUtc().toIso8601String(),
          'to': to.toUtc().toIso8601String(),
        },
      );

      if (response.statusCode != 200) {
        return const DurationStatsModel(avgMinutes: 0, longestMinutes: 0);
      }

      return DurationStatsModel.fromJson(
        json.decode(utf8.decode(response.bodyBytes)),
      );
    } catch (_) {
      return const DurationStatsModel(avgMinutes: 0, longestMinutes: 0);
    }
  }

  Future<VolumeDensityModel> getVolumeDensity() async {
    try {
      final response = await ApiClientLegacy.get('/api/v1/analytics/volume-density');
      if (response.statusCode != 200) {
        return const VolumeDensityModel(
          currentDensity: 0,
          previousDensity: 0,
          changePercent: 0,
        );
      }
      return VolumeDensityModel.fromJson(
        json.decode(utf8.decode(response.bodyBytes)),
      );
    } catch (_) {
      return const VolumeDensityModel(
        currentDensity: 0,
        previousDensity: 0,
        changePercent: 0,
      );
    }
  }

  Future<TrainingStyleModel> getTrainingStyle(
    DateTime from,
    DateTime to,
  ) async {
    try {
      final response = await ApiClientLegacy.get(
        '/api/v1/analytics/training-style',
        queryParams: {
          'from': from.toUtc().toIso8601String(),
          'to': to.toUtc().toIso8601String(),
        },
      );
      if (response.statusCode != 200) {
        return const TrainingStyleModel(
          strengthSets: 0,
          hypertrophySets: 0,
          enduranceSets: 0,
        );
      }
      return TrainingStyleModel.fromJson(
        json.decode(utf8.decode(response.bodyBytes)),
      );
    } catch (_) {
      return const TrainingStyleModel(
        strengthSets: 0,
        hypertrophySets: 0,
        enduranceSets: 0,
      );
    }
  }

  Future<WeeklyRhythmModel> getWeeklyRhythm() async {
    try {
      final response = await ApiClientLegacy.get('/api/v1/analytics/weekly-rhythm');
      if (response.statusCode != 200) {
        return const WeeklyRhythmModel(
          sessionsByDayOfWeek: [0, 0, 0, 0, 0, 0, 0],
        );
      }
      return WeeklyRhythmModel.fromJson(
        json.decode(utf8.decode(response.bodyBytes)),
      );
    } catch (_) {
      return const WeeklyRhythmModel(
        sessionsByDayOfWeek: [0, 0, 0, 0, 0, 0, 0],
      );
    }
  }
}
