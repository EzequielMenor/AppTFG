import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/workout_provider.dart';
import '../widgets/workout_card.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  String _selectedChip = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutProvider>().loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final user = context.watch<AuthProvider>().user;
    final initial = (user?.email.isNotEmpty == true)
        ? user!.email[0].toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.neonGreen),
            onPressed: () => context.read<WorkoutProvider>().loadHistory(),
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
          // Filters
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildChip('All Workouts', 'all'),
                const SizedBox(width: 8),
                _buildChip('Routines', 'routines'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Stale indicator
          if (provider.isUsingStaleData)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.withValues(alpha: 0.1),
              child: const Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Actualizando…',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          // Content
          Expanded(
            child: provider.isLoading && !provider.hasLoadedOnce
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.neonGreen),
                  )
                : provider.errorMessage != null && !provider.isUsingStaleData
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.wifi_off,
                            size: 64,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                context.read<WorkoutProvider>().loadHistory(),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  )
                : provider.workouts.isEmpty
                ? const Center(
                    child: Text('No hay entrenamientos. ¡Importa tu CSV!'),
                  )
                : RefreshIndicator(
                    onRefresh: () =>
                        context.read<WorkoutProvider>().loadHistory(),
                    color: AppTheme.neonGreen,
                    backgroundColor: AppTheme.cardBackground,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: provider.workouts.length,
                      itemBuilder: (context, index) {
                        final workout = provider.workouts[index];
                        return WorkoutCard(
                          workout: workout,
                          onDeleted: () =>
                              context.read<WorkoutProvider>().deleteWorkout(workout.id),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String chipId) {
    final isSelected = _selectedChip == chipId;
    return GestureDetector(
      onTap: () {
        if (chipId == 'routines') {
          context.push('/routines');
        } else {
          setState(() => _selectedChip = chipId);
        }
      },
      child: Chip(
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
      ),
    );
  }
}
