import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';

class MainLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  static const _activeColor = Color(0xFF00E676);
  static const _inactiveColor = Color(0xFF6B6B6B);
  static const _navBg = Color(0xFF1A1A1A);
  static const _navBorder = Color(0xFF2C2C2C);

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 600) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: _buildBottomNavBar(),
            floatingActionButton: _buildFab(),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
          );
        }

        return Scaffold(
          body: Row(
            children: [
              _buildNavigationRail(extended: width >= 900),
              const VerticalDivider(width: 1, color: _navBorder),
              Expanded(child: navigationShell),
            ],
          ),
          floatingActionButton: _buildFab(),
        );
      },
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: _navBg,
        border: Border(top: BorderSide(color: _navBorder)),
      ),
      child: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        backgroundColor: _navBg,
        selectedItemColor: _activeColor,
        unselectedItemColor: _inactiveColor,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: Icon(PhosphorIconsRegular.house),
            activeIcon: Icon(PhosphorIconsFill.house, color: _activeColor),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(PhosphorIconsRegular.clockCounterClockwise),
            activeIcon: Icon(
              PhosphorIconsFill.clockCounterClockwise,
              color: _activeColor,
            ),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Icon(PhosphorIconsRegular.chartBar),
            activeIcon: Icon(PhosphorIconsFill.chartBar, color: _activeColor),
            label: 'Analíticas',
          ),
          BottomNavigationBarItem(
            icon: Icon(PhosphorIconsRegular.user),
            activeIcon: Icon(PhosphorIconsFill.user, color: _activeColor),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail({required bool extended}) {
    return NavigationRail(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: _onTap,
      extended: extended,
      backgroundColor: _navBg,
      selectedIconTheme: const IconThemeData(color: _activeColor),
      unselectedIconTheme: const IconThemeData(color: _inactiveColor),
      selectedLabelTextStyle: const TextStyle(
        color: _activeColor,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelTextStyle: const TextStyle(color: _inactiveColor),
      destinations: [
        NavigationRailDestination(
          icon: Icon(PhosphorIconsRegular.house),
          selectedIcon: Icon(PhosphorIconsFill.house),
          label: const Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(PhosphorIconsRegular.clockCounterClockwise),
          selectedIcon: Icon(PhosphorIconsFill.clockCounterClockwise),
          label: const Text('Historial'),
        ),
        NavigationRailDestination(
          icon: Icon(PhosphorIconsRegular.chartBar),
          selectedIcon: Icon(PhosphorIconsFill.chartBar),
          label: const Text('Analíticas'),
        ),
        NavigationRailDestination(
          icon: Icon(PhosphorIconsRegular.user),
          selectedIcon: Icon(PhosphorIconsFill.user),
          label: const Text('Perfil'),
        ),
      ],
    );
  }

  Widget _buildFab() {
    return Builder(
      builder: (context) => FloatingActionButton(
        backgroundColor: AppTheme.neonGreen,
        foregroundColor: Colors.black,
        elevation: 8,
        shape: const CircleBorder(),
        onPressed: () => context.push('/pre-workout'),
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }
}
