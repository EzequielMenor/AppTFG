import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/analytics_models.dart';
import '../providers/analytics_provider.dart';
import 'exercise_detail_screen.dart';

class ExerciseSearchScreen extends StatefulWidget {
  const ExerciseSearchScreen({super.key});

  @override
  State<ExerciseSearchScreen> createState() => _ExerciseSearchScreenState();
}

class _ExerciseSearchScreenState extends State<ExerciseSearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<ExerciseModel> _exercises = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedMuscle;
  String? _selectedEquipment;

  static const _muscles = [
    'Piernas',
    'Glúteos',
    'Hombros',
    'Pecho',
    'Tríceps',
    'Espalda',
    'Bíceps',
    'Core',
  ];

  static const _equipments = [
    'Barra',
    'Mancuernas',
    'Máquina',
    'Cable',
    'Peso Corporal',
    'Kettlebell',
    'Banda',
  ];

  @override
  void initState() {
    super.initState();
    _fetchExercises();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _fetchExercises);
  }

  Future<void> _fetchExercises() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final provider = context.read<AnalyticsProvider>();
      final results = await provider.getExercisesFiltered(
        name: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        muscleGroup: _selectedMuscle,
        equipment: _selectedEquipment,
        size: 30,
      );
      if (mounted) {
        setState(() {
          _exercises = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar ejercicios';
          _isLoading = false;
        });
      }
    }
  }

  void _selectMuscle(String muscle) {
    setState(() => _selectedMuscle = _selectedMuscle == muscle ? null : muscle);
    _fetchExercises();
  }

  void _selectEquipment(String equipment) {
    setState(
      () => _selectedEquipment =
          _selectedEquipment == equipment ? null : equipment,
    );
    _fetchExercises();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: const Text('Buscar ejercicios'),
        backgroundColor: AppTheme.appBackground,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar ejercicio…',
                hintStyle: const TextStyle(color: AppTheme.textGrey),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textGrey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textGrey),
                        onPressed: () {
                          _searchController.clear();
                          _fetchExercises();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Muscle filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _muscles
                  .map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(m,
                            style: const TextStyle(fontSize: 12)),
                        selected: _selectedMuscle == m,
                        onSelected: (_) => _selectMuscle(m),
                        selectedColor: AppTheme.neonGreen,
                        backgroundColor: AppTheme.cardBackground,
                        checkmarkColor: Colors.black,
                        labelStyle: TextStyle(
                          color: _selectedMuscle == m
                              ? Colors.black
                              : Colors.white70,
                        ),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Equipment filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _equipments
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(e,
                            style: const TextStyle(fontSize: 12)),
                        selected: _selectedEquipment == e,
                        onSelected: (_) => _selectEquipment(e),
                        selectedColor: Colors.orangeAccent,
                        backgroundColor: AppTheme.cardBackground,
                        checkmarkColor: Colors.black,
                        labelStyle: TextStyle(
                          color: _selectedEquipment == e
                              ? Colors.black
                              : Colors.white70,
                        ),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.neonGreen),
                  )
                : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  )
                : _exercises.isEmpty
                ? const Center(
                    child: Text(
                      'No se encontraron ejercicios',
                      style: TextStyle(color: AppTheme.textGrey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _exercises.length,
                    itemBuilder: (_, i) {
                      final ex = _exercises[i];
                      return _ExerciseResultTile(
                        exercise: ex,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExerciseDetailScreen(
                                exerciseId: ex.id,
                                exerciseName: ex.name,
                                muscleGroup: ex.muscleGroup,
                                thumbnailUrl: ex.thumbnailUrl,
                                videoUrl: ex.videoUrl,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseResultTile extends StatelessWidget {
  final ExerciseModel exercise;
  final VoidCallback onTap;

  const _ExerciseResultTile({
    required this.exercise,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final muscleColor = exercise.muscleGroup != null
        ? _muscleColor(exercise.muscleGroup!)
        : AppTheme.textGrey;

    return Card(
      color: AppTheme.cardBackground,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: exercise.thumbnailUrl != null &&
                  exercise.thumbnailUrl!.isNotEmpty
              ? Image.network(
                  exercise.thumbnailUrl!,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _defaultIcon(),
                )
              : _defaultIcon(),
        ),
        title: Text(
          exercise.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: muscleColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                exercise.muscleGroup ?? 'Sin grupo',
                style: TextStyle(color: muscleColor, fontSize: 10),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textGrey),
        onTap: onTap,
      ),
    );
  }

  Widget _defaultIcon() => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: AppTheme.neonGreen.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.fitness_center, color: AppTheme.neonGreen, size: 22),
  );

  Color _muscleColor(String muscle) {
    switch (muscle.toLowerCase()) {
      case 'piernas':
      case 'quadriceps':
      case 'isquiotibiales':
        return Colors.blueAccent;
      case 'glúteos':
        return Colors.purpleAccent;
      case 'hombros':
      case 'deltoides':
        return Colors.orangeAccent;
      case 'pecho':
        return Colors.redAccent;
      case 'tríceps':
        return Colors.tealAccent;
      case 'espalda':
        return Colors.greenAccent;
      case 'bíceps':
        return Colors.cyanAccent;
      case 'core':
      case 'abdominales':
        return Colors.yellowAccent;
      default:
        return AppTheme.textGrey;
    }
  }
}
