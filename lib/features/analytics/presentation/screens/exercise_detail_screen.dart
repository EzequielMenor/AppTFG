import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/chart_theme.dart';
import '../../../../shared/widgets/charts/app_line_chart.dart';
import '../../data/datasources/analytics_datasource.dart';
import '../../data/models/analytics_models.dart';

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

class ExerciseDetailScreen extends StatefulWidget {
  final int exerciseId;
  final String exerciseName;
  final String? muscleGroup;
  final String? thumbnailUrl;
  final String? videoUrl;

  const ExerciseDetailScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    this.muscleGroup,
    this.thumbnailUrl,
    this.videoUrl,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  final _datasource = AnalyticsDatasource();

  List<Progression1RMModel> _allData = [];
  List<Progression1RMModel> _filteredData = [];
  _TimePeriod _period = _TimePeriod.all;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _datasource.get1RMProgression(widget.exerciseId);
      setState(() {
        _allData = data;
        _applyFilter();
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'No se pudo cargar la progresión.';
        _loading = false;
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
    return _filteredData.reduce((a, b) => a.estimated1Rm > b.estimated1Rm ? a : b);
  }

  int? get _highlightIndex {
    final max = _maxEntry;
    if (max == null) return null;
    return _filteredData.indexOf(max);
  }

  ({double diff, double percent})? get _lastMonthProgress {
    if (_filteredData.length < 2) return null;
    final monthAgo = DateTime.now().subtract(const Duration(days: 30));
    final recent = _filteredData.last.estimated1Rm;
    final before = _filteredData
        .where((d) => d.date.isBefore(monthAgo))
        .fold<double?>(null, (_, e) => e.estimated1Rm);
    if (before == null) return null;
    final diff = recent - before;
    return (diff: diff, percent: (diff / before) * 100);
  }

  Future<void> _openVideo() async {
    final url = widget.videoUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.appBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.exerciseName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageCard(),
            const SizedBox(height: 16),
            _buildMuscleChip(),
            const SizedBox(height: 20),
            _build1RMSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard() {
    final hasThumbnail = widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty;
    final hasVideo = widget.videoUrl != null && widget.videoUrl!.isNotEmpty;

    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // imagen o placeholder
          if (hasThumbnail)
            Image.network(
              widget.thumbnailUrl!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _placeholderIcon(),
            )
          else
            _placeholderIcon(),

          // botón vídeo (esquina inferior derecha)
          if (hasVideo)
            Positioned(
              bottom: 12,
              right: 12,
              child: GestureDetector(
                onTap: _openVideo,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.neonGreen.withValues(alpha: 0.6),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_circle_outline_rounded,
                          color: AppTheme.neonGreen, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Ver vídeo',
                        style: TextStyle(
                          color: AppTheme.neonGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholderIcon() => const Center(
        child: Icon(Icons.fitness_center, size: 64, color: AppTheme.neonGreen),
      );

  Widget _buildMuscleChip() {
    if (widget.muscleGroup == null || widget.muscleGroup!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      children: [
        Chip(
          label: Text(widget.muscleGroup!),
          backgroundColor: AppTheme.neonGreen.withValues(alpha: 0.15),
          labelStyle: const TextStyle(color: AppTheme.neonGreen, fontWeight: FontWeight.w600),
          side: const BorderSide(color: AppTheme.neonGreen, width: 0.5),
        ),
      ],
    );
  }

  Widget _build1RMSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PROGRESO 1RM',
          style: TextStyle(
            color: AppTheme.textGrey,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: CircularProgressIndicator(color: AppTheme.neonGreen))
        else ...[
          _buildChartCard(),
          const SizedBox(height: 12),
          _buildTimePeriodChips(),
          const SizedBox(height: 16),
          _buildStatsCard(),
        ],
      ],
    );
  }

  Widget _buildChartCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SizedBox(
          height: 220,
          child: _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppTheme.textGrey)))
              : _filteredData.length < 2
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bar_chart_rounded, size: 44, color: AppTheme.textGrey),
                          SizedBox(height: 10),
                          Text(
                            'Necesitas al menos 2 sesiones\ncon este ejercicio para ver el gráfico.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : AppLineChart(
                      dataPoints: _filteredData.asMap().entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.estimated1Rm))
                          .toList(),
                      highlightIndex: _highlightIndex,
                      xFormatter: (val) {
                        final i = val.toInt();
                        if (i < 0 || i >= _filteredData.length) return '';
                        return DateFormat('dd/MM').format(_filteredData[i].date);
                      },
                      yFormatter: (val) => '${val.toStringAsFixed(1)}kg',
                    ),
        ),
      );

  Widget _buildTimePeriodChips() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _TimePeriod.values
              .map((p) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(p.label),
                      selected: _period == p,
                      onSelected: (_) {
                        setState(() => _period = p);
                        _applyFilter();
                      },
                      selectedColor: AppTheme.neonGreen,
                      backgroundColor: AppTheme.cardBackground,
                      labelStyle: TextStyle(
                        color: _period == p ? AppTheme.appBackground : AppTheme.textGrey,
                        fontWeight: FontWeight.w600,
                      ),
                      side: const BorderSide(color: ChartTheme.gridColor),
                    ),
                  ))
              .toList(),
        ),
      );

  Widget _buildStatsCard() {
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
            label: 'Máximo histórico (1RM est.)',
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
          const SizedBox(height: 12),
          _statRow(
            icon: Icons.repeat_rounded,
            iconColor: AppTheme.textGrey,
            label: 'Sesiones registradas',
            value: _allData.length.toString(),
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
                Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
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
