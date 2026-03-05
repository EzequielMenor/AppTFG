import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../features/workouts/presentation/screens/workout_history_screen.dart';

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
      body: IndexedStack(index: _currentIndex, children: _screens),
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
        backgroundColor: AppTheme.neonGreen,
        foregroundColor: Colors.black, // "+" en negro como en el diseño
        elevation: 8,
        shape: const CircleBorder(),
        onPressed: () {
          // TODO: Abrir pantalla de crear entreno (EZE-88)
        },
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
