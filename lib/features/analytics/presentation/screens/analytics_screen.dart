import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/chart_theme.dart';
import '../../../../shared/widgets/charts/app_bar_chart.dart';
import '../../data/models/analytics_models.dart';
import '../../domain/analytics_period.dart';
import '../providers/analytics_provider.dart';
import '../widgets/volume_density_chart.dart';
import '../widgets/training_style_chart.dart';
import '../widgets/weekly_rhythm_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    // Carga inicial post-frame para evitar llamar notifyListeners durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();

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
        onRefresh: provider.forceRefresh,
        color: AppTheme.neonGreen,
        backgroundColor: AppTheme.cardBackground,
        child: provider.isLoading && !provider.hasLoadedOnce
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.neonGreen),
              )
            : provider.error != null && !provider.hasLoadedOnce
                ? _buildErrorView(provider)
                : _buildDashboard(provider),
      ),
    );
  }

  Widget _buildDashboard(AnalyticsProvider provider) {
    final hasWorkouts =
        (provider.summary?.sessionCount ?? 0) > 0 ||
        provider.topExercises.isNotEmpty;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildPeriodSelector(provider),
          if (provider.isUsingStaleData) ...[
            const SizedBox(height: 8),
            _buildStaleDataBanner(),
          ],
          if (!hasWorkouts) ...[
            const SizedBox(height: 24),
            _buildEmptyGlobalBanner(),
          ],
          const SizedBox(height: 24),
          _buildKPIRow(provider),
          const SizedBox(height: 24),
          _buildRecordsCard(provider),
          const SizedBox(height: 24),
          _buildWeeklyVolumeCard(provider),
          const SizedBox(height: 24),
          _buildMuscleDistributionCard(provider),
          const SizedBox(height: 24),
          _buildConsistencyCard(provider),
          const SizedBox(height: 24),
          _buildDurationCard(provider),
          const SizedBox(height: 24),
          _buildVolumeDensityCard(provider),
          const SizedBox(height: 24),
          _buildTrainingStyleCard(provider),
          const SizedBox(height: 24),
          _buildWeeklyRhythmCard(provider),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(AnalyticsProvider provider) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: AnalyticsPeriod.values
          .map(
            (p) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(p.label),
                selected: provider.period == p,
                onSelected: (selected) {
                  if (selected) provider.changePeriod(p);
                },
                selectedColor: AppTheme.neonGreen,
                backgroundColor: AppTheme.cardBackground,
                labelStyle: TextStyle(
                  color: provider.period == p
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

  Widget _buildKPIRow(AnalyticsProvider provider) {
    final summary = provider.summary;
    final volumeText = summary != null
        ? summary.totalVolume >= 1000
              ? '${(summary.totalVolume / 1000).toStringAsFixed(1)}k'
              : summary.totalVolume.toStringAsFixed(0)
        : '0';

    return Row(
      children: [
        Expanded(
          child: _kpiCard(
            'Sesiones',
            '${summary?.sessionCount ?? 0}',
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
            _buildRachaValue(provider.consistency),
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
        Icon(icon, color: AppTheme.neonGreen.withValues(alpha: 0.8), size: 20),
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

  Widget _buildRecordsCard(AnalyticsProvider provider) => _sectionCard(
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
        if (provider.recentPRs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Sin nuevos récords en este periodo',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          )
        else
          ...provider.recentPRs
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
                color: Colors.white.withValues(alpha: 0.07),
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
        if (provider.topExercises.isEmpty)
          const Text(
            'Sin datos registrados aún',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          )
        else
          ...provider.topExercises.map((top) {
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
                      color: rankColor.withValues(alpha: 0.2),
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

  Widget _buildWeeklyVolumeCard(AnalyticsProvider provider) {
    final currentTotal = provider.weeklyVolume.fold<double>(
      0,
      (sum, w) => sum + w.totalVolume,
    );
    final prevTotal = provider.previousWeeklyVolume.fold<double>(
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
              values: provider.weeklyVolume.map((w) => w.totalVolume).toList(),
              labels: provider.weeklyVolume
                  .map((w) => 'S${_weekNumber(w.weekStart)}')
                  .toList(),
              yFormatter: (val) => val >= 1000
                  ? '${(val / 1000).toStringAsFixed(1)}k'
                  : val.toStringAsFixed(0),
              labelInterval: _barLabelInterval(provider.weeklyVolume.length),
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

  Widget _buildMuscleDistributionCard(AnalyticsProvider provider) =>
      _sectionCard(
        title: 'DISTRIBUCIÓN MUSCULAR',
        icon: Icons.pie_chart_outline,
        child: provider.muscleDistribution.isEmpty
            ? const Text(
                'Sin entrenamientos en este periodo',
                style: TextStyle(color: Colors.white54),
              )
            : Column(
                children: provider.muscleDistribution
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

  Widget _buildConsistencyCard(AnalyticsProvider provider) => _sectionCard(
    title: 'CONSISTENCIA',
    icon: Icons.calendar_today_outlined,
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _miniStat(
              'Racha actual',
              '${provider.consistency?.currentStreak ?? 0} ${(provider.consistency?.currentStreak ?? 0) == 1 ? 'día' : 'días'}',
            ),
            _miniStat(
              'Mejor racha',
              '${provider.consistency?.bestStreak ?? 0} ${(provider.consistency?.bestStreak ?? 0) == 1 ? 'día' : 'días'}',
            ),
            _miniStat(
              'Media/sem',
              '${provider.consistency?.avgDaysPerWeek.toStringAsFixed(1) ?? '0'} d',
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildCalendarConsistency(provider),
      ],
    ),
  );

  Widget _buildCalendarConsistency(AnalyticsProvider provider) {
    final now = DateTime.now();
    final trainingDaysSet =
        provider.consistency?.trainingDays
            .map((d) => DateTime(d.year, d.month, d.day))
            .toSet() ??
        {};

    int maxMonths;
    switch (provider.period) {
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
    final firstWeekday = DateTime(month.year, month.month, 1).weekday;
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
          ? AppTheme.neonGreen.withValues(alpha: 0.85)
          : isToday
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(4),
      border: isToday && !isTrained
          ? Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.5), width: 1)
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

  Widget _buildDurationCard(AnalyticsProvider provider) => _sectionCard(
    title: 'DURACIÓN',
    icon: Icons.timer_outlined,
    child: Row(
      children: [
        Expanded(
          child: _miniStat(
            'Media por sesión',
            '${provider.durationStats?.avgMinutes ?? 0} min',
          ),
        ),
        Expanded(
          child: _miniStat(
            'Sesión más larga',
            '${provider.durationStats?.longestMinutes ?? 0} min',
          ),
        ),
      ],
    ),
  );

  Widget _buildVolumeDensityCard(AnalyticsProvider provider) => _sectionCard(
    title: 'DENSIDAD DE VOLUMEN',
    icon: Icons.compress_rounded,
    child: provider.volumeDensity == null
        ? const Text('Sin datos', style: TextStyle(color: Colors.white54))
        : VolumeDensityChart(data: provider.volumeDensity!),
  );

  Widget _buildTrainingStyleCard(AnalyticsProvider provider) => _sectionCard(
    title: 'ESTILO DE ENTRENAMIENTO',
    icon: Icons.pie_chart_outline_rounded,
    child: provider.trainingStyle == null
        ? const Text('Sin datos', style: TextStyle(color: Colors.white54))
        : TrainingStyleChart(data: provider.trainingStyle!),
  );

  Widget _buildWeeklyRhythmCard(AnalyticsProvider provider) => _sectionCard(
    title: 'RITMO SEMANAL',
    icon: Icons.radar_rounded,
    child: provider.weeklyRhythm == null
        ? const Text('Sin datos', style: TextStyle(color: Colors.white54))
        : WeeklyRhythmChart(data: provider.weeklyRhythm!),
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
            ?badge,
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
        color: (isPositive ? AppTheme.neonGreen : Colors.redAccent).withValues(
          alpha: 0.15,
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
      color: Colors.orangeAccent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.orangeAccent.withValues(alpha: 0.7),
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
        colors: [AppTheme.neonGreen.withValues(alpha: 0.2), Colors.transparent],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.3)),
    ),
    child: const Row(
      children: [
        Icon(Icons.info_outline, color: AppTheme.neonGreen),
        SizedBox(width: 16),
        Expanded(
          child: Text(
            'Registra tu primer entrenamiento para ver tus analíticas.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );

  Widget _buildErrorView(AnalyticsProvider provider) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
        const SizedBox(height: 16),
        Text(provider.error!, style: const TextStyle(color: AppTheme.textGrey)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: provider.forceRefresh,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen),
          child: const Text(
            'Reintentar',
            style: TextStyle(color: AppTheme.appBackground),
          ),
        ),
      ],
    ),
  );

  String _buildRachaValue(ConsistencyModel? consistency) {
    final streak = consistency?.currentStreak ?? 0;
    if (streak == 0) return '—';
    return '$streak ${streak == 1 ? 'día' : 'días'}';
  }

  int _weekNumber(DateTime date) {
    int dayOfYear = int.parse(DateFormat('D').format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  int _barLabelInterval(int barCount) {
    if (barCount <= 8) return 1;
    if (barCount <= 16) return 2;
    if (barCount <= 28) return 4;
    return 8;
  }
}
