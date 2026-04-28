import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/cache/cache_manager.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/chart_theme.dart';
import '../../../../shared/widgets/charts/app_bar_chart.dart';
import '../../data/datasources/analytics_datasource.dart';
import '../../data/models/analytics_models.dart';
import '../../domain/analytics_period.dart';
import '../widgets/volume_density_chart.dart';
import '../widgets/training_style_chart.dart';
import '../widgets/weekly_rhythm_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _datasource = AnalyticsDatasource();
  AnalyticsPeriod _period = AnalyticsPeriod.oneMonth;

  bool _loading = true;
  String? _error;

  /// True cuando los datos mostrados provienen de cache stale (background revalidating).
  bool _isUsingStaleData = false;

  /// True después del primer load exitoso — permite SWR en cambios de período.
  bool _hasLoadedOnce = false;

  AnalyticsSummaryModel? _summary;
  List<RecentPrModel> _recentPRs = [];
  List<TopExerciseModel> _topExercises = [];
  List<WeeklyVolumeModel> _weeklyVolume = [];
  List<WeeklyVolumeModel> _previousWeeklyVolume = [];
  List<MuscleDistributionModel> _muscleDistribution = [];
  ConsistencyModel? _consistency;
  DurationStatsModel? _durationStats;
  // EZE-168
  VolumeDensityModel? _volumeDensity;
  TrainingStyleModel? _trainingStyle;
  WeeklyRhythmModel? _weeklyRhythm;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // ── Data loading with SWR cache ──────────────────────────────────────

  /// Pull-to-refresh: limpia cache y carga fresco desde API.
  Future<void> _loadAllData() async {
    // Limpiar todo el cache de analytics para forzar fetch fresco
    await CacheManager.clearAllCache();

    setState(() {
      _loading = true;
      _error = null;
      _isUsingStaleData = false;
    });

    final range = _period.dateRange();
    final duration = range.to.difference(range.from);
    final prevFrom = range.from.subtract(duration);
    final prevTo = range.from;

    try {
      // Pull-to-refresh siempre usa Future.wait para carga paralela fresca
      final results = await Future.wait([
        _datasource.getSummary(range.from, range.to),
        _datasource.getRecentPRs(range.from, range.to),
        _datasource.getTopExercises(limit: 5),
        _datasource.getWeeklyVolume(range.from, range.to),
        _datasource.getWeeklyVolume(prevFrom, prevTo),
        _datasource.getMuscleDistribution(range.from, range.to),
        _datasource.getTrainingDays(range.from, range.to),
        _datasource.getDurationStats(range.from, range.to),
        _datasource.getVolumeDensity(),
        _datasource.getTrainingStyle(range.from, range.to),
        _datasource.getWeeklyRhythm(),
      ]);

      if (mounted) {
        setState(() {
          _summary = results[0] as AnalyticsSummaryModel;
          _recentPRs = results[1] as List<RecentPrModel>;
          _topExercises = results[2] as List<TopExerciseModel>;
          _weeklyVolume = results[3] as List<WeeklyVolumeModel>;
          _previousWeeklyVolume = results[4] as List<WeeklyVolumeModel>;
          _muscleDistribution = results[5] as List<MuscleDistributionModel>;
          _consistency = results[6] as ConsistencyModel;
          _durationStats = results[7] as DurationStatsModel;
          _volumeDensity = results[8] as VolumeDensityModel;
          _trainingStyle = results[9] as TrainingStyleModel;
          _weeklyRhythm = results[10] as WeeklyRhythmModel;
          _loading = false;
          _isUsingStaleData = false;
          _hasLoadedOnce = true;
        });
      }
    } catch (e, st) {
      debugPrint('[AnalyticsScreen] Error: $e\n$st');
      if (mounted) {
        setState(() {
          _error = 'Error al cargar las analíticas';
          _loading = false;
        });
      }
    }
  }

  /// Carga datos usando cache SWR. Si ya tenemos datos, los mantiene
  /// visibles mientras revalida en background.
  Future<void> _loadDataWithCache() async {
    final hadData = _hasLoadedOnce;

    // Si ya tenemos datos, NO mostrar loading spinner — SWR los actualizará
    if (hadData) {
      setState(() {
        _error = null;
        _isUsingStaleData = true;
      });
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final range = _period.dateRange();
    final duration = range.to.difference(range.from);
    final prevFrom = range.from.subtract(duration);
    final prevTo = range.from;

    try {
      // Cached methods con fallback a originales si falla el cache
      final summary = await _cachedOrFallback(
        () => _datasource.getSummaryCached(range.from, range.to),
        () => _datasource.getSummary(range.from, range.to),
      );
      final recentPRs = await _cachedOrFallback(
        () => _datasource.getRecentPRsCached(range.from, range.to),
        () => _datasource.getRecentPRs(range.from, range.to),
      );
      final topExercises = await _cachedOrFallback(
        () => _datasource.getTopExercisesCached(limit: 5),
        () => _datasource.getTopExercises(limit: 5),
      );
      final weeklyVolume = await _cachedOrFallback(
        () => _datasource.getWeeklyVolumeCached(range.from, range.to),
        () => _datasource.getWeeklyVolume(range.from, range.to),
      );
      final previousWeeklyVolume = await _cachedOrFallback(
        () => _datasource.getWeeklyVolumeCached(prevFrom, prevTo),
        () => _datasource.getWeeklyVolume(prevFrom, prevTo),
      );
      final volumeDensity = await _cachedOrFallback(
        () => _datasource.getVolumeDensityCached(),
        () => _datasource.getVolumeDensity(),
      );
      final weeklyRhythm = await _cachedOrFallback(
        () => _datasource.getWeeklyRhythmCached(),
        () => _datasource.getWeeklyRhythm(),
      );

      // Métodos sin versión cached — usar originales directamente
      final muscleDistribution = await _datasource.getMuscleDistribution(
        range.from,
        range.to,
      );
      final consistency = await _datasource.getTrainingDays(
        range.from,
        range.to,
      );
      final durationStats = await _datasource.getDurationStats(
        range.from,
        range.to,
      );
      final trainingStyle = await _datasource.getTrainingStyle(
        range.from,
        range.to,
      );

      if (mounted) {
        setState(() {
          _summary = summary;
          _recentPRs = recentPRs;
          _topExercises = topExercises;
          _weeklyVolume = weeklyVolume;
          _previousWeeklyVolume = previousWeeklyVolume;
          _muscleDistribution = muscleDistribution;
          _consistency = consistency;
          _durationStats = durationStats;
          _volumeDensity = volumeDensity;
          _trainingStyle = trainingStyle;
          _weeklyRhythm = weeklyRhythm;
          _loading = false;
          _hasLoadedOnce = true;
        });

        // Verificar staleness del cache
        await _checkAndScheduleStaleState();
      }
    } catch (e, st) {
      debugPrint('[AnalyticsScreen] Cache load error: $e\n$st');
      if (mounted) {
        setState(() {
          _error = 'Error al cargar las analíticas';
          _loading = false;
          _isUsingStaleData = false;
        });
      }
    }
  }

  /// Intenta método cached; si falla, cae al método original.
  Future<T> _cachedOrFallback<T>(
    Future<T> Function() cachedFn,
    Future<T> Function() fallbackFn,
  ) async {
    try {
      return await cachedFn();
    } catch (e) {
      debugPrint('[AnalyticsScreen] Cached method failed, using fallback: $e');
      return await fallbackFn();
    }
  }

  /// Verifica si alguna clave de cache está stale y programa re-chequeo.
  Future<void> _checkAndScheduleStaleState() async {
    final range = _period.dateRange();
    final fromUtc = range.from.toUtc().toIso8601String();
    final toUtc = range.to.toUtc().toIso8601String();

    final staleChecks = await Future.wait([
      CacheManager.getStale('analytics_summary_${fromUtc}_$toUtc'),
      CacheManager.getStale('analytics_recent_prs_${fromUtc}_$toUtc'),
      CacheManager.getStale('analytics_top_exercises_5'),
      CacheManager.getStale('analytics_volume_density'),
      CacheManager.getStale('analytics_weekly_rhythm'),
    ]);

    final anyStale = staleChecks.any((entry) => entry?.isExpired == true);

    if (mounted) {
      setState(() => _isUsingStaleData = anyStale);
    }

    // Programar re-chequeo tras 5s — para limpiar indicador cuando
    // el background refresh (disparado por _swr) complete.
    Future.delayed(const Duration(seconds: 5), () async {
      if (!mounted) return;
      final recheck = await Future.wait([
        CacheManager.getStale('analytics_summary_${fromUtc}_$toUtc'),
        CacheManager.getStale('analytics_volume_density'),
      ]);
      final stillStale = recheck.any((entry) => entry?.isExpired == true);
      if (mounted && _isUsingStaleData && !stillStale) {
        setState(() => _isUsingStaleData = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: const Text('ANALÍTICAS'),
        backgroundColor: AppTheme.appBackground,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Buscar ejercicio',
            onPressed: () => context.push('/analytics/exercises'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        color: AppTheme.neonGreen,
        backgroundColor: AppTheme.cardBackground,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.neonGreen),
              )
            : _error != null
            ? _buildErrorView()
            : _buildDashboard(),
      ),
    );
  }

  Widget _buildDashboard() {
    final hasWorkouts =
        (_summary?.sessionCount ?? 0) > 0 || _topExercises.isNotEmpty;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildPeriodSelector(),
          if (_isUsingStaleData) ...[
            const SizedBox(height: 8),
            _buildStaleDataBanner(),
          ],
          if (!hasWorkouts) ...[
            const SizedBox(height: 24),
            _buildEmptyGlobalBanner(),
          ],
          const SizedBox(height: 24),
          _buildKPIRow(),
          const SizedBox(height: 24),
          _buildRecordsCard(),
          const SizedBox(height: 24),
          _buildWeeklyVolumeCard(),
          const SizedBox(height: 24),
          _buildMuscleDistributionCard(),
          const SizedBox(height: 24),
          _buildConsistencyCard(),
          const SizedBox(height: 24),
          _buildDurationCard(),
          const SizedBox(height: 24),
          _buildVolumeDensityCard(),
          const SizedBox(height: 24),
          _buildTrainingStyleCard(),
          const SizedBox(height: 24),
          _buildWeeklyRhythmCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: AnalyticsPeriod.values
          .map(
            (p) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(p.label),
                selected: _period == p,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _period = p);
                    _loadDataWithCache();
                  }
                },
                selectedColor: AppTheme.neonGreen,
                backgroundColor: AppTheme.cardBackground,
                labelStyle: TextStyle(
                  color: _period == p
                      ? AppTheme.appBackground
                      : AppTheme.textGrey,
                  fontWeight: FontWeight.w600,
                ),
                side: const BorderSide(color: ChartTheme.gridColor),
              ),
            ),
          )
          .toList(),
    ),
  );

  Widget _buildKPIRow() {
    final volumeText = _summary != null
        ? _summary!.totalVolume >= 1000
              ? '${(_summary!.totalVolume / 1000).toStringAsFixed(1)}k'
              : _summary!.totalVolume.toStringAsFixed(0)
        : '0';

    return Row(
      children: [
        Expanded(
          child: _kpiCard(
            'Sesiones',
            '${_summary?.sessionCount ?? 0}',
            Icons.fitness_center,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _kpiCard('Volumen', '$volumeText kg', Icons.line_weight),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _kpiCard(
            'Racha actual',
            _buildRachaValue(),
            Icons.local_fire_department,
          ),
        ),
      ],
    );
  }

  Widget _kpiCard(String label, String value, IconData icon) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        Icon(icon, color: AppTheme.neonGreen.withOpacity(0.8), size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
        ),
      ],
    ),
  );

  Widget _buildRecordsCard() => _sectionCard(
    title: 'RÉCORDS',
    icon: Icons.emoji_events_outlined,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nuevos este periodo',
          style: TextStyle(
            color: AppTheme.textGrey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_recentPRs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Sin nuevos récords en este periodo',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          )
        else
          ..._recentPRs
              .take(5)
              .map(
                (pr) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          pr.exerciseName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '${pr.maxWeight.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          color: AppTheme.neonGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        const Divider(color: Colors.white10, height: 32),
        Row(
          children: [
            const Text(
              'Ranking histórico',
              style: TextStyle(
                color: AppTheme.textGrey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Peso máx.',
                style: TextStyle(
                  color: AppTheme.textGrey,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_topExercises.isEmpty)
          const Text(
            'Sin datos registrados aún',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          )
        else
          ..._topExercises.map((top) {
            Color rankColor = Colors.white54;
            if (top.rank == 1) rankColor = const Color(0xFFFFD700);
            if (top.rank == 2) rankColor = const Color(0xFFC0C0C0);
            if (top.rank == 3) rankColor = const Color(0xFFCD7F32);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: rankColor.withOpacity(0.2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${top.rank}',
                      style: TextStyle(
                        color: rankColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      top.exerciseName,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  Text(
                    '${top.best1Rm.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    ),
  );

  Widget _buildWeeklyVolumeCard() {
    final currentTotal = _weeklyVolume.fold<double>(
      0,
      (sum, w) => sum + w.totalVolume,
    );
    final prevTotal = _previousWeeklyVolume.fold<double>(
      0,
      (sum, w) => sum + w.totalVolume,
    );

    double percentDiff = 0;
    if (prevTotal > 0) {
      percentDiff = ((currentTotal - prevTotal) / prevTotal) * 100;
    }

    return _sectionCard(
      title: 'VOLUMEN SEMANAL',
      icon: Icons.bar_chart_rounded,
      badge: prevTotal > 0 ? _comparisonBadge(percentDiff) : null,
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: AppBarChart(
              values: _weeklyVolume.map((w) => w.totalVolume).toList(),
              labels: _weeklyVolume
                  .map((w) => 'S${_weekNumber(w.weekStart)}')
                  .toList(),
              yFormatter: (val) => val >= 1000
                  ? '${(val / 1000).toStringAsFixed(1)}k'
                  : val.toStringAsFixed(0),
              labelInterval: _barLabelInterval(_weeklyVolume.length),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _miniStat(
                'Este periodo',
                '${currentTotal.toStringAsFixed(0)} kg',
              ),
              const SizedBox(width: 16),
              _miniStat('Periodo ant.', '${prevTotal.toStringAsFixed(0)} kg'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleDistributionCard() => _sectionCard(
    title: 'DISTRIBUCIÓN MUSCULAR',
    icon: Icons.pie_chart_outline,
    child: _muscleDistribution.isEmpty
        ? const Text(
            'Sin entrenamientos en este periodo',
            style: TextStyle(color: Colors.white54),
          )
        : Column(
            children: _muscleDistribution
                .map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              m.muscleGroup,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${m.percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: AppTheme.neonGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: m.percentage / 100,
                            backgroundColor: Colors.white10,
                            color: AppTheme.neonGreen,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
  );

  Widget _buildConsistencyCard() => _sectionCard(
    title: 'CONSISTENCIA',
    icon: Icons.calendar_today_outlined,
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _miniStat(
              'Racha actual',
              '${_consistency?.currentStreak ?? 0} ${(_consistency?.currentStreak ?? 0) == 1 ? 'día' : 'días'}',
            ),
            _miniStat(
              'Mejor racha',
              '${_consistency?.bestStreak ?? 0} ${(_consistency?.bestStreak ?? 0) == 1 ? 'día' : 'días'}',
            ),
            _miniStat(
              'Media/sem',
              '${_consistency?.avgDaysPerWeek.toStringAsFixed(1) ?? '0'} d',
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildCalendarConsistency(),
      ],
    ),
  );

  Widget _buildCalendarConsistency() {
    final now = DateTime.now();
    final trainingDaysSet =
        _consistency?.trainingDays
            .map((d) => DateTime(d.year, d.month, d.day))
            .toSet() ??
        {};

    int maxMonths;
    switch (_period) {
      case AnalyticsPeriod.oneMonth:
        maxMonths = 1;
        break;
      case AnalyticsPeriod.threeMonths:
        maxMonths = 3;
        break;
      case AnalyticsPeriod.sixMonths:
        maxMonths = 6;
        break;
      default:
        maxMonths = 4;
    }

    final months = <DateTime>[];
    var cursor = DateTime(now.year, now.month, 1);
    for (int i = 0; i < maxMonths; i++) {
      months.insert(0, cursor);
      cursor = cursor.month == 1
          ? DateTime(cursor.year - 1, 12, 1)
          : DateTime(cursor.year, cursor.month - 1, 1);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int mi = 0; mi < months.length; mi++) ...[
          if (mi > 0) const SizedBox(height: 16),
          _buildMonthCalendar(months[mi], trainingDaysSet),
        ],
      ],
    );
  }

  Widget _buildMonthCalendar(DateTime month, Set<DateTime> trainingDays) {
    final monthName = DateFormat('MMMM yyyy', 'es_ES').format(month);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstWeekday = DateTime(month.year, month.month, 1).weekday; // 1=Mon
    const dayHeaders = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final cells = <Widget>[];
    for (int i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      cells.add(
        _dayCellCalendar(day, trainingDays.contains(date), date == today),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          monthName[0].toUpperCase() + monthName.substring(1),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: dayHeaders
              .map(
                (d) => Expanded(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 10,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          mainAxisSpacing: 3,
          crossAxisSpacing: 3,
          childAspectRatio: 1.0,
          children: cells,
        ),
      ],
    );
  }

  Widget _dayCellCalendar(int day, bool isTrained, bool isToday) => Container(
    decoration: BoxDecoration(
      color: isTrained
          ? AppTheme.neonGreen.withOpacity(0.85)
          : isToday
          ? Colors.white.withOpacity(0.12)
          : Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(4),
      border: isToday && !isTrained
          ? Border.all(color: AppTheme.neonGreen.withOpacity(0.5), width: 1)
          : null,
    ),
    alignment: Alignment.center,
    child: Text(
      '$day',
      style: TextStyle(
        fontSize: 10,
        fontWeight: isTrained ? FontWeight.bold : FontWeight.normal,
        color: isTrained ? Colors.black : Colors.white54,
      ),
    ),
  );

  Widget _buildDurationCard() => _sectionCard(
    title: 'DURACIÓN',
    icon: Icons.timer_outlined,
    child: Row(
      children: [
        Expanded(
          child: _miniStat(
            'Media por sesión',
            '${_durationStats?.avgMinutes ?? 0} min',
          ),
        ),
        Expanded(
          child: _miniStat(
            'Sesión más larga',
            '${_durationStats?.longestMinutes ?? 0} min',
          ),
        ),
      ],
    ),
  );

  // ── EZE-168 section cards ────────────────────────────────────────────────

  Widget _buildVolumeDensityCard() => _sectionCard(
    title: 'DENSIDAD DE VOLUMEN',
    icon: Icons.compress_rounded,
    child: _volumeDensity == null
        ? const Text('Sin datos', style: TextStyle(color: Colors.white54))
        : VolumeDensityChart(data: _volumeDensity!),
  );

  Widget _buildTrainingStyleCard() => _sectionCard(
    title: 'ESTILO DE ENTRENAMIENTO',
    icon: Icons.pie_chart_outline_rounded,
    child: _trainingStyle == null
        ? const Text('Sin datos', style: TextStyle(color: Colors.white54))
        : TrainingStyleChart(data: _trainingStyle!),
  );

  Widget _buildWeeklyRhythmCard() => _sectionCard(
    title: 'RITMO SEMANAL',
    icon: Icons.radar_rounded,
    child: _weeklyRhythm == null
        ? const Text('Sin datos', style: TextStyle(color: Colors.white54))
        : WeeklyRhythmChart(data: _weeklyRhythm!),
  );

  // ── UI Helpers ──────────────────────────────────────────────────────────

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? badge,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.textGrey),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textGrey,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            if (badge != null) badge,
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );

  Widget _comparisonBadge(double percent) {
    final isPositive = percent >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isPositive ? AppTheme.neonGreen : Colors.redAccent).withOpacity(
          0.15,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${isPositive ? '+' : ''}${percent.toStringAsFixed(0)}% vs ant.',
        style: TextStyle(
          color: isPositive ? AppTheme.neonGreen : Colors.redAccent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: AppTheme.textGrey, fontSize: 11),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );

  Widget _buildStaleDataBanner() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.orangeAccent.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.orangeAccent.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.orangeAccent.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Actualizando datos…',
            style: TextStyle(
              color: Colors.orangeAccent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildEmptyGlobalBanner() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [AppTheme.neonGreen.withOpacity(0.2), Colors.transparent],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, color: AppTheme.neonGreen),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'Registra tu primer entrenamiento para ver tus analíticas.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );

  Widget _buildErrorView() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
        const SizedBox(height: 16),
        Text(_error!, style: const TextStyle(color: AppTheme.textGrey)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _loadAllData,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen),
          child: const Text(
            'Reintentar',
            style: TextStyle(color: AppTheme.appBackground),
          ),
        ),
      ],
    ),
  );

  String _buildRachaValue() {
    final streak = _consistency?.currentStreak ?? 0;
    if (streak == 0) return '—';
    return '$streak ${streak == 1 ? 'día' : 'días'}';
  }

  int _weekNumber(DateTime date) {
    int dayOfYear = int.parse(DateFormat("D").format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  int _barLabelInterval(int barCount) {
    if (barCount <= 8) return 1;
    if (barCount <= 16) return 2;
    if (barCount <= 28) return 4;
    return 8;
  }

  DateTime _toDateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
