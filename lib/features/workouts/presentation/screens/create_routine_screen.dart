import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/analytics/data/datasources/analytics_datasource.dart';
import '../../../../features/analytics/data/models/analytics_models.dart';
import '../../data/datasources/routine_datasource.dart';
import '../../data/models/routine_models.dart';

class CreateRoutineScreen extends StatefulWidget {
  const CreateRoutineScreen({super.key});

  @override
  State<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final List<_SelectedExercise> _exercises = [];
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    for (final e in _exercises) {
      e.setsCtrl.dispose();
    }
    super.dispose();
  }

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty && _exercises.isNotEmpty;

  Future<void> _pickExercise() async {
    final result = await showModalBottomSheet<ExerciseModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      builder: (ctx) => const _ExercisePickerSheet(),
    );
    if (result != null && mounted) {
      if (_exercises.any((e) => e.exercise.id == result.id)) return;
      setState(() {
        _exercises.add(_SelectedExercise(exercise: result));
      });
    }
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    try {
      final exercisesPayload = _exercises.asMap().entries.map((entry) {
        final i = entry.key;
        final e = entry.value;
        final sets = int.tryParse(e.setsCtrl.text) ?? 3;
        return {
          'exerciseId': e.exercise.id,
          'exerciseOrder': i + 1,
          'targetSeries': sets,
        };
      }).toList();

      final routine = await RoutineDatasource().createRoutine(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        exercises: exercisesPayload,
      );

      if (mounted) Navigator.of(context).pop(routine);
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
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: const Text('Nueva Rutina'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ListenableBuilder(
              listenable: _nameCtrl,
              builder: (_, __) => TextButton(
                onPressed: _canSave && !_saving ? _save : null,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.neonGreen),
                      )
                    : Text(
                        'Guardar',
                        style: TextStyle(
                          color: _canSave
                              ? AppTheme.neonGreen
                              : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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
            onChanged: (_) => setState(() {}),
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
                  letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            ..._exercises.asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              return _ExerciseItem(
                exercise: e,
                onRemove: () => setState(() => _exercises.removeAt(i)),
              );
            }),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: _pickExercise,
            icon: const Icon(Icons.add, color: AppTheme.neonGreen),
            label: const Text('Añadir ejercicio',
                style: TextStyle(color: AppTheme.neonGreen)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.neonGreen),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
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

class _SelectedExercise {
  final ExerciseModel exercise;
  final TextEditingController setsCtrl;

  _SelectedExercise({required this.exercise})
      : setsCtrl = TextEditingController(text: '3');
}

class _ExerciseItem extends StatelessWidget {
  final _SelectedExercise exercise;
  final VoidCallback onRemove;

  const _ExerciseItem({required this.exercise, required this.onRemove});

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
                  exercise.exercise.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
                if (exercise.exercise.muscleGroup != null)
                  Text(
                    exercise.exercise.muscleGroup!,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 52,
            child: TextField(
              controller: exercise.setsCtrl,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Sets',
                labelStyle:
                    const TextStyle(color: Colors.grey, fontSize: 11),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 8),
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

// ── Exercise picker bottom sheet ─────────────────────────────────────────────

class _ExercisePickerSheet extends StatefulWidget {
  const _ExercisePickerSheet();

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  final _searchCtrl = TextEditingController();
  List<ExerciseModel> _all = [];
  List<ExerciseModel> _filtered = [];
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
      setState(() {
        _all = exercises;
        _filtered = exercises;
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
        return ex.name.toLowerCase().contains(q) ||
            (ex.muscleGroup?.toLowerCase().contains(q) ?? false);
      }).toList();
    });
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
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.neonGreen))
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.red)))
                    : ListView.builder(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final ex = _filtered[i];
                          return ListTile(
                            onTap: () => Navigator.of(context).pop(ex),
                            title: Text(ex.name,
                                style: const TextStyle(color: Colors.white)),
                            subtitle: ex.muscleGroup != null
                                ? Text(ex.muscleGroup!,
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12))
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
