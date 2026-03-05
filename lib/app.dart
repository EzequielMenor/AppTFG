import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

class GymAnalyticsApp extends StatelessWidget {
  const GymAnalyticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos el authProvider para inyectarlo en el router
    final authProvider = context.watch<AuthProvider>();

    // IMPORTANTE: Llamamos a createRouter pasando el AuthProvider
    final router = AppRouter.createRouter(authProvider);

    return MaterialApp.router(
      title: 'GymAnalytics',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
