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
  final int targetSeries;

  _ActiveExercise(this.exercise, {int targetSeries = 1})
      : targetSeries = max(1, targetSeries),
        sets = List.generate(max(1, targetSeries), (_) => _ActiveSet());
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

  int _currentIndex = 0;
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

  String get _appBarTitle {
    final total = _activeExercises.length;
    final routineName = widget.startData.routineName?.toUpperCase() ?? 'WORKOUT';
    if (total == 0) return routineName;
    return '$routineName  •  ${_currentIndex + 1} OF $total';
  }

  void _goToPrev() {
    if (_currentIndex > 0) setState(() => _currentIndex--);
  }

  void _goToNext() {
    if (_currentIndex < _activeExercises.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _addSet() {
    setState(() => _activeExercises[_currentIndex].sets.add(_ActiveSet()));
  }

  void _toggleDone(_ActiveSet s) {
    final wasNotDone = !s.isDone;
    setState(() => s.isDone = !s.isDone);
    if (wasNotDone) _startRestTimer();
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

  Future<void> _finishWorkout() async {
    final endTime = DateTime.now();
    final now = _startTime;
    final autoName =
        'Entrenamiento ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

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
      'name': autoName,
      'startTime': _startTime.toUtc().toIso8601String(),
      'endTime': endTime.toUtc().toIso8601String(),
      'exercises': exercises,
    };

    setState(() => _saving = true);
    try {
      final response = await ApiClient.post('/api/workouts', body: payload);
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
    final hasExercises = _activeExercises.isNotEmpty;
    final current =
        hasExercises ? _activeExercises[_currentIndex] : null;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.appBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: _confirmCancel,
        ),
        title: Text(
          _appBarTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: AppTheme.cardBackground,
            onSelected: (value) {
              if (value == 'cancel') _confirmCancel();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'cancel',
                child: Text('Cancelar entrenamiento',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // ── Timer ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 4),
                child: Text(
                  _timerText,
                  style: const TextStyle(
                    color: AppTheme.neonGreen,
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const Text(
                'Elapsed Time',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // ── Exercise name + target ──────────────────────────────────────
              if (current != null) ...[
                Text(
                  current.exercise.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Target: ${current.targetSeries} sets',
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 20),
              ],

              // ── Sets table ─────────────────────────────────────────────────
              if (current != null)
                Expanded(
                  child: _ExerciseSetTable(
                    activeExercise: current,
                    onAddSet: _addSet,
                    onToggleDone: _toggleDone,
                  ),
                )
              else
                const Expanded(
                  child: Center(
                    child: Text(
                      'No hay ejercicios.\nPulsa FINISH para guardar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),

              // ── Exercise navigation ────────────────────────────────────────
              if (hasExercises)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed:
                            _currentIndex > 0 ? _goToPrev : null,
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: _currentIndex > 0
                              ? Colors.white
                              : Colors.grey.withAlpha(60),
                          size: 20,
                        ),
                      ),
                      Text(
                        '${_currentIndex + 1} / ${_activeExercises.length}',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13),
                      ),
                      IconButton(
                        onPressed: _currentIndex <
                                _activeExercises.length - 1
                            ? _goToNext
                            : null,
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          color: _currentIndex <
                                  _activeExercises.length - 1
                              ? Colors.white
                              : Colors.grey.withAlpha(60),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // ── Rest timer pill ────────────────────────────────────────────────
          if (_restRemaining > 0)
            Positioned(
              bottom: 16,
              right: 16,
              child: _RestPill(
                remaining: _restRemaining,
                onSkip: _skipRest,
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
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
      ),
    );
  }
}

// ── Rest Pill ─────────────────────────────────────────────────────────────────

class _RestPill extends StatelessWidget {
  final int remaining;
  final VoidCallback onSkip;

  const _RestPill({required this.remaining, required this.onSkip});

  String get _text {
    final m = remaining ~/ 60;
    final s = remaining % 60;
    return 'REST ${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSkip,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppTheme.neonGreen.withAlpha(80), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.neonGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _text,
              style: const TextStyle(
                color: AppTheme.neonGreen,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Exercise Set Table ────────────────────────────────────────────────────────

class _ExerciseSetTable extends StatelessWidget {
  final _ActiveExercise activeExercise;
  final VoidCallback onAddSet;
  final void Function(_ActiveSet) onToggleDone;

  const _ExerciseSetTable({
    required this.activeExercise,
    required this.onAddSet,
    required this.onToggleDone,
  });

  int get _firstActiveIndex {
    for (int i = 0; i < activeExercise.sets.length; i++) {
      if (!activeExercise.sets[i].isDone) return i;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final activeIdx = _firstActiveIndex;

    return Column(
      children: [
        // Table header
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text('SET',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: Text('PREV',
                    textAlign: TextAlign.center,
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
              SizedBox(width: 36),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Sets
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: activeExercise.sets.length,
            itemBuilder: (context, i) {
              final s = activeExercise.sets[i];
              final isActive = i == activeIdx;
              final isPending = !s.isDone && i > activeIdx;
              return _SetRow(
                index: i,
                set: s,
                isActive: isActive,
                isPending: isPending,
                onToggleDone: () => onToggleDone(s),
              );
            },
          ),
        ),

        // Add set
        TextButton.icon(
          onPressed: onAddSet,
          icon: const Icon(Icons.add, size: 18, color: AppTheme.neonGreen),
          label: const Text('+ ADD SET',
              style: TextStyle(
                  color: AppTheme.neonGreen,
                  fontWeight: FontWeight.w600)),
          style: TextButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}

// ── Set Row ────────────────────────────────────────────────────────────────

class _SetRow extends StatelessWidget {
  final int index;
  final _ActiveSet set;
  final bool isActive;
  final bool isPending;
  final VoidCallback onToggleDone;

  const _SetRow({
    required this.index,
    required this.set,
    required this.isActive,
    required this.isPending,
    required this.onToggleDone,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: set.isDone
            ? AppTheme.neonGreen.withAlpha(20)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive
              ? AppTheme.neonGreen
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // SET number
          SizedBox(
            width: 32,
            child: Text(
              '${index + 1}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: set.isDone ? AppTheme.neonGreen : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

          // PREV (previous session — placeholder)
          const Expanded(
            child: Text(
              '—',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),

          // KG input
          Expanded(
            child: IgnorePointer(
              ignoring: set.isDone,
              child: _NumField(
                controller: set.kgCtrl,
                hint: isPending ? '—' : '0',
                decimal: true,
                dimmed: isPending,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // REPS input
          Expanded(
            child: IgnorePointer(
              ignoring: set.isDone,
              child: _NumField(
                controller: set.repsCtrl,
                hint: isPending ? '—' : '0',
                decimal: false,
                dimmed: isPending,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Done check
          GestureDetector(
            onTap: onToggleDone,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: set.isDone
                    ? AppTheme.neonGreen
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: set.isDone ? AppTheme.neonGreen : Colors.grey,
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.check,
                size: 17,
                color: set.isDone ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Num Field ─────────────────────────────────────────────────────────────────

class _NumField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool decimal;
  final bool dimmed;

  const _NumField({
    required this.controller,
    required this.hint,
    required this.decimal,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      style: TextStyle(
          color: dimmed ? Colors.grey : Colors.white, fontSize: 14),
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
