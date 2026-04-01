import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/analytics_models.dart';

class TrainingStyleChart extends StatelessWidget {
  final TrainingStyleModel data;

  const TrainingStyleChart({super.key, required this.data});

  static const _strengthColor = Color(0xFF4FC3F7);
  static const _hypertrophyColor = AppTheme.neonGreen;
  static const _enduranceColor = Color(0xFFFFB74D);

  @override
  Widget build(BuildContext context) {
    final total = data.strengthSets + data.hypertrophySets + data.enduranceSets;
    if (total == 0) {
      return const Text('Sin datos en este periodo',
          style: TextStyle(color: Colors.white54, fontSize: 13));
    }

    return Row(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: [
                if (data.strengthSets > 0)
                  _section(data.strengthSets, total, _strengthColor),
                if (data.hypertrophySets > 0)
                  _section(data.hypertrophySets, total, _hypertrophyColor),
                if (data.enduranceSets > 0)
                  _section(data.enduranceSets, total, _enduranceColor),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _legendRow('Fuerza', '≤ 5 reps', data.strengthSets, total, _strengthColor),
              const SizedBox(height: 10),
              _legendRow('Hipertrofia', '6-12 reps', data.hypertrophySets, total, _hypertrophyColor),
              const SizedBox(height: 10),
              _legendRow('Resistencia', '> 12 reps', data.enduranceSets, total, _enduranceColor),
            ],
          ),
        ),
      ],
    );
  }

  PieChartSectionData _section(int value, int total, Color color) {
    final pct = value / total * 100;
    return PieChartSectionData(
      value: value.toDouble(),
      color: color,
      radius: 28,
      title: '${pct.toStringAsFixed(0)}%',
      titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
    );
  }

  Widget _legendRow(String name, String range, int sets, int total, Color color) {
    final pct = total > 0 ? sets / total * 100 : 0.0;
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$name ($range)',
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
              Text('$sets sets · ${pct.toStringAsFixed(0)}%',
                  style: const TextStyle(color: AppTheme.textGrey, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }
}
