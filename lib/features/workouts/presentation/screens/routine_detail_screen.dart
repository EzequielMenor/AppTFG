import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/routine_datasource.dart';
import '../../data/models/routine_models.dart';
import '../../../../features/analytics/data/datasources/analytics_datasource.dart';
import '../../../../features/analytics/data/models/analytics_models.dart';

class RoutineDetailScreen extends StatefulWidget {
  final RoutineModel routine;

  const RoutineDetailScreen({super.key, required this.routine});

  @override
  State<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  final List<_EditableExercise> _exercises = [];
  bool _saving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.routine.name);
    _descCtrl = TextEditingController(text: widget.routine.description ?? '');

    for (final re in widget.routine.exercises) {
      _exercises.add(
        _EditableExercise(
          exerciseId: re.exerciseId,
          name: re.exerciseName,
          muscleGroup: re.muscleGroup,
          secondaryMuscles: re.secondaryMuscles,
          thumbnailUrl: re.thumbnailUrl,
          sets: re.targetSeries > 0 ? re.targetSeries : 3,
          order: re.exerciseOrder,
        ),
      );
    }

    _nameCtrl.addListener(_markDirty);
    _descCtrl.addListener(_markDirty);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  Future<void> _pickExercise() async {
    final result = await showModalBottomSheet<ExerciseModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      builder: (ctx) => const _ExercisePickerSheet(),
    );
    if (result != null && mounted) {
      if (_exercises.any((e) => e.exerciseId == result.id)) return;
      setState(() {
        _hasChanges = true;
        _exercises.add(
          _EditableExercise(
            exerciseId: result.id,
            name: result.name,
            muscleGroup: result.muscleGroup,
            secondaryMuscles: result.secondaryMuscles,
            thumbnailUrl: result.thumbnailUrl,
            sets: 3,
            order: _exercises.length + 1,
          ),
        );
      });
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre es obligatorio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final exercisesPayload = _exercises.asMap().entries.map((entry) {
        final sets = entry.value.sets;
        return {
          'exerciseId': entry.value.exerciseId,
          'exerciseOrder': entry.key + 1,
          'targetSeries': sets, // legacy compat
          'series': List.generate(sets, (i) => {'setOrder': i + 1}),
        };
      }).toList();

      await RoutineDatasource().updateRoutine(
        id: widget.routine.id,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        exercises: exercisesPayload,
      );

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.cardBackground,
            title: const Text(
              'Descartar cambios',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Tenés cambios sin guardar. ¿Querés descartarlos?',
              style: TextStyle(color: AppTheme.textGrey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text(
                  'Seguir editando',
                  style: TextStyle(color: AppTheme.textGrey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Descartar',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        );
        if (!context.mounted) return;
        if (discard == true) Navigator.of(context).pop(false);
      },
      child: Scaffold(
        backgroundColor: AppTheme.appBackground,
        appBar: AppBar(
          title: const Text('Editar Rutina'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.neonGreen,
                        ),
                      )
                    : const Text(
                        'Guardar',
                        style: TextStyle(
                          color: AppTheme.neonGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Nombre de la rutina *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: _inputDecoration('Descripción (opcional)'),
            ),
            const SizedBox(height: 24),
            if (_exercises.isNotEmpty) ...[
              const Text(
                'EJERCICIOS',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              ..._exercises.asMap().entries.map((entry) {
                final i = entry.key;
                final ex = entry.value;
                return _ExerciseTile(
                  exercise: ex,
                  onChanged: (sets) {
                    setState(() {
                      _hasChanges = true;
                      _exercises[i] = ex.copyWith(sets: sets);
                    });
                  },
                  onRemove: () {
                    setState(() {
                      _hasChanges = true;
                      _exercises.removeAt(i);
                    });
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: _pickExercise,
              icon: const Icon(Icons.add, color: AppTheme.neonGreen),
              label: const Text(
                'Añadir ejercicio',
                style: TextStyle(color: AppTheme.neonGreen),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.neonGreen),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: AppTheme.cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

// ── Editable Exercise Model ────────────────────────────────────────────────────

class _EditableExercise {
  final int exerciseId;
  final String name;
  final String? muscleGroup;
  final List<String> secondaryMuscles;
  final String? thumbnailUrl;
  final int sets;
  final int order;

  const _EditableExercise({
    required this.exerciseId,
    required this.name,
    this.muscleGroup,
    this.secondaryMuscles = const [],
    this.thumbnailUrl,
    required this.sets,
    required this.order,
  });

  _EditableExercise copyWith({int? sets}) {
    return _EditableExercise(
      exerciseId: exerciseId,
      name: name,
      muscleGroup: muscleGroup,
      secondaryMuscles: secondaryMuscles,
      thumbnailUrl: thumbnailUrl,
      sets: sets ?? this.sets,
      order: order,
    );
  }
}

// ── Exercise Tile ──────────────────────────────────────────────────────────────

class _ExerciseTile extends StatelessWidget {
  final _EditableExercise exercise;
  final ValueChanged<int> onChanged;
  final VoidCallback onRemove;

  const _ExerciseTile({
    required this.exercise,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
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
                ),
                if (exercise.muscleGroup != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.neonGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      exercise.muscleGroup!,
                      style: const TextStyle(
                        color: AppTheme.neonGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 52,
            child: TextField(
              controller: TextEditingController(text: exercise.sets.toString()),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (val) {
                final sets = int.tryParse(val);
                if (sets != null && sets > 0) onChanged(sets);
              },
              decoration: InputDecoration(
                labelText: 'Sets',
                labelStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, color: Colors.grey, size: 20),
          ),
        ],
      ),
    );
  }
}

// ── Exercise Picker Bottom Sheet ───────────────────────────────────────────────

class _ExercisePickerSheet extends StatefulWidget {
  const _ExercisePickerSheet();

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  final _searchCtrl = TextEditingController();
  List<ExerciseModel> _all = [];
  List<ExerciseModel> _filtered = [];
  List<String> _muscleGroups = [];
  String? _selectedMuscleGroup;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final exercises = await AnalyticsDatasource().getExercises();
      final groups =
          exercises
              .where((e) => e.muscleGroup != null)
              .map((e) => e.muscleGroup!)
              .toSet()
              .toList()
            ..sort();
      setState(() {
        _all = exercises;
        _filtered = exercises;
        _muscleGroups = groups;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _all.where((ex) {
        final matchesSearch =
            ex.name.toLowerCase().contains(q) ||
            (ex.muscleGroup?.toLowerCase().contains(q) ?? false);
        final matchesChip =
            _selectedMuscleGroup == null ||
            ex.muscleGroup == _selectedMuscleGroup;
        return matchesSearch && matchesChip;
      }).toList();
    });
  }

  void _selectMuscleGroup(String? group) {
    setState(() => _selectedMuscleGroup = group);
    _filter();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar ejercicio...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (!_loading && _error == null)
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _MuscleChip(
                    label: 'Todos',
                    selected: _selectedMuscleGroup == null,
                    onTap: () => _selectMuscleGroup(null),
                  ),
                  ..._muscleGroups.map(
                    (g) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _MuscleChip(
                        label: g,
                        selected: _selectedMuscleGroup == g,
                        onTap: () => _selectMuscleGroup(g),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.neonGreen),
                  )
                : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final ex = _filtered[i];
                      return ListTile(
                        onTap: () => Navigator.of(context).pop(ex),
                        title: Text(
                          ex.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: ex.muscleGroup != null
                            ? Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.neonGreen.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  ex.muscleGroup!,
                                  style: const TextStyle(
                                    color: AppTheme.neonGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MuscleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MuscleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.neonGreen.withValues(alpha: 0.2)
              : const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? Border.all(color: AppTheme.neonGreen, width: 1.5)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.neonGreen : Colors.grey[400],
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
