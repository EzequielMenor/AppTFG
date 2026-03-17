import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

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
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: const GymAnalyticsApp(),
    ),
  );
}
