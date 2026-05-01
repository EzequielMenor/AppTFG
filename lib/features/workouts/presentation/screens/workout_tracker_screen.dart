import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/analytics/data/models/analytics_models.dart';
import '../../data/models/routine_models.dart';
import '../providers/workout_tracker_provider.dart';

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

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _activeExercises = widget.startData.exercises.map((ex) {
      final ts = widget.startData.targetSeries[ex.id] ?? 1;
      return _ActiveExercise(ex, targetSeries: ts);
    }).toList();

    // Iniciar tracker en provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutTrackerProvider>().startWorkout(widget.startData);
    });
  }

  @override
  void dispose() {
    for (final ae in _activeExercises) {
      for (final s in ae.sets) {
        s.dispose();
      }
    }
    super.dispose();
  }

  void _addSet() {
    setState(() => _activeExercises[_currentIndex].sets.add(_ActiveSet()));
  }

  void _toggleDone(_ActiveSet s) {
    final wasNotDone = !s.isDone;
    setState(() => s.isDone = !s.isDone);
    if (wasNotDone) _showRestSheet();
  }

  void _showRestSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _RestTimerSheet(),
    );
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

    setState(() => _saving = true);
    try {
      final success = await context.read<WorkoutTrackerProvider>().finishWorkout(
        startTime: _startTime,
        endTime: endTime,
        exercisesPayload: exercises,
      );
      if (success && mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Entrenamiento guardado!'),
            backgroundColor: AppTheme.neonGreen,
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
        title: const Text(
          'Cancelar entrenamiento',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Seguro que quieres cancelar? Se perderán los datos.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Continuar',
              style: TextStyle(color: AppTheme.neonGreen),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Cancelar entreno',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        context.read<WorkoutTrackerProvider>().cancelWorkout();
        Navigator.of(context).pop(false);
      }
    });
  }

  int get _currentIndex => context.read<WorkoutTrackerProvider>().currentIndex;

  void _goToPrev() {
    context.read<WorkoutTrackerProvider>().goToPrevExercise();
  }

  void _goToNext() {
    context.read<WorkoutTrackerProvider>().goToNextExercise();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutTrackerProvider>();
    final hasExercises = _activeExercises.isNotEmpty;
    final currentIdx = provider.currentIndex;
    final current = hasExercises && currentIdx < _activeExercises.length
        ? _activeExercises[currentIdx]
        : null;
    final elapsed = provider.elapsedSeconds;

    String timerText;
    final h = elapsed ~/ 3600;
    final m = (elapsed % 3600) ~/ 60;
    final s2 = elapsed % 60;
    if (h > 0) {
      timerText = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s2.toString().padLeft(2, '0')}';
    } else {
      timerText = '${m.toString().padLeft(2, '0')}:${s2.toString().padLeft(2, '0')}';
    }

    String appBarTitle;
    final total = _activeExercises.length;
    final routineName =
        widget.startData.routineName?.toUpperCase() ?? 'WORKOUT';
    if (total == 0) {
      appBarTitle = routineName;
    } else {
      appBarTitle = '$routineName  •  ${currentIdx + 1} OF $total';
    }

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.appBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: _confirmCancel,
        ),
        title: Text(
          appBarTitle,
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
                child: Text(
                  'Cancelar entrenamiento',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Timer ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 4),
            child: Text(
              timerText,
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
              style: const TextStyle(color: Colors.grey, fontSize: 13),
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
                    onPressed: currentIdx > 0 ? _goToPrev : null,
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: currentIdx > 0
                          ? Colors.white
                          : Colors.grey.withAlpha(60),
                      size: 20,
                    ),
                  ),
                  Text(
                    '${currentIdx + 1} / ${_activeExercises.length}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  IconButton(
                    onPressed: currentIdx < _activeExercises.length - 1
                        ? _goToNext
                        : null,
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color: currentIdx < _activeExercises.length - 1
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
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text('FINISH WORKOUT'),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Rest Timer Bottom Sheet ────────────────────────────────────────────────────

class _RestTimerSheet extends StatefulWidget {
  const _RestTimerSheet();

  @override
  State<_RestTimerSheet> createState() => _RestTimerSheetState();
}

class _RestTimerSheetState extends State<_RestTimerSheet> {
  late int _remaining;
  Timer? _timer;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _remaining = _kRestSeconds;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _paused = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 1) {
        _timer?.cancel();
        if (mounted) Navigator.pop(context);
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _togglePause() {
    if (_paused) {
      _startTimer();
    } else {
      _timer?.cancel();
      setState(() => _paused = true);
    }
  }

  void _adjust(int seconds) {
    setState(() {
      _remaining = (_remaining + seconds).clamp(1, _remaining + 300);
    });
  }

  String get _timeText {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.4;
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'REST',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
            Text(
              _timeText,
              style: const TextStyle(
                color: AppTheme.neonGreen,
                fontSize: 80,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _TimerButton(label: '−30s', onTap: () => _adjust(-30)),
                _TimerButton(
                  icon: _paused ? Icons.play_arrow : Icons.pause,
                  onTap: _togglePause,
                  large: true,
                ),
                _TimerButton(label: '+30s', onTap: () => _adjust(30)),
                _TimerButton(
                  icon: Icons.skip_next,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool large;

  const _TimerButton({
    this.label,
    this.icon,
    required this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = large ? 64.0 : 48.0;
    final iconSize = large ? 32.0 : 24.0;

    return SizedBox(
      width: size,
      height: size,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.neonGreen, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: EdgeInsets.zero,
        ),
        child: label != null
            ? Text(
                label!,
                style: const TextStyle(
                  color: AppTheme.neonGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              )
            : Icon(icon, color: AppTheme.neonGreen, size: iconSize),
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
                child: Text(
                  'SET',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'PREV',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'KG',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'REPS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'RPE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
          label: const Text(
            '+ ADD SET',
            style: TextStyle(
              color: AppTheme.neonGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          color: isActive ? AppTheme.neonGreen : Colors.transparent,
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

          // PREV (placeholder)
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

          // RPE input
          Expanded(
            child: IgnorePointer(
              ignoring: set.isDone,
              child: _NumField(
                controller: set.rpeCtrl,
                hint: isPending ? '—' : '0',
                decimal: true,
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
                color: set.isDone ? AppTheme.neonGreen : Colors.transparent,
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
        color: dimmed ? Colors.grey : Colors.white,
        fontSize: 14,
      ),
      keyboardType: decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimal ? RegExp(r'[\d.]') : RegExp(r'\d'),
        ),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }
}
