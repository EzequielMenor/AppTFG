import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/analytics_datasource.dart';
import '../../data/models/analytics_models.dart';
import 'exercise_detail_screen.dart';

class ExerciseSearchScreen extends StatefulWidget {
  const ExerciseSearchScreen({super.key});

  @override
  State<ExerciseSearchScreen> createState() => _ExerciseSearchScreenState();
}

class _ExerciseSearchScreenState extends State<ExerciseSearchScreen> {
  final _datasource = AnalyticsDatasource();
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
      final results = await _datasource.getExercisesFiltered(
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
        () => _selectedEquipment = _selectedEquipment == equipment ? null : equipment);
    _fetchExercises();
  }

  void _openDetail(ExerciseModel exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseDetailScreen(
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          muscleGroup: exercise.muscleGroup,
          thumbnailUrl: exercise.thumbnailUrl,
          videoUrl: exercise.videoUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: const Text('EJERCICIOS'),
        backgroundColor: AppTheme.appBackground,
      ),
      body: Column(
        children: [
          _buildSearchField(),
          _buildFilterChips(
            items: _muscles,
            selected: _selectedMuscle,
            accentColor: AppTheme.neonGreen,
            onSelect: _selectMuscle,
          ),
          _buildFilterChips(
            items: _equipments,
            selected: _selectedEquipment,
            accentColor: const Color(0xFF00BFFF),
            onSelect: _selectEquipment,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Buscar ejercicio...',
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
    );
  }

  Widget _buildFilterChips({
    required List<String> items,
    required String? selected,
    required Color accentColor,
    required void Function(String) onSelect,
  }) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: items.map((item) {
          final isSelected = selected == item;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(item),
              selected: isSelected,
              onSelected: (_) => onSelect(item),
              selectedColor: accentColor,
              checkmarkColor: Colors.black,
              backgroundColor: AppTheme.cardBackground,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 12,
              ),
              side: BorderSide.none,
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.neonGreen));
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!,
                style: const TextStyle(color: AppTheme.textGrey)),
            const SizedBox(height: 12),
            TextButton(
                onPressed: _fetchExercises,
                child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (_exercises.isEmpty) {
      return const Center(
        child: Text('Sin resultados',
            style: TextStyle(color: AppTheme.textGrey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _exercises.length,
      itemBuilder: (context, index) => _ExerciseCard(
        exercise: _exercises[index],
        onTap: () => _openDetail(_exercises[index]),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final ExerciseModel exercise;
  final VoidCallback onTap;

  const _ExerciseCard({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: exercise.thumbnailUrl != null
                  ? Image.network(
                      exercise.thumbnailUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (exercise.muscleGroup != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      exercise.muscleGroup!,
                      style: const TextStyle(
                          color: AppTheme.textGrey, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textGrey),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.fitness_center,
          color: AppTheme.textGrey, size: 28),
    );
  }
}
