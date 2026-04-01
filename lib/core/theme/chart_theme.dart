import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

abstract class ChartTheme {
  // --- Colores base ---
  static const Color gridColor = Color(0xFF2C2C2C);
  static const Color axisColor = Color(0xFF444444);
  static const Color lineColor = Color(0xFF00E676);
  static const Color barColorTop = Color(0xFF00E676);
  static const Color barColorBottom = Color(0xFF004D25);
  static const Color tooltipBackground = Color(0xFF1E1E1E);
  static const Color tooltipBorder = Color(0xFF00E676);
  static const Color maxPointColor = Color(0xFFFFD700);
  static const Color axisTextColor = Color(0xFFAAAAAA);
  static const Color areaGradientTop = Color(0x4D00E676); // 30% opacity
  static const Color areaGradientBottom = Color(0x0D00E676); // 5% opacity

  // --- Estilos de texto ---
  static const TextStyle axisTitleStyle = TextStyle(
    color: axisTextColor,
    fontSize: 10,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle tooltipTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle tooltipValueStyle = TextStyle(
    color: lineColor,
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );

  // --- Configuración de grid ---
  static FlGridData get defaultGridData => FlGridData(
    show: true,
    drawVerticalLine: false,
    horizontalInterval: null,
    getDrawingHorizontalLine: (_) => FlLine(
      color: gridColor,
      strokeWidth: 1,
    ),
  );

  // --- Configuración de ejes ---
  static FlBorderData get hiddenBorder => FlBorderData(show: false);

  // --- Gradiente bajo la curva ---
  static LinearGradient get areaGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [areaGradientTop, areaGradientBottom],
  );

  // --- Gradiente para barras ---
  static LinearGradient get barGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [barColorTop, barColorBottom],
  );
}
