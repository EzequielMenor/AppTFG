import 'package:flutter/material.dart';

class AppTheme {
  // --- COLORES BASADOS EN EL MOCKUP ---
  static const Color appBackground = Color(
    0xFF121212,
  ); // Fondo principal muy oscuro
  static const Color cardBackground = Color(
    0xFF1E1E1E,
  ); // Gris oscuro para tarjetas
  static const Color neonGreen = Color(0xFF00FF7F); // El verde de acento
  static const Color textGrey = Color(0xFFAAAAAA);

  static ThemeData get darkTheme {
    return ThemeData(
      scaffoldBackgroundColor: appBackground,
      colorScheme: const ColorScheme.dark(
        primary: neonGreen,
        surface: appBackground,
        surfaceContainer: cardBackground,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: appBackground,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: appBackground,
        selectedItemColor: neonGreen,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
