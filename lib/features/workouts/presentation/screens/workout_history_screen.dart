import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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
      final response = await ApiClient.get(
        '/api/workouts',
        queryParams: {'page': '0', 'size': '20'},
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
    final user = context.watch<AuthProvider>().user;
    final initial = (user?.email?.isNotEmpty == true)
        ? user!.email![0].toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppTheme.textGrey),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.neonGreen,
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
