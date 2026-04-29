import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/chart_theme.dart';
import '../../../../shared/widgets/charts/app_line_chart.dart';
import '../../data/models/analytics_models.dart';
import '../providers/analytics_provider.dart';

enum _TimePeriod { oneMonth, threeMonths, sixMonths, oneYear, all }

extension _TimePeriodLabel on _TimePeriod {
  String get label {
    switch (this) {
      case _TimePeriod.oneMonth:
        return '1M';
      case _TimePeriod.threeMonths:
        return '3M';
      case _TimePeriod.sixMonths:
        return '6M';
      case _TimePeriod.oneYear:
        return '1A';
      case _TimePeriod.all:
        return 'Todo';
    }
  }

  bool includes(DateTime date) {
    final now = DateTime.now();
    switch (this) {
      case _TimePeriod.oneMonth:
        return date.isAfter(now.subtract(const Duration(days: 30)));
      case _TimePeriod.threeMonths:
        return date.isAfter(now.subtract(const Duration(days: 90)));
      case _TimePeriod.sixMonths:
        return date.isAfter(now.subtract(const Duration(days: 180)));
      case _TimePeriod.oneYear:
        return date.isAfter(now.subtract(const Duration(days: 365)));
      case _TimePeriod.all:
        return true;
    }
  }
}

class OneRmProgressionScreen extends StatefulWidget {
  const OneRmProgressionScreen({super.key});

  static const routePath = '/analytics/1rm';

  @override
  State<OneRmProgressionScreen> createState() => _OneRmProgressionScreenState();
}

class _OneRmProgressionScreenState extends State<OneRmProgressionScreen> {
  List<ExerciseModel> _exercises = [];
  ExerciseModel? _selectedExercise;

  List<Progression1RMModel> _allData = [];
  List<Progression1RMModel> _filteredData = [];

  _TimePeriod _period = _TimePeriod.all;

  bool _loadingExercises = true;
  bool _loadingProgression = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    try {
      final provider = context.read<AnalyticsProvider>();
      final exercises = await provider.getExercises();
      setState(() {
        _exercises = exercises;
        _selectedExercise = exercises.isNotEmpty ? exercises.first : null;
        _loadingExercises = false;
      });
      if (_selectedExercise != null) {
        await _load1RMProgression(_selectedExercise!.id);
      }
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar los ejercicios.';
        _loadingExercises = false;
      });
    }
  }

  Future<void> _load1RMProgression(int exerciseId) async {
    setState(() {
      _loadingProgression = true;
      _error = null;
    });
    try {
      final provider = context.read<AnalyticsProvider>();
      final data = await provider.get1RMProgression(exerciseId);
      setState(() {
        _allData = data;
        _applyFilter();
        _loadingProgression = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar la progresión 1RM.';
        _loadingProgression = false;
      });
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredData = _allData.where((d) => _period.includes(d.date)).toList();
    });
  }

  Progression1RMModel? get _maxEntry {
    if (_filteredData.isEmpty) return null;
    return _filteredData.reduce(
      (a, b) => a.estimated1Rm > b.estimated1Rm ? a : b,
    );
  }

  int? get _highlightIndex {
    final max = _maxEntry;
    if (max == null) return null;
    return _filteredData.indexOf(max);
  }

  ({double diff, double percent})? get _lastMonthProgress {
    if (_filteredData.length < 2) return null;
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));

    final recent = _filteredData.last.estimated1Rm;
    final oneMonthBefore = _filteredData
        .where((d) => d.date.isBefore(monthAgo))
        .fold<double?>(null, (prev, e) => e.estimated1Rm);

    if (oneMonthBefore == null) return null;
    final diff = recent - oneMonthBefore;
    final percent = (diff / oneMonthBefore) * 100;
    return (diff: diff, percent: percent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: const Text('PROGRESO 1RM'),
        backgroundColor: AppTheme.appBackground,
      ),
      body: _loadingExercises
          ? const Center(child: CircularProgressIndicator(color: AppTheme.neonGreen))
          : _error != null && _exercises.isEmpty
              ? _buildErrorBanner()
              : _buildBody(),
    );
  }

  Widget _buildBody() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExerciseSelector(),
        const SizedBox(height: 20),
        _buildChartCard(),
        const SizedBox(height: 16),
        _buildTimePeriodChips(),
        const SizedBox(height: 20),
        _buildStatsPanel(),
        const SizedBox(height: 32),
      ],
    ),
  );

  Widget _buildExerciseSelector() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(
      color: AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: ChartTheme.gridColor),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<ExerciseModel>(
        isExpanded: true,
        value: _selectedExercise,
        dropdownColor: AppTheme.cardBackground,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.neonGreen),
        onChanged: (exercise) {
          if (exercise != null && exercise.id != _selectedExercise?.id) {
            setState(() => _selectedExercise = exercise);
            _load1RMProgression(exercise.id);
          }
        },
        items: _exercises
            .map((e) => DropdownMenuItem(
              value: e,
              child: Text(e.name),
            ))
            .toList(),
      ),
    ),
  );

  Widget _buildChartCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(16),
    ),
    child: SizedBox(
      height: 240,
      child: _buildChartContent(),
    ),
  );

  Widget _buildChartContent() {
    if (_loadingProgression) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.neonGreen),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: AppTheme.textGrey)),
      );
    }
    if (_filteredData.length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bar_chart_rounded, size: 48, color: AppTheme.textGrey),
              const SizedBox(height: 12),
              Text(
                'No hay datos suficientes para este ejercicio.\nNecesitas al menos 2 sesiones registradas.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final spots = _filteredData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.estimated1Rm);
    }).toList();

    final dateFormat = DateFormat('dd/MM');

    return AppLineChart(
      dataPoints: spots,
      highlightIndex: _highlightIndex,
      xFormatter: (val) {
        final i = val.toInt();
        if (i < 0 || i >= _filteredData.length) return '';
        return dateFormat.format(_filteredData[i].date);
      },
      yFormatter: (val) => '${val.toStringAsFixed(1)}kg',
    );
  }

  Widget _buildTimePeriodChips() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: _TimePeriod.values
          .map((period) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(period.label),
              selected: _period == period,
              onSelected: (_) {
                setState(() => _period = period);
                _applyFilter();
              },
              selectedColor: AppTheme.neonGreen,
              backgroundColor: AppTheme.cardBackground,
              labelStyle: TextStyle(
                color: _period == period
                    ? AppTheme.appBackground
                    : AppTheme.textGrey,
                fontWeight: FontWeight.w600,
              ),
              side: const BorderSide(color: ChartTheme.gridColor),
            ),
          ))
          .toList(),
    ),
  );

  Widget _buildStatsPanel() {
    final max = _maxEntry;
    final progress = _lastMonthProgress;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ESTADÍSTICAS',
            style: TextStyle(
              color: AppTheme.textGrey,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _statRow(
            icon: Icons.emoji_events_rounded,
            iconColor: ChartTheme.maxPointColor,
            label: 'Máximo histórico',
            value: max != null
                ? '${max.estimated1Rm.toStringAsFixed(1)} kg  •  ${DateFormat('dd/MM/yyyy').format(max.date)}'
                : '—',
          ),
          const SizedBox(height: 12),
          _statRow(
            icon: _trendIcon(progress?.diff),
            iconColor: _trendColor(progress?.diff),
            label: 'Progreso último mes',
            value: progress != null
                ? '${progress.diff >= 0 ? '+' : ''}${progress.diff.toStringAsFixed(1)} kg  (${progress.percent >= 0 ? '+' : ''}${progress.percent.toStringAsFixed(1)}%)'
                : '—',
            valueColor: _trendColor(progress?.diff),
          ),
        ],
      ),
    );
  }

  Widget _statRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
  }) =>
      Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildErrorBanner() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 56, color: AppTheme.textGrey),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textGrey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadExercises,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen),
            child: const Text('Reintentar',
                style: TextStyle(color: AppTheme.appBackground)),
          ),
        ],
      ),
    ),
  );

  IconData _trendIcon(double? diff) {
    if (diff == null) return Icons.remove;
    if (diff > 0) return Icons.trending_up_rounded;
    if (diff < 0) return Icons.trending_down_rounded;
    return Icons.trending_flat_rounded;
  }

  Color _trendColor(double? diff) {
    if (diff == null) return AppTheme.textGrey;
    if (diff > 0) return ChartTheme.lineColor;
    if (diff < 0) return Colors.redAccent;
    return AppTheme.textGrey;
  }
}
