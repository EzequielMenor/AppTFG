import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/chart_theme.dart';

class AppBarChart extends StatefulWidget {
  final List<double> values;
  final List<String> labels;
  final String xLabel;
  final String yLabel;
  final String Function(double) yFormatter;
  final int? labelInterval; // show every N-th label; null = show all

  const AppBarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.yFormatter,
    this.xLabel = '',
    this.yLabel = '',
    this.labelInterval,
  }) : assert(values.length == labels.length, 'values and labels must be the same length');

  @override
  State<AppBarChart> createState() => _AppBarChartState();
}

class _AppBarChartState extends State<AppBarChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.values.isEmpty) {
      return const Center(
        child: Text('Sin datos', style: TextStyle(color: ChartTheme.axisTextColor)),
      );
    }

    final maxY = widget.values.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: maxY * 1.15,
        gridData: ChartTheme.defaultGridData,
        borderData: ChartTheme.hiddenBorder,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (val, meta) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  widget.yFormatter(val),
                  style: ChartTheme.axisTitleStyle,
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (val, meta) {
                final index = val.toInt();
                if (index < 0 || index >= widget.labels.length) {
                  return const SizedBox.shrink();
                }
                final interval = widget.labelInterval ?? 1;
                if (interval > 1 && index % interval != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(widget.labels[index], style: ChartTheme.axisTitleStyle),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barTouchData: BarTouchData(
          touchCallback: (event, response) {
            setState(() {
              if (response?.spot != null && event is! FlTapUpEvent) {
                _touchedIndex = response!.spot!.touchedBarGroupIndex;
              } else {
                _touchedIndex = -1;
              }
            });
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => ChartTheme.tooltipBackground,
            tooltipBorder: const BorderSide(color: ChartTheme.tooltipBorder, width: 1),
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              widget.labels[groupIndex],
              ChartTheme.tooltipTitleStyle,
              children: [
                TextSpan(
                  text: '\n${widget.yFormatter(rod.toY)}',
                  style: ChartTheme.tooltipValueStyle,
                ),
              ],
            ),
          ),
        ),
        barGroups: List.generate(widget.values.length, (i) {
          final isTouched = i == _touchedIndex;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: widget.values[i],
                width: isTouched ? 20 : 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                gradient: ChartTheme.barGradient,
              ),
            ],
          );
        }),
      ),
    );
  }
}
