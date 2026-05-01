import 'package:go_router/go_router.dart';
import '../../shared/widgets/main_layout.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/analytics/presentation/screens/one_rm_progression_screen.dart';
import '../../features/analytics/presentation/screens/exercise_search_screen.dart';
import '../../features/workouts/presentation/screens/workout_history_screen.dart';
import '../../features/workouts/presentation/screens/dashboard_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/workouts/presentation/screens/pre_workout_screen.dart';
import '../../features/workouts/presentation/screens/workout_tracker_screen.dart';
import '../../features/workouts/presentation/screens/routines_screen.dart';
import '../../features/workouts/presentation/screens/routine_detail_screen.dart';
import '../../features/workouts/presentation/screens/create_routine_screen.dart';
import '../../features/workouts/data/models/routine_models.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/dashboard',
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
          return '/dashboard';
        }

        return null;
      },

      routes: [
        GoRoute(
          path: '/pre-workout',
          builder: (context, state) => const PreWorkoutScreen(),
        ),
        GoRoute(
          path: '/tracker',
          builder: (context, state) =>
              WorkoutTrackerScreen(startData: state.extra as WorkoutStartData),
        ),
        GoRoute(
          path: '/routines',
          builder: (context, state) => const RoutinesScreen(),
        ),
        GoRoute(
          path: '/create-routine',
          builder: (context, state) => const CreateRoutineScreen(),
        ),
        GoRoute(
          path: '/routine/:id',
          builder: (context, state) =>
              RoutineDetailScreen(routine: state.extra as RoutineModel),
        ),
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
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/dashboard',
                  builder: (context, state) => const DashboardScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/history',
                  builder: (context, state) => const WorkoutHistoryScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/analytics',
                  builder: (context, state) => const AnalyticsScreen(),
                  routes: [
                    GoRoute(
                      path: '1rm',
                      builder: (context, state) =>
                          const OneRmProgressionScreen(),
                    ),
                    GoRoute(
                      path: 'exercises',
                      builder: (context, state) => const ExerciseSearchScreen(),
                    ),
                  ],
                ),
              ],
            ),

            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
