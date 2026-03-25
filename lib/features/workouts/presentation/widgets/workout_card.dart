import 'package:flutter/material.dart';
import 'package:gym_analytics_mobile/features/workouts/presentation/screens/workout_detail_screen.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

class WorkoutCard extends StatelessWidget {
  final dynamic workout;
  final VoidCallback? onDeleted;

  const WorkoutCard({super.key, required this.workout, this.onDeleted});

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('MMM d, yyyy').format(date); // Ej: Oct 24, 2023
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalVolume = workout['totalVolume'] != null
        ? '${double.parse(workout['totalVolume'].toString()).toStringAsFixed(0)} kg'
        : '0 kg';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          12,
        ), // Ajusta al radio de tu tarjeta
        onTap: () async {
          final deleted = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  WorkoutDetailScreen(workoutId: workout['id']),
            ),
          );
          if (deleted == true) onDeleted?.call();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            // Línea verde a la izquierda como en el mockup
            border: const Border(
              left: BorderSide(color: AppTheme.neonGreen, width: 4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icono cuadrado redondeado
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: AppTheme.neonGreen,
                  ),
                ),
                const SizedBox(width: 16),

                // Info Central
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout['name'] ?? 'Entrenamiento',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: AppTheme.textGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(workout['startTime'] ?? ''),
                            style: const TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.line_weight,
                            size: 14,
                            color: AppTheme.textGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            totalVolume,
                            style: const TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Icono flecha derecha
                const Icon(Icons.chevron_right, color: AppTheme.textGrey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
