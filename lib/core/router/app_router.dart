import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets/main_layout.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/workouts/presentation/screens/workout_history_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/history',
      refreshListenable: authProvider,

      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isAuthRoute =
            state.matchedLocation == '/welcome' ||
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        if (!isAuthenticated && !isAuthRoute) {
          return '/welcome';
        }

        if (isAuthenticated && isAuthRoute) {
          return '/history';
        }

        return null;
      },

      routes: [
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainLayout(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Dashboard'),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const WorkoutHistoryScreen(),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/analytics',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Analíticas'),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ]),
          ],
        ),
      ],
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final initial = (user?.email?.isNotEmpty == true)
        ? user!.email![0].toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF00E676),
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(color: Colors.white54, fontSize: 18),
        ),
      ),
    );
  }
}
