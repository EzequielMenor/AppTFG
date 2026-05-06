import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/chart_theme.dart';
import '../../../../shared/widgets/charts/app_line_chart.dart';
import '../../domain/analytics_period.dart';
import '../providers/exercise_detail_provider.dart';

class ExerciseDetailScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseDetailProvider>();

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: Text(exerciseName),
        backgroundColor: AppTheme.appBackground,
        actions: [
          if (videoUrl != null)
            IconButton(
              icon: const Icon(Icons.play_circle_outline),
              tooltip: 'Ver video',
              onPressed: () async {
                final uri = Uri.tryParse(videoUrl!);
                if (uri != null && await canLaunchUrl(uri) == true) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.neonGreen),
            )
          : provider.error != null
              ? _buildError(context, provider)
              : _buildContent(context, provider),
    );
  }

  Widget _buildError(BuildContext context, ExerciseDetailProvider provider) =>
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(provider.error!,
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadProgression(exerciseId),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonGreen),
              child: const Text('Reintentar',
                  style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );

  Widget _buildContent(BuildContext context, ExerciseDetailProvider provider) {
    final hasData = provider.filteredData.isNotEmpty;
    final best1RM = provider.best1Rm;
    final totalEntries = provider.totalEntries;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Row(
            children: [
              if (muscleGroup != null)
                Chip(
                  label: Text(
                    muscleGroup!,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: AppTheme.neonGreen.withValues(alpha: 0.2),
                  side: BorderSide.none,
                ),
              const Spacer(),
              if (thumbnailUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    thumbnailUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Period selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AnalyticsPeriod.values
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(p.label),
                        selected: provider.period == p,
                        onSelected: (_) => provider.changePeriod(p),
                        selectedColor: AppTheme.neonGreen,
                        backgroundColor: AppTheme.cardBackground,
                        labelStyle: TextStyle(
                          color: provider.period == p
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
                provider.period == AnalyticsPeriod.all
                    ? 'Todo'
                    : provider.period.label,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Chart
          if (hasData)
            SizedBox(
              height: 280,
              child: AppLineChart(
                dataPoints: provider.filteredData.asMap().entries.map((entry) {
                  return FlSpot(
                    entry.key.toDouble(),
                    entry.value.estimated1Rm,
                  );
                }).toList(),
                xFormatter: (val) {
                  final index = val.toInt();
                  if (index < 0 || index >= provider.filteredData.length) {
                    return '';
                  }
                  return DateFormat('MMM d')
                      .format(provider.filteredData[index].date);
                },
                yFormatter: (val) => '${val.toStringAsFixed(0)} kg',
                lineColor: AppTheme.neonGreen.withValues(alpha: 0.7),
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
