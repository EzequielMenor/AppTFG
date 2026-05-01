import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/analytics_models.dart';

class WeeklyRhythmChart extends StatelessWidget {
  final WeeklyRhythmModel data;

  const WeeklyRhythmChart({super.key, required this.data});

  static const _dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final sessions = data.sessionsByDayOfWeek;
    final maxVal = sessions.isEmpty ? 1 : sessions.reduce((a, b) => a > b ? a : b);
    // Normalise to 0-1 range for RadarChart
    final normalised = sessions.map((v) => maxVal > 0 ? v / maxVal : 0.0).toList();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: RadarChart(
            RadarChartData(
              dataSets: [
                RadarDataSet(
                  dataEntries: normalised.map((v) => RadarEntry(value: v)).toList(),
                  fillColor: AppTheme.neonGreen.withValues(alpha: 0.2),
                  borderColor: AppTheme.neonGreen,
                  borderWidth: 2,
                  entryRadius: 3,
                ),
              ],
              radarBackgroundColor: Colors.transparent,
              borderData: FlBorderData(show: false),
              radarBorderData: const BorderSide(color: Colors.white10),
              gridBorderData: const BorderSide(color: Colors.white10, width: 0.5),
              tickCount: 3,
              tickBorderData: const BorderSide(color: Colors.transparent),
              ticksTextStyle: const TextStyle(fontSize: 0),
              getTitle: (index, angle) => RadarChartTitle(
                text: _dayLabels[index],
                angle: 0,
              ),
              titleTextStyle: const TextStyle(color: AppTheme.textGrey, fontSize: 11),
              titlePositionPercentageOffset: 0.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (i) {
            final cnt = sessions.length > i ? sessions[i] : 0;
            return Column(
              children: [
                Text(_dayLabels[i],
                    style: const TextStyle(color: AppTheme.textGrey, fontSize: 10)),
                const SizedBox(height: 2),
                Text('$cnt',
                    style: TextStyle(
                        color: cnt > 0 ? AppTheme.neonGreen : Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            );
          }),
        ),
      ],
    );
  }
}
