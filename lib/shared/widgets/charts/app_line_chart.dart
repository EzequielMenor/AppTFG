import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/chart_theme.dart';

class AppLineChart extends StatefulWidget {
  final List<FlSpot> dataPoints;
  final String xLabel;
  final String yLabel;
  final Color lineColor;
  final String Function(double) xFormatter;
  final String Function(double) yFormatter;

  /// Índice del punto a resaltar en dorado (ej. el máximo histórico).
  final int? highlightIndex;

  const AppLineChart({
    super.key,
    required this.dataPoints,
    required this.xFormatter,
    required this.yFormatter,
    this.xLabel = '',
    this.yLabel = '',
    this.lineColor = ChartTheme.lineColor,
    this.highlightIndex,
  });

  @override
  State<AppLineChart> createState() => _AppLineChartState();
}

class _AppLineChartState extends State<AppLineChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.dataPoints.isEmpty) {
      return const Center(
        child: Text('Sin datos', style: TextStyle(color: ChartTheme.axisTextColor)),
      );
    }

    final minY = widget.dataPoints.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = widget.dataPoints.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final yMargin = (maxY - minY) * 0.1;

    return LineChart(
      LineChartData(
        minY: minY - yMargin,
        maxY: maxY + yMargin,
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
              getTitlesWidget: (val, meta) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  widget.xFormatter(val),
                  style: ChartTheme.axisTitleStyle,
                ),
              ),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineTouchData: LineTouchData(
          touchCallback: (event, response) {
            setState(() {
              if (response?.lineBarSpots != null && event is FlTapUpEvent) {
                _touchedIndex = response!.lineBarSpots!.first.spotIndex;
              } else if (event is FlTapUpEvent) {
                _touchedIndex = null;
              }
            });
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => ChartTheme.tooltipBackground,
            tooltipBorder: const BorderSide(color: ChartTheme.tooltipBorder, width: 1),
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      widget.xFormatter(s.x),
                      ChartTheme.tooltipTitleStyle,
                      children: [
                        TextSpan(
                          text: '\n${widget.yFormatter(s.y)}',
                          style: ChartTheme.tooltipValueStyle,
                        )
                      ],
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: widget.dataPoints,
            isCurved: true,
            curveSmoothness: 0.3,
            color: widget.lineColor,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                final isHighlight = index == widget.highlightIndex;
                final isTouched = index == _touchedIndex;
                final color = isHighlight
                    ? ChartTheme.maxPointColor
                    : (isTouched ? Colors.white : widget.lineColor);
                return FlDotCirclePainter(
                  radius: isHighlight ? 5 : (isTouched ? 4 : 3),
                  color: color,
                  strokeWidth: 0,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: ChartTheme.areaGradient,
            ),
          ),
        ],
      ),
    );
  }
}
