// ignore: do_not_use_environment — este archivo es solo para development/debug.
// TODO: Eliminar o mantener bajo flag kDebugMode antes de release.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/charts/app_bar_chart.dart';
import '../../../../shared/widgets/charts/app_line_chart.dart';

class ChartsPreviewScreen extends StatelessWidget {
  const ChartsPreviewScreen({super.key});

  static const routePath = '/dev/charts-preview';

  @override
  Widget build(BuildContext context) {
    assert(kDebugMode, 'ChartsPreviewScreen solo debe usarse en modo debug');

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: const Text('📊 Charts Preview [DEV]'),
        backgroundColor: AppTheme.appBackground,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('AppLineChart — Progreso 1RM'),
            const SizedBox(height: 8),
            _card(
              SizedBox(
                height: 240,
                child: AppLineChart(
                  dataPoints: _mockLineData(),
                  xFormatter: (val) {
                    final dates = ['01/01', '15/01', '01/02', '15/02', '01/03', '15/03'];
                    final i = val.toInt();
                    return (i >= 0 && i < dates.length) ? dates[i] : '';
                  },
                  yFormatter: (val) => '${val.toStringAsFixed(0)}kg',
                  lineColor: const Color(0xFF00E676),
                  highlightIndex: 5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('AppBarChart — Volumen Semanal'),
            const SizedBox(height: 8),
            _card(
              SizedBox(
                height: 240,
                child: AppBarChart(
                  values: const [12000, 8500, 15000, 11000, 13500, 9000, 16000],
                  labels: const ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'],
                  yFormatter: (val) => '${(val / 1000).toStringAsFixed(0)}k',
                  yLabel: 'kg total',
                ),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('AppLineChart — Estado vacío'),
            const SizedBox(height: 8),
            _card(
              SizedBox(
                height: 120,
                child: AppLineChart(
                  dataPoints: const [],
                  xFormatter: (val) => '',
                  yFormatter: (val) => '',
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      );

  Widget _card(Widget child) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      );

  List<FlSpot> _mockLineData() => const [
        FlSpot(0, 90),
        FlSpot(1, 92.5),
        FlSpot(2, 91),
        FlSpot(3, 95),
        FlSpot(4, 97.5),
        FlSpot(5, 102),
      ];
}
