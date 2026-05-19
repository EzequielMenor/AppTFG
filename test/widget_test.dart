import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gym_analytics_mobile/app.dart';
import 'package:gym_analytics_mobile/features/auth/presentation/providers/auth_provider.dart';

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    await Supabase.initialize(
      url: 'https://xiggoajtomuwtbarjtvj.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhpZ2dvYWp0b211d3RiYXJqdHZqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxNDExODUsImV4cCI6MjA4NTcxNzE4NX0.SXg1cMSbqGHJ4fwSe5q9a_QQLQlYjsLcGLWLZauppbg',
    );
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const GymAnalyticsApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
