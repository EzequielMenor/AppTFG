import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/analytics/data/models/analytics_models.dart';
import '../providers/analytics_provider.dart' as analytics_providers;
import '../providers/routine_provider.dart';
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
        return {
          'exerciseId': e.exercise.id,
          'exerciseOrder': i + 1,
          'targetSeries': e.series.length,
          'series': e.series
              .asMap()
              .entries
              .map(
                (s) => {
                  'setOrder': s.key + 1,
                  if (s.value.targetWeight != null)
                    'targetWeight': s.value.targetWeight,
                  if (s.value.targetRepsMin != null)
                    'targetRepsMin': s.value.targetRepsMin,
                  if (s.value.targetRepsMax != null)
                    'targetRepsMax': s.value.targetRepsMax,
                },
              )
              .toList(),
        };
      }).toList();

      final routine = await context.read<RoutineProvider>().createRoutine(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        exercises: exercisesPayload,
      );

      if (routine != null && mounted) Navigator.of(context).pop(routine);
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
              builder: (_, _) => TextButton(
                onPressed: _canSave && !_saving ? _save : null,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.neonGreen,
                        ),
                      )
                    : Text(
                        'Guardar',
                        style: TextStyle(
                          color: _canSave ? AppTheme.neonGreen : Colors.grey,
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
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            ..._exercises.asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              return _ExerciseItem(
                exercise: e,
                onRemove: () => setState(() => _exercises.removeAt(i)),
                onChanged: () => setState(() {}),
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

// ── Selected Exercise (state holder) ──────────────────────────────────────────

class _SelectedExercise {
  final ExerciseModel exercise;
  final List<RoutineSeriesModel> series;

  _SelectedExercise({required this.exercise})
    : series = [const RoutineSeriesModel(setOrder: 1)];

  String get seriesPreview {
    final parts = series.map((s) => s.displayText).toList();
    return '${series.length} serie${series.length == 1 ? '' : 's'}: ${parts.join(", ")}';
  }
}

// ── Exercise Item Widget ─────────────────────────────────────────────────────

class _ExerciseItem extends StatefulWidget {
  final _SelectedExercise exercise;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _ExerciseItem({
    required this.exercise,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_ExerciseItem> createState() => _ExerciseItemState();
}

class _ExerciseItemState extends State<_ExerciseItem> {
  bool _expanded = false;

  void _addSeries() {
    setState(() {
      final nextOrder = widget.exercise.series.length + 1;
      widget.exercise.series.add(RoutineSeriesModel(setOrder: nextOrder));
    });
    widget.onChanged();
  }

  void _removeSeries(int index) {
    if (widget.exercise.series.length <= 1) return;
    setState(() {
      widget.exercise.series.removeAt(index);
      for (int i = 0; i < widget.exercise.series.length; i++) {
        widget.exercise.series[i] = RoutineSeriesModel(
          setOrder: i + 1,
          targetWeight: widget.exercise.series[i].targetWeight,
          targetRepsMin: widget.exercise.series[i].targetRepsMin,
          targetRepsMax: widget.exercise.series[i].targetRepsMax,
        );
      }
    });
    widget.onChanged();
  }

  void _updateSeries(
    int index, {
    double? targetWeight,
    int? targetRepsMin,
    int? targetRepsMax,
  }) {
    setState(() {
      final old = widget.exercise.series[index];
      widget.exercise.series[index] = RoutineSeriesModel(
        setOrder: old.setOrder,
        targetWeight: targetWeight ?? old.targetWeight,
        targetRepsMin: targetRepsMin ?? old.targetRepsMin,
        targetRepsMax: targetRepsMax ?? old.targetRepsMax,
      );
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex.exercise.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (ex.exercise.muscleGroup != null)
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
                            ex.exercise.muscleGroup!,
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
                GestureDetector(
                  onTap: widget.onRemove,
                  child: const Icon(Icons.close, color: Colors.grey, size: 20),
                ),
              ],
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              onExpansionChanged: (v) => setState(() => _expanded = v),
              title: Text(
                ex.seriesPreview,
                style: TextStyle(
                  color: _expanded ? AppTheme.neonGreen : Colors.grey[400],
                  fontSize: 13,
                  fontWeight: _expanded ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              trailing: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.grey,
              ),
              children: [
                ...ex.series.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final s = entry.value;
                  return _SeriesRow(
                    index: idx,
                    series: s,
                    canDelete: ex.series.length > 1,
                    onRemove: () => _removeSeries(idx),
                    onWeightChanged: (v) => _updateSeries(idx, targetWeight: v),
                    onRepsMinChanged: (v) =>
                        _updateSeries(idx, targetRepsMin: v),
                    onRepsMaxChanged: (v) =>
                        _updateSeries(idx, targetRepsMax: v),
                  );
                }),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _addSeries,
                    icon: const Icon(
                      Icons.add,
                      size: 18,
                      color: AppTheme.neonGreen,
                    ),
                    label: const Text(
                      'Añadir serie',
                      style: TextStyle(color: AppTheme.neonGreen, fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Series Row Widget ────────────────────────────────────────────────────────

class _SeriesRow extends StatelessWidget {
  final int index;
  final RoutineSeriesModel series;
  final bool canDelete;
  final VoidCallback onRemove;
  final ValueChanged<double?> onWeightChanged;
  final ValueChanged<int?> onRepsMinChanged;
  final ValueChanged<int?> onRepsMaxChanged;

  const _SeriesRow({
    required this.index,
    required this.series,
    required this.canDelete,
    required this.onRemove,
    required this.onWeightChanged,
    required this.onRepsMinChanged,
    required this.onRepsMaxChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${index + 1}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _NumberField(
              label: 'kg',
              value: series.targetWeight,
              isDecimal: true,
              onChanged: (v) =>
                  onWeightChanged(v != null ? double.tryParse(v) : null),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _NumberField(
              label: 'min',
              value: series.targetRepsMin?.toDouble(),
              isDecimal: false,
              onChanged: (v) =>
                  onRepsMinChanged(v != null ? int.tryParse(v) : null),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _NumberField(
              label: 'max',
              value: series.targetRepsMax?.toDouble(),
              isDecimal: false,
              onChanged: (v) =>
                  onRepsMaxChanged(v != null ? int.tryParse(v) : null),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 28,
            child: canDelete
                ? GestureDetector(
                    onTap: onRemove,
                    child: Icon(Icons.close, color: Colors.grey[600], size: 18),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Small Number Input Field ─────────────────────────────────────────────────

class _NumberField extends StatelessWidget {
  final String label;
  final double? value;
  final bool isDecimal;
  final ValueChanged<String?> onChanged;

  const _NumberField({
    required this.label,
    required this.value,
    required this.isDecimal,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(
        text: value != null
            ? (isDecimal
                  ? value!.toStringAsFixed(value! % 1 == 0 ? 0 : 1)
                  : value!.toInt().toString())
            : '',
      ),
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      inputFormatters: isDecimal
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))]
          : [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: Colors.grey[700], fontSize: 11),
        isDense: true,
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
      final exercises =
          await context.read<analytics_providers.AnalyticsProvider>()
              .getExercises();
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

  void _showExercisePreview(BuildContext context, ExerciseModel exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ExercisePreviewSheet(exercise: exercise),
    );
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
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (ex.muscleGroup != null)
                              Container(
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
                              ),
                            if (ex.secondaryMuscles.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Secundarios: ${ex.secondaryMuscles.join(", ")}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.info_outline,
                            color: Colors.grey,
                            size: 22,
                          ),
                          onPressed: () =>
                              _showExercisePreview(context, ex),
                        ),
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

// ── Exercise preview bottom sheet ───────────────────────────────────────────

class _ExercisePreviewSheet extends StatelessWidget {
  final ExerciseModel exercise;

  const _ExercisePreviewSheet({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollCtrl) => SingleChildScrollView(
        controller: scrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (exercise.thumbnailUrl != null &&
                exercise.thumbnailUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    exercise.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFF2C2C2C),
                      child: const Center(
                        child: Icon(
                          Icons.fitness_center,
                          color: Colors.grey,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              exercise.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (exercise.muscleGroup != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  exercise.muscleGroup!,
                  style: const TextStyle(
                    color: AppTheme.neonGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (exercise.secondaryMuscles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Secundarios: ${exercise.secondaryMuscles.join(", ")}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ),
            const SizedBox(height: 16),
            if (exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Abriendo video...')),
                    );
                  },
                  icon: const Icon(Icons.play_circle_outline, size: 22),
                  label: const Text('Ver video del ejercicio'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.neonGreen,
                    side: const BorderSide(color: AppTheme.neonGreen),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (exercise.aliases.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'También conocido como:',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: exercise.aliases
                    .map(
                      (a) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          a,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
