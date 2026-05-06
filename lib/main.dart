import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/analytics/presentation/providers/analytics_provider.dart';
import 'features/workouts/presentation/providers/workout_provider.dart';
import 'features/workouts/presentation/providers/workout_tracker_provider.dart';
import 'features/workouts/presentation/providers/routine_provider.dart';
import 'features/profile/presentation/providers/profile_provider.dart';
import 'features/profile/data/datasources/profile_local_datasource.dart';
import 'features/profile/data/datasources/profile_remote_datasource.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/domain/profile_repository.dart';
import 'features/analytics/data/datasources/analytics_datasource.dart';
import 'features/analytics/data/repositories/analytics_repository_impl.dart';
import 'features/analytics/domain/analytics_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  await initializeDateFormatting('en_US', null);

  // Inicializamos Supabase con las credenciales extraídas del backend
  await Supabase.initialize(
    url: 'https://xiggoajtomuwtbarjtvj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhpZ2dvYWp0b211d3RiYXJqdHZqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxNDExODUsImV4cCI6MjA4NTcxNzE4NX0.SXg1cMSbqGHJ4fwSe5q9a_QQLQlYjsLcGLWLZauppbg',
  );

  runApp(
    // Inyectamos el AuthProvider en la raíz de la app
    MultiProvider(
      providers: [
        // ── Capa de infraestructura (sin dependencias) ──
        Provider<AnalyticsDatasource>(
          create: (_) => AnalyticsDatasource(),
        ),
        Provider<ProfileLocalDatasource>(
          create: (_) => ProfileLocalDatasource(),
        ),
        Provider<ProfileRemoteDatasource>(
          create: (_) => ProfileRemoteDatasource(),
        ),

        // ── Repositories (dependen de datasources) ──
        Provider<IAnalyticsRepository>(
          create: (ctx) => AnalyticsRepositoryImpl(
            remote: ctx.read<AnalyticsDatasource>(),
          ),
        ),
        Provider<IProfileRepository>(
          create: (ctx) => ProfileRepositoryImpl(
            local: ctx.read<ProfileLocalDatasource>(),
            remote: ctx.read<ProfileRemoteDatasource>(),
          ),
        ),

        // ── Providers/ViewModels (dependen de repositories) ──
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (ctx) => AnalyticsProvider(
            repository: ctx.read<IAnalyticsRepository>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutTrackerProvider()),
        ChangeNotifierProvider(create: (_) => RoutineProvider()),
        ChangeNotifierProvider(
          create: (ctx) => ProfileProvider(
            repository: ctx.read<IProfileRepository>(),
          ),
        ),
      ],
      child: const GymAnalyticsApp(),
    ),
  );
}
