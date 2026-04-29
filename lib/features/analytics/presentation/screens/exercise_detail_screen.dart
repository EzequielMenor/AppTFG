import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/chart_theme.dart';
import '../../../../shared/widgets/charts/app_line_chart.dart';
import '../../data/models/analytics_models.dart';
import '../../domain/analytics_period.dart';
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
      final provider = context.read<AnalyticsProvider>();
      final data = await provider.get1RMProgression(widget.exerciseId);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: Text(widget.exerciseName),
        backgroundColor: AppTheme.appBackground,
        actions: [
          if (widget.videoUrl != null)
            IconButton(
              icon: const Icon(Icons.play_circle_outline),
              tooltip: 'Ver video',
              onPressed: () async {
                final uri = Uri.tryParse(widget.videoUrl!);
                if (uri != null &&
                    await canLaunchUrl(uri) == true) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.neonGreen),
            )
          : _error != null
          ? _buildError()
          : _buildContent(),
    );
  }

  Widget _buildError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
        const SizedBox(height: 16),
        Text(_error!, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _load,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen),
          child: const Text('Reintentar',
              style: TextStyle(color: Colors.black)),
        ),
      ],
    ),
  );

  Widget _buildContent() {
    final hasData = _filteredData.isNotEmpty;
    final best1RM = hasData
        ? _filteredData.map((e) => e.estimated1Rm).reduce(
              (a, b) => a > b ? a : b,
            )
        : 0.0;
    final totalEntries = _filteredData.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Row(
            children: [
              if (widget.muscleGroup != null)
                Chip(
                  label: Text(
                    widget.muscleGroup!,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: AppTheme.neonGreen.withOpacity(0.2),
                  side: BorderSide.none,
                ),
              const Spacer(),
              if (widget.thumbnailUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.thumbnailUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Period selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _TimePeriod.values
                  .map(
                    (p) => Padding(
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
                          color: _period == p
                              ? Colors.black
                              : Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        side: const BorderSide(color: ChartTheme.gridColor),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Stats row
          Row(
            children: [
              _buildStat('Best 1RM', '${best1RM.toStringAsFixed(1)} kg'),
              const SizedBox(width: 16),
              _buildStat('Registros', '$totalEntries'),
              const SizedBox(width: 16),
              _buildStat(
                'Periodo',
                _period == _TimePeriod.all ? 'Todo' : _period.label,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Chart
          if (hasData)
            SizedBox(
              height: 280,
              child: AppLineChart(
                spots: _filteredData.asMap().entries.map((entry) {
                  return FlSpot(
                    entry.key.toDouble(),
                    entry.value.estimated1Rm,
                  );
                }).toList(),
                dotColor: AppTheme.neonGreen,
                lineColor: AppTheme.neonGreen.withOpacity(0.7),
                gradientColors: const [
                  AppTheme.neonGreen,
                  AppTheme.neonGreen,
                ],
                xLabels: _filteredData
                    .map(
                      (d) => DateFormat('MMM d').format(d.date),
                    )
                    .toList(),
                yFormatter: (val) => '${val.toStringAsFixed(0)} kg',
              ),
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Sin datos de progresión en este período',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textGrey,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}
