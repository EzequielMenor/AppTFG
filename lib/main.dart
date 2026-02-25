import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

// --- COLORES BASADOS EN EL MOCKUP ---
const Color appBackground = Color(0xFF121212); // Fondo principal muy oscuro
const Color cardBackground = Color(0xFF1E1E1E); // Gris oscuro para tarjetas
const Color neonGreen = Color(0xFF00FF7F); // El verde de acento
const Color textGrey = Color(0xFFAAAAAA);

void main() {
  runApp(const GymAnalyticsApp());
}

class GymAnalyticsApp extends StatelessWidget {
  const GymAnalyticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymAnalytics',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: appBackground,
        colorScheme: const ColorScheme.dark(
          primary: neonGreen,
          surface: appBackground,
          surfaceContainer: cardBackground,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: appBackground,
          scrolledUnderElevation:
              0, // Esto evita que cambie de color al hacer scroll
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
      ),
      home: const MainLayout(),
    );
  }
}

// --- ESQUELETO PRINCIPAL (Bottom Nav) ---
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 1; // Empezamos en History para ver lo que hemos hecho

  final List<Widget> _screens = [
    const Center(
      child: Text('Dashboard (WIP)', style: TextStyle(color: Colors.white)),
    ), // index 0
    const WorkoutHistoryScreen(), // index 1
    const Center(
      child: Text('Analytics (WIP)', style: TextStyle(color: Colors.white)),
    ), // index 2
    const Center(
      child: Text('Settings (WIP)', style: TextStyle(color: Colors.white)),
    ), // index 3
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: neonGreen,
        foregroundColor: Colors.black, // "+" en negro como en el diseño
        elevation: 8,
        shape: const CircleBorder(),
        onPressed: () {
          // TODO: Abrir pantalla de crear entreno (EZE-88)
        },
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation
          .centerDocked, // Si quieres que esté centrado como en algunas apps, o quítalo para que vaya a la derecha. Lo dejo a la derecha por defecto en Material.
    );
  }
}

// --- PANTALLA HISTORY BASADA EN sc_history.png ---
class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  List<dynamic> _workouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWorkouts();
  }

  Future<void> _fetchWorkouts() async {
    try {
      final url = Uri.parse(
        'http://localhost:8080/api/workouts?email=eze@test.com&page=0&size=20',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(
          utf8.decode(response.bodyBytes),
        );
        setState(() {
          _workouts = data['content'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('MMM d, yyyy').format(date); // Ej: Oct 24, 2023
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: textGrey),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros (Chips horizontales)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildChip('All Workouts', true),
                const SizedBox(width: 8),
                _buildChip('Templates', false),
                const SizedBox(width: 8),
                _buildChip('Routines', false),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Lista de Entrenamientos
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: neonGreen),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _workouts.length,
                    itemBuilder: (context, index) {
                      final workout = _workouts[index];
                      return _buildWorkoutCard(workout);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : textGrey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor: isSelected ? neonGreen : cardBackground,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildWorkoutCard(dynamic workout) {
    final exercisesCount = (workout['exercises'] as List?)?.length ?? 0;
    final totalVolume = workout['totalVolume'] != null
        ? '${double.parse(workout['totalVolume'].toString()).toStringAsFixed(0)} kg'
        : '0 kg';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        // Línea verde a la izquierda como en el mockup
        border: const Border(left: BorderSide(color: neonGreen, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Icono cuadrado redondeado
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.fitness_center, color: neonGreen),
            ),
            const SizedBox(width: 16),

            // Info Central
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout['name'] ?? 'Entrenamiento',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: textGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(workout['startTime'] ?? ''),
                        style: const TextStyle(color: textGrey, fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.line_weight, size: 14, color: textGrey),
                      const SizedBox(width: 4),
                      Text(
                        totalVolume,
                        style: const TextStyle(color: textGrey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Icono flecha derecha
            const Icon(Icons.chevron_right, color: textGrey),
          ],
        ),
      ),
    );
  }
}
