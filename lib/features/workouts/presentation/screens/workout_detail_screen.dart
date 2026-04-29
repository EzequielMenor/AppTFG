import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../analytics/presentation/screens/exercise_detail_screen.dart';
import '../../data/models/workout_models.dart';
import '../providers/workout_provider.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final int workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  bool _visible = false;

  static const _cardBg = Color(0xFF1E1E1E);
  static const _exerciseBg = Color(0xFF1C1C1E);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutProvider>().loadWorkoutDetail(widget.workoutId);
    });
  }

  Future<void> _deleteWorkout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Eliminar', style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Estás seguro de eliminar este entrenamiento?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<WorkoutProvider>().deleteWorkout(widget.workoutId);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entrenamiento eliminado')),
        );
      }
    }
  }

  // ── Helpers de formato ─────────────────────────────────────────────────────

  String _formatDuration(DateTime start, DateTime? end) {
    if (end == null) return 'N/A';
    final diff = end.difference(start);
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  String _formatVolume(double? vol) {
    if (vol == null) return '0 kg';
    final fmt = NumberFormat('#,##0', 'en_US');
    return '${fmt.format(vol.toInt())} kg';
  }

  int _countTotalSets(List<WorkoutExerciseModel> exercises) {
    int total = 0;
    for (final ex in exercises) {
      total += ex.sets.length;
    }
    return total;
  }

  String _formatDate(DateTime dt) {
    return DateFormat('EEEE, MMM d • h:mm a', 'en_US').format(dt);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final workout = provider.selectedWorkout;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: _buildAppBar(),
      body: provider.isLoading && workout == null
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.neonGreen))
          : workout == null
              ? const Center(
                  child: Text('Error al cargar',
                      style: TextStyle(color: Colors.white)))
              : AnimatedOpacity(
                  opacity: _visible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: _buildContent(workout),
                ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF121212),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.ios_share, color: Colors.white),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Próximamente')));
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Próximamente')));
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.neonGreen,
              side: const BorderSide(color: AppTheme.neonGreen),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              minimumSize: const Size(0, 34),
            ),
            child: const Text('Edit',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: _cardBg,
          onSelected: (value) {
            if (value == 'delete') _deleteWorkout();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                  SizedBox(width: 8),
                  Text('Delete workout',
                      style: TextStyle(color: Colors.redAccent)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildContent(WorkoutModel workout) {
    // Mostrar animación una vez cargado
    if (!_visible) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _visible = true);
      });
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Text(
          workout.name ?? 'Entrenamiento',
          style: const TextStyle(
              color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: Colors.grey, size: 14),
            const SizedBox(width: 6),
            Text(
              _formatDate(workout.startTime),
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Stats row ───────────────────────────────────────────────────────
        IntrinsicHeight(
          child: Row(
            children: [
              _buildStatCard('DURATION', _formatDuration(workout.startTime, workout.endTime)),
              const SizedBox(width: 10),
              _buildStatCard('VOLUME', _formatVolume(workout.totalVolume)),
              const SizedBox(width: 10),
              _buildStatCard('SETS', '${_countTotalSets(workout.exercises)}'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Exercise cards ──────────────────────────────────────────────────
        ...workout.exercises.map((ex) => _buildExerciseCard(ex)),

        // ── Notes ───────────────────────────────────────────────────────────
        if (workout.notes != null && workout.notes!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('NOTES',
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(workout.notes!,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _exerciseIcon() => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: AppTheme.neonGreen,
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(Icons.fitness_center, color: Colors.black, size: 22),
  );

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                  color: AppTheme.neonGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(WorkoutExerciseModel exercise) {
    void openDetail() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExerciseDetailScreen(
            exerciseId: exercise.exerciseId,
            exerciseName: exercise.exerciseName,
            muscleGroup: exercise.muscleGroup,
            videoUrl: exercise.videoUrl,
            thumbnailUrl: exercise.thumbnailUrl,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _exerciseBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // ── Exercise header ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: openDetail,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: exercise.thumbnailUrl != null &&
                            exercise.thumbnailUrl!.isNotEmpty
                        ? Image.network(
                            exercise.thumbnailUrl!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _exerciseIcon(),
                          )
                        : _exerciseIcon(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercise.exerciseName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      if (exercise.muscleGroup != null)
                        Text(exercise.muscleGroup!,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: Colors.grey, size: 20),
                  color: _cardBg,
                  onSelected: (value) {
                    if (value == 'info') openDetail();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'info',
                      child: Text('Ver ejercicio',
                          style: TextStyle(color: Colors.white70)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Table header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _SetCol(child: Text('SET', style: _headerStyle)),
                _KgCol(child: Text('KG', style: _headerStyle)),
                _RepsCol(child: Text('REPS', style: _headerStyle)),
                _RpeCol(child: Text('RPE', style: _headerStyle)),
                _DoneCol(child: Text('DONE', style: _headerStyle)),
              ],
            ),
          ),

          // ── Series rows ────────────────────────────────────────────────
          ...exercise.sets.asMap().entries.map((entry) {
            final serie = entry.value;
            final bool isWarmup = serie.isWarmup;
            final Color setColor =
                isWarmup ? Colors.orange : Colors.grey;
            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  _SetCol(
                    child: Text(
                      '${serie.setOrder}',
                      style: TextStyle(
                          color: setColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  _KgCol(
                    child: Text(
                      _stripTrailingZeros(serie.weight),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  _RepsCol(
                    child: Text(
                      '${serie.reps ?? 0}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  _RpeCol(
                    child: Text(
                      _formatRpe(serie.rpe),
                      style: TextStyle(
                          color: serie.rpe != null
                              ? Colors.orange.shade300
                              : Colors.grey.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  _DoneCol(
                    child: serie.done
                        ? Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: AppTheme.neonGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check,
                                color: Colors.black, size: 18),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _stripTrailingZeros(dynamic val) {
    if (val == null) return '0';
    final d = double.tryParse(val.toString());
    if (d == null) return val.toString();
    return d == d.truncateToDouble()
        ? d.toInt().toString()
        : d.toString();
  }

  String _formatRpe(dynamic rpe) {
    if (rpe == null) return '—';
    final d = double.tryParse(rpe.toString());
    if (d == null || d == 0) return '—';
    return '@${d == d.truncateToDouble() ? d.toInt() : d}';
  }
}

const _headerStyle = TextStyle(
    color: Colors.grey,
    fontSize: 11,
    letterSpacing: 1.2,
    fontWeight: FontWeight.w600);

class _SetCol extends StatelessWidget {
  final Widget child;
  const _SetCol({required this.child});
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 40, child: Center(child: child));
}

class _KgCol extends StatelessWidget {
  final Widget child;
  const _KgCol({required this.child});
  @override
  Widget build(BuildContext context) =>
      Expanded(child: Center(child: child));
}

class _RepsCol extends StatelessWidget {
  final Widget child;
  const _RepsCol({required this.child});
  @override
  Widget build(BuildContext context) =>
      Expanded(child: Center(child: child));
}

class _RpeCol extends StatelessWidget {
  final Widget child;
  const _RpeCol({required this.child});
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 48, child: Center(child: child));
}

class _DoneCol extends StatelessWidget {
  final Widget child;
  const _DoneCol({required this.child});
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 52, child: Center(child: child));
}
