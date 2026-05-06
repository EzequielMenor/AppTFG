import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_analytics_mobile/features/analytics/data/datasources/analytics_datasource.dart';
import 'package:gym_analytics_mobile/features/analytics/data/models/analytics_models.dart';
import 'package:gym_analytics_mobile/features/analytics/data/repositories/analytics_repository_impl.dart';

class _FakeDatasource extends AnalyticsDatasource {
  int callCount = 0;

  @override
  Future<AnalyticsSummaryModel> getSummary(DateTime from, DateTime to) async {
    callCount++;
    return const AnalyticsSummaryModel(sessionCount: 1, totalVolume: 100);
  }
}

class _BlockingFakeDatasource extends AnalyticsDatasource {
  int callCount = 0;

  @override
  Future<AnalyticsSummaryModel> getSummary(DateTime from, DateTime to) async {
    callCount++;
    if (callCount > 1) {
      // Bloquea indefinidamente para demostrar que el caller no espera
      await Completer<void>().future;
    }
    return const AnalyticsSummaryModel(sessionCount: 1, totalVolume: 100);
  }
}

class _SlowFakeDatasource extends AnalyticsDatasource {
  int callCount = 0;
  final Duration delay;

  _SlowFakeDatasource({required this.delay});

  @override
  Future<AnalyticsSummaryModel> getSummary(DateTime from, DateTime to) async {
    callCount++;
    if (callCount > 1) {
      await Future.delayed(delay);
    }
    return const AnalyticsSummaryModel(sessionCount: 1, totalVolume: 100);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  group('AnalyticsRepositoryImpl', () {
    test('SWR cache miss → llama al datasource, cachea resultado',
        () async {
      final ds = _FakeDatasource();
      final repo = AnalyticsRepositoryImpl(remote: ds);

      final result = await repo.getSummary(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
      );

      expect(result.sessionCount, 1);
      expect(ds.callCount, 1);
    });

    test('SWR cache hit → devuelve datos sin bloquear al caller',
        () async {
      final ds = _BlockingFakeDatasource();
      final repo = AnalyticsRepositoryImpl(remote: ds);

      // Primera llamada pobla caché
      await repo.getSummary(DateTime(2024, 1, 1), DateTime(2024, 1, 31));
      expect(ds.callCount, 1);

      // Segunda llamada: cache hit. El background refresh se bloquea,
      // pero el caller recibe la respuesta inmediatamente.
      final result = await repo.getSummary(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
      );

      expect(result.sessionCount, 1);
      expect(ds.callCount, 2); // el background refresh inició
    });

    test('Background refresh no bloquea al caller', () async {
      final ds = _SlowFakeDatasource(delay: const Duration(seconds: 2));
      final repo = AnalyticsRepositoryImpl(remote: ds);

      // Primera llamada para poblar caché
      await repo.getSummary(DateTime(2024, 1, 1), DateTime(2024, 1, 31));
      expect(ds.callCount, 1);

      // Segunda llamada: cache hit + background refresh con delay de 2s
      final stopwatch = Stopwatch()..start();
      final result = await repo.getSummary(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
      );
      stopwatch.stop();

      expect(result.sessionCount, 1);
      // El caller debe recibir la respuesta en menos de 200ms
      // a pesar de que el refresco en background tarda 2s.
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
    });
  });
}
