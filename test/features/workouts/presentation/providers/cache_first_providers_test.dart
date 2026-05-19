import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_analytics_mobile/core/cache/cache_manager.dart';
import 'package:gym_analytics_mobile/features/workouts/data/datasources/routine_datasource.dart';
import 'package:gym_analytics_mobile/features/workouts/data/datasources/workout_datasource.dart';
import 'package:gym_analytics_mobile/features/workouts/data/models/routine_models.dart';
import 'package:gym_analytics_mobile/features/workouts/data/models/workout_models.dart';
import 'package:gym_analytics_mobile/features/workouts/presentation/providers/routine_provider.dart';
import 'package:gym_analytics_mobile/features/workouts/presentation/providers/workout_provider.dart';

class _FailingRoutineDatasource extends RoutineDatasource {
  @override
  Future<List<RoutineModel>> getRoutines() async {
    throw Exception('backend down');
  }
}

class _FailingWorkoutDatasource extends WorkoutDatasource {
  @override
  Future<List<WorkoutModel>> getWorkouts({int page = 0, int size = 20}) async {
    throw Exception('backend down');
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Cache-first providers', () {
    test(
      'RoutineProvider.refresh mantiene rutinas cacheadas si falla red',
      () async {
        await CacheManager.setCache('routines', [
          {'id': 1, 'name': 'Push Day', 'exercises': <Map<String, dynamic>>[]},
        ], cacheDuration: const Duration(milliseconds: -1));

        final provider = RoutineProvider(
          datasource: _FailingRoutineDatasource(),
        );

        await provider.refresh();

        expect(provider.routines, hasLength(1));
        expect(provider.routines.first.name, 'Push Day');
        expect(provider.hasLoadedOnce, true);
        expect(provider.isUsingStaleData, true);
        expect(provider.errorMessage, isNull);
      },
    );

    test(
      'WorkoutProvider.loadHistory mantiene historial cacheado si falla red',
      () async {
        await CacheManager.setCache('workouts', [
          {
            'id': 7,
            'name': 'Leg Day',
            'startTime': DateTime(2026, 5, 1).toUtc().toIso8601String(),
            'exercises': <Map<String, dynamic>>[],
          },
        ], cacheDuration: const Duration(milliseconds: -1));

        final provider = WorkoutProvider(
          datasource: _FailingWorkoutDatasource(),
        );

        await provider.loadHistory();

        expect(provider.workouts, hasLength(1));
        expect(provider.workouts.first.name, 'Leg Day');
        expect(provider.hasLoadedOnce, true);
        expect(provider.isUsingStaleData, true);
        expect(provider.errorMessage, isNull);
      },
    );
  });
}
