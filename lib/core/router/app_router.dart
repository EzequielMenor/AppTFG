import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/main_layout.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class AppRouter {
  // Configuración del router con lógica de redirección
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/welcome', // Inicialmente mandamos al Welcome
      // Escuchamos el authProvider: Si hay un login/logout, re-evaluamos la ruta
      refreshListenable: authProvider,

      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isAuthRoute =
            state.matchedLocation == '/welcome' ||
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        // Si NO está autenticado y NO está en una pantalla de auth -> Mandar al Welcome
        if (!isAuthenticated && !isAuthRoute) {
          return '/welcome';
        }

        // Si SÍ está autenticado y está en la pantalla de auth -> Mandar al Home
        if (isAuthenticated && isAuthRoute) {
          return '/home';
        }

        // Dejar que siga su curso
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
        GoRoute(path: '/home', builder: (context, state) => const MainLayout()),
      ],
    );
  }
}
