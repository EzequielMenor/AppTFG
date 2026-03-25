import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/analytics/data/models/analytics_models.dart';
import '../../data/models/routine_models.dart';

// ── Domain models ────────────────────────────────────────────────────────────

class _ActiveSet {
  final TextEditingController kgCtrl;
  final TextEditingController repsCtrl;
  final TextEditingController rpeCtrl;
  bool isWarmup;
  bool isDone;

  _ActiveSet()
      : kgCtrl = TextEditingController(),
        repsCtrl = TextEditingController(),
        rpeCtrl = TextEditingController(),
        isWarmup = false,
        isDone = false;

  void dispose() {
    kgCtrl.dispose();
    repsCtrl.dispose();
    rpeCtrl.dispose();
  }
}

class _ActiveExercise {
  final ExerciseModel exercise;
  final List<_ActiveSet> sets;

  _ActiveExercise(this.exercise, {int targetSeries = 1})
      : sets = List.generate(max(1, targetSeries), (_) => _ActiveSet());
}

// ── Screen ───────────────────────────────────────────────────────────────────

const int _kRestSeconds = 90;

class WorkoutTrackerScreen extends StatefulWidget {
  final WorkoutStartData startData;

  const WorkoutTrackerScreen({super.key, required this.startData});

  @override
  State<WorkoutTrackerScreen> createState() => _WorkoutTrackerScreenState();
}

class _WorkoutTrackerScreenState extends State<WorkoutTrackerScreen> {
  late final List<_ActiveExercise> _activeExercises;
  late final DateTime _startTime;
  late final TextEditingController _nameCtrl;

  Timer? _timer;
  int _elapsed = 0;
  bool _saving = false;

  // Rest timer
  Timer? _restTimer;
  int _restRemaining = 0;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _nameCtrl = TextEditingController(text: 'Entrenamiento');
    _activeExercises = widget.startData.exercises.map((ex) {
      final ts = widget.startData.targetSeries[ex.id] ?? 1;
      return _ActiveExercise(ex, targetSeries: ts);
    }).toList();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _restTimer?.cancel();
    _nameCtrl.dispose();
    for (final ae in _activeExercises) {
      for (final s in ae.sets) {
        s.dispose();
      }
    }
    super.dispose();
  }

  String get _timerText {
    final h = _elapsed ~/ 3600;
    final m = (_elapsed % 3600) ~/ 60;
    final s = _elapsed % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _addSet(_ActiveExercise ae) {
    setState(() => ae.sets.add(_ActiveSet()));
  }

  void _toggleDone(_ActiveSet s) {
    final wasNotDone = !s.isDone;
    setState(() => s.isDone = !s.isDone);
    if (wasNotDone) {
      _startRestTimer();
    }
  }

  void _toggleWarmup(_ActiveSet s) {
    setState(() => s.isWarmup = !s.isWarmup);
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    setState(() => _restRemaining = _kRestSeconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_restRemaining <= 1) {
        _restTimer?.cancel();
        setState(() => _restRemaining = 0);
      } else {
        setState(() => _restRemaining--);
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() => _restRemaining = 0);
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _activeExercises.removeAt(oldIndex);
      _activeExercises.insert(newIndex, item);
    });
  }

  Future<void> _finishWorkout() async {
    final endTime = DateTime.now();

    final exercises = <Map<String, dynamic>>[];
    for (int ei = 0; ei < _activeExercises.length; ei++) {
      final ae = _activeExercises[ei];
      final series = <Map<String, dynamic>>[];
      for (int si = 0; si < ae.sets.length; si++) {
        final s = ae.sets[si];
        final kg = double.tryParse(s.kgCtrl.text) ?? 0.0;
        final reps = int.tryParse(s.repsCtrl.text) ?? 0;
        final rpe = double.tryParse(s.rpeCtrl.text);
        final serieMap = <String, dynamic>{
          'weight': kg,
          'reps': reps,
          'isWarmup': s.isWarmup,
          'setOrder': si + 1,
        };
        if (rpe != null) serieMap['rpe'] = rpe;
        series.add(serieMap);
      }
      exercises.add({
        'exerciseId': ae.exercise.id,
        'exerciseOrder': ei + 1,
        'series': series,
      });
    }

    final payload = {
      'name': _nameCtrl.text.trim().isEmpty
          ? 'Entrenamiento'
          : _nameCtrl.text.trim(),
      'startTime': _startTime.toUtc().toIso8601String(),
      'endTime': endTime.toUtc().toIso8601String(),
      'exercises': exercises,
    };

    setState(() => _saving = true);
    try {
      final response =
          await ApiClient.post('/api/workouts', body: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Entrenamiento guardado!'),
              backgroundColor: AppTheme.neonGreen,
            ),
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
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

  void _confirmCancel() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Cancelar entrenamiento',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            '¿Seguro que quieres cancelar? Se perderán los datos.',
            style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar',
                style: TextStyle(color: AppTheme.neonGreen)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar entreno',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) Navigator.of(context).pop(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: SizedBox(
          width: 200,
          child: TextField(
            controller: _nameCtrl,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _confirmCancel,
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Cronómetro
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              _timerText,
              style: const TextStyle(
                color: AppTheme.neonGreen,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          // Exercise list (reorderable)
          Expanded(
            child: _activeExercises.isEmpty
                ? const Center(
                    child: Text(
                      'No hay ejercicios.\nPulsa FINISH para guardar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: _activeExercises.length,
                    onReorder: _onReorder,
                    itemBuilder: (context, i) => _ExerciseCard(
                      key: ValueKey(_activeExercises[i].exercise.id),
                      activeExercise: _activeExercises[i],
                      onAddSet: () => _addSet(_activeExercises[i]),
                      onToggleDone: _toggleDone,
                      onToggleWarmup: _toggleWarmup,
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_restRemaining > 0)
              _RestTimerBar(
                remaining: _restRemaining,
                onSkip: _skipRest,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _finishWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      : const Text('FINISH WORKOUT'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rest Timer Bar ────────────────────────────────────────────────────────────

class _RestTimerBar extends StatelessWidget {
  final int remaining;
  final VoidCallback onSkip;

  const _RestTimerBar({required this.remaining, required this.onSkip});

  String get _text {
    final m = remaining ~/ 60;
    final s = remaining % 60;
    return 'DESCANSO ${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.cardBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.timer, color: AppTheme.neonGreen, size: 20),
          const SizedBox(width: 8),
          Text(
            _text,
            style: const TextStyle(
                color: AppTheme.neonGreen,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          const Spacer(),
          TextButton(
            onPressed: onSkip,
            child: const Text('Saltar',
                style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

// ── Exercise card ─────────────────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  final _ActiveExercise activeExercise;
  final VoidCallback onAddSet;
  final void Function(_ActiveSet) onToggleDone;
  final void Function(_ActiveSet) onToggleWarmup;

  const _ExerciseCard({
    super.key,
    required this.activeExercise,
    required this.onAddSet,
    required this.onToggleDone,
    required this.onToggleWarmup,
  });

  @override
  Widget build(BuildContext context) {
    final ex = activeExercise.exercise;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _Thumbnail(url: ex.thumbnailUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ex.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      if (ex.muscleGroup != null)
                        Text(ex.muscleGroup!,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.drag_handle, color: Colors.grey, size: 20),
              ],
            ),
          ),
          // Table header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text('SET',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text('KG',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text('REPS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
                SizedBox(
                  width: 44,
                  child: Text('RPE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
                SizedBox(width: 64),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Sets
          ...activeExercise.sets.asMap().entries.map(
                (entry) => _SetRow(
                  index: entry.key,
                  set: entry.value,
                  onToggleDone: () => onToggleDone(entry.value),
                  onToggleWarmup: () => onToggleWarmup(entry.value),
                ),
              ),
          // Add set
          TextButton.icon(
            onPressed: onAddSet,
            icon: const Icon(Icons.add, size: 18, color: AppTheme.neonGreen),
            label: const Text('ADD SET',
                style: TextStyle(
                    color: AppTheme.neonGreen,
                    fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final int index;
  final _ActiveSet set;
  final VoidCallback onToggleDone;
  final VoidCallback onToggleWarmup;

  const _SetRow({
    required this.index,
    required this.set,
    required this.onToggleDone,
    required this.onToggleWarmup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: set.isDone
            ? AppTheme.neonGreen.withAlpha(20)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '${index + 1}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          ),
          Expanded(
            child: _NumField(
              controller: set.kgCtrl,
              hint: '0',
              decimal: true,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _NumField(
              controller: set.repsCtrl,
              hint: '0',
              decimal: false,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 44,
            child: _NumField(
              controller: set.rpeCtrl,
              hint: '-',
              decimal: true,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onToggleWarmup,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: set.isWarmup
                    ? Colors.orange.withAlpha(40)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: set.isWarmup ? Colors.orange : Colors.grey,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.whatshot,
                size: 16,
                color: set.isWarmup ? Colors.orange : Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onToggleDone,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: set.isDone
                    ? AppTheme.neonGreen.withAlpha(40)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: set.isDone ? AppTheme.neonGreen : Colors.grey,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.check,
                size: 16,
                color: set.isDone ? AppTheme.neonGreen : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool decimal;

  const _NumField(
      {required this.controller,
      required this.hint,
      required this.decimal});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      keyboardType: decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
            decimal ? RegExp(r'[\d.]') : RegExp(r'\d')),
      ],
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        isDense: true,
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String? url;
  const _Thumbnail({this.url});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, st) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.fitness_center, color: Colors.grey, size: 22),
    );
  }
}
