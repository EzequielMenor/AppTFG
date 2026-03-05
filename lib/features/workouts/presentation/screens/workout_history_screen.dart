import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../../../../core/theme/app_theme.dart';
import '../widgets/workout_card.dart';

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
      // Obtenemos el token de la sesión actual de Supabase
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;

      if (token == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // IMPORTANTE: Ya no mandamos el email en la URL, el backend lo saca del Token
      final url = Uri.parse(
        'http://localhost:8080/api/workouts?page=0&size=20',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(
          utf8.decode(response.bodyBytes),
        );
        if (mounted) {
          setState(() {
            _workouts = data['content'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppTheme.textGrey),
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
                    child: CircularProgressIndicator(color: AppTheme.neonGreen),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _workouts.length,
                    itemBuilder: (context, index) {
                      final workout = _workouts[index];
                      return WorkoutCard(workout: workout);
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
          color: isSelected ? Colors.black : AppTheme.textGrey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor: isSelected
          ? AppTheme.neonGreen
          : AppTheme.cardBackground,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
