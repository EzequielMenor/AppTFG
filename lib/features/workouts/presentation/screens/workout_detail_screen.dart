import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final int workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _workout;
  bool _visible = false; // Para la animación de entrada

  @override
  void initState() {
    super.initState();
    _fetchWorkout();
  }

  Future<void> _fetchWorkout() async {
    try {
      final response = await ApiClient.get('/api/workouts/${widget.workoutId}');
      if (response.statusCode == 200) {
        setState(() {
          _workout = json.decode(utf8.decode(response.bodyBytes));
          _isLoading = false;
        });
        // Disparamos la animación un frame después de renderizar
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) setState(() => _visible = true);
        });
      }
    } catch (e) {
      // Idealmente, mostrar un banner o snackbar de error de conexión aquí
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteWorkout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Eliminar', style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Estás seguro de eliminar este entrenamiento?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await ApiClient.delete(
          '/api/workouts/${widget.workoutId}',
        );
        if (response.statusCode == 204 || response.statusCode == 200) {
          if (!mounted) return;
          Navigator.pop(context); // Volvemos al history
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entrenamiento eliminado')),
          );
        }
      } catch (e) {
        // Manejo de error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Próximamente')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: _deleteWorkout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.neonGreen),
            )
          : _workout == null
          ? const Center(
              child: Text(
                'Error al cargar',
                style: TextStyle(color: Colors.white),
              ),
            )
          : AnimatedOpacity(
              opacity: _visible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: _buildContent(),
            ),
    );
  }

  Widget _buildContent() {
    final startTime = DateTime.parse(_workout!['startTime']);
    final endTime = DateTime.parse(_workout!['endTime']);
    final durationMins = endTime.difference(startTime).inMinutes;
    final String dateStr = DateFormat(
      'EEEE, d \'de\' MMMM \'de\' yyyy',
      'es_ES',
    ).format(startTime);
    final List exercises = _workout!['workoutExercises'] ?? [];

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // HEADER
        Text(
          _workout!['name'] ?? 'Entrenamiento',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          dateStr.toUpperCase(),
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 16),

        // CHIPS (Volumen y Duración)
        Row(
          children: [
            Chip(
              backgroundColor: AppTheme.cardBackground,
              label: Text(
                '$durationMins min',
                style: const TextStyle(color: Colors.white),
              ),
              avatar: const Icon(
                Icons.timer,
                color: AppTheme.neonGreen,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Chip(
              backgroundColor: AppTheme.cardBackground,
              label: Text(
                '${_workout!['totalVolume']} kg',
                style: const TextStyle(color: Colors.white),
              ),
              avatar: const Icon(
                Icons.fitness_center,
                color: AppTheme.neonGreen,
                size: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // LISTA DE EJERCICIOS
        ...exercises.map((ex) => _buildExerciseTile(ex)).toList(),

        // NOTAS DEL WORKOUT
        if (_workout!['notes'] != null &&
            _workout!['notes'].toString().isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notas del entrenamiento',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  _workout!['notes'],
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildExerciseTile(Map<String, dynamic> exerciseData) {
    final exerciseInfo = exerciseData['exercise'];
    final List series = exerciseData['series'] ?? [];

    return Theme(
      // Evita los bordes feos por defecto del ExpansionTile al expandir
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        iconColor: AppTheme.neonGreen,
        collapsedIconColor: Colors.grey,
        title: Row(
          children: [
            Expanded(
              child: Text(
                exerciseInfo['name'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                exerciseInfo['muscleGroup'],
                style: const TextStyle(color: AppTheme.neonGreen, fontSize: 10),
              ),
            ),
          ],
        ),
        children: [
          if (exerciseData['notes'] != null &&
              exerciseData['notes'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  exerciseData['notes'],
                  style: const TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ...series
              .map(
                (serie) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Serie ${serie['setOrder']}: ',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '${serie['weight']} kg × ${serie['reps']} reps',
                        style: const TextStyle(
                          color: AppTheme.neonGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ' [RPE: ${serie['rpe']}]',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      if (serie['isWarmup'] == true) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Warmup',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
              .toList(),
          const SizedBox(
            height: 12,
          ), // Espaciador para respirar entre ejercicios
        ],
      ),
    );
  }
}
