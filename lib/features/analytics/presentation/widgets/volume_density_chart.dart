import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/analytics_models.dart';

class VolumeDensityChart extends StatelessWidget {
  final VolumeDensityModel data;

  const VolumeDensityChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final values = [data.previousDensity, data.currentDensity];
    final maxY = (values.reduce((a, b) => a > b ? a : b) * 1.3).ceilToDouble();
    final isPositive = data.changePercent >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _statCol('Periodo anterior', '${data.previousDensity.toStringAsFixed(1)} kg/set'),
            const SizedBox(width: 24),
            _statCol('Periodo actual', '${data.currentDensity.toStringAsFixed(1)} kg/set'),
            const Spacer(),
            _changeBadge(isPositive),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: BarChart(
            BarChartData(
              maxY: maxY == 0 ? 10 : maxY,
              minY: 0,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final labels = ['Anterior', 'Actual'];
                      final idx = value.toInt();
                      if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(labels[idx],
                            style: const TextStyle(color: AppTheme.textGrey, fontSize: 10)),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                _bar(0, data.previousDensity, Colors.white24),
                _bar(1, data.currentDensity, AppTheme.neonGreen),
              ],
            ),
          ),
        ),
      ],
    );
  }

  BarChartGroupData _bar(int x, double y, Color color) => BarChartGroupData(
        x: x,
        barRods: [
          BarChartRodData(
            toY: y,
            color: color,
            width: 40,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );

  Widget _statCol(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      );

  Widget _changeBadge(bool isPositive) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (isPositive ? AppTheme.neonGreen : Colors.redAccent).withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${isPositive ? '+' : ''}${data.changePercent.toStringAsFixed(1)}%',
          style: TextStyle(
              color: isPositive ? AppTheme.neonGreen : Colors.redAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold),
        ),
      );
}
