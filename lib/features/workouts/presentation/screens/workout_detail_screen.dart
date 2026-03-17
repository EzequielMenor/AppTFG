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
  bool _visible = false;

  // ── Colores del diseño ─────────────────────────────────────────────────────
  static const _cardBg = Color(0xFF1E1E1E);
  static const _exerciseBg = Color(0xFF1C1C1E);

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
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) setState(() => _visible = true);
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
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
    if (confirm == true) {
      try {
        final response =
            await ApiClient.delete('/api/workouts/${widget.workoutId}');
        if (response.statusCode == 204 || response.statusCode == 200) {
          if (!mounted) return;
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entrenamiento eliminado')),
          );
        }
      } catch (_) {}
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

  String _formatVolume(dynamic vol) {
    if (vol == null) return '0 kg';
    final num v = (vol is num) ? vol : num.tryParse(vol.toString()) ?? 0;
    final fmt = NumberFormat('#,##0', 'en_US');
    return '${fmt.format(v.toInt())} kg';
  }

  int _countTotalSets(List exercises) {
    int total = 0;
    for (final ex in exercises) {
      final series = ex['series'] as List? ?? [];
      total += series.length;
    }
    return total;
  }

  String _formatDate(DateTime dt) {
    return DateFormat('EEEE, MMM d • h:mm a', 'en_US').format(dt);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.neonGreen))
          : _workout == null
              ? const Center(
                  child: Text('Error al cargar',
                      style: TextStyle(color: Colors.white)))
              : AnimatedOpacity(
                  opacity: _visible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: _buildContent(),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              minimumSize: const Size(0, 34),
            ),
            child: const Text('Edit',
                style:
                    TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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

  Widget _buildContent() {
    final startTime = _workout!['startTime'] != null
        ? DateTime.parse(_workout!['startTime'])
        : DateTime.now();
    final endTime = _workout!['endTime'] != null
        ? DateTime.parse(_workout!['endTime'])
        : null;
    final List exercises = _workout!['exercises'] ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Text(
          _workout!['name'] ?? 'Entrenamiento',
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
              _formatDate(startTime),
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Stats row ───────────────────────────────────────────────────────
        IntrinsicHeight(
          child: Row(
            children: [
              _buildStatCard('DURATION', _formatDuration(startTime, endTime)),
              const SizedBox(width: 10),
              _buildStatCard(
                  'VOLUME', _formatVolume(_workout!['totalVolume'])),
              const SizedBox(width: 10),
              _buildStatCard('SETS', '${_countTotalSets(exercises)}'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Exercise cards ──────────────────────────────────────────────────
        ...exercises.map((ex) => _buildExerciseCard(ex as Map<String, dynamic>)),

        // ── Notes ───────────────────────────────────────────────────────────
        if (_workout!['notes'] != null &&
            _workout!['notes'].toString().isNotEmpty)
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
                Text(_workout!['notes'],
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
      ],
    );
  }

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

  Widget _buildExerciseCard(Map<String, dynamic> exerciseData) {
    final exerciseInfo =
        exerciseData['exercise'] as Map<String, dynamic>? ?? {};
    final List series = exerciseData['series'] ?? [];
    final String name = exerciseInfo['name'] ?? 'Ejercicio';
    final String muscleGroup = exerciseInfo['muscleGroup'] ?? '';

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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.neonGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.fitness_center,
                      color: Colors.black, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      if (muscleGroup.isNotEmpty)
                        Text(muscleGroup,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: Colors.grey, size: 20),
                  color: _cardBg,
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
          ...series.asMap().entries.map((entry) {
            final serie = entry.value as Map<String, dynamic>;
            final bool isWarmup = serie['isWarmup'] == true;
            final Color setColor =
                isWarmup ? Colors.orange : Colors.grey;
            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  _SetCol(
                    child: Text(
                      '${serie['setOrder'] ?? entry.key + 1}',
                      style: TextStyle(
                          color: setColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  _KgCol(
                    child: Text(
                      _stripTrailingZeros(serie['weight']),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  _RepsCol(
                    child: Text(
                      '${serie['reps'] ?? 0}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  _RpeCol(
                    child: Text(
                      _formatRpe(serie['rpe']),
                      style: TextStyle(
                          color: serie['rpe'] != null
                              ? Colors.orange.shade300
                              : Colors.grey.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  _DoneCol(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppTheme.neonGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.black, size: 18),
                    ),
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

  /// Elimina ceros decimales innecesarios: "100.00" → "100", "102.50" → "102.5"
  String _stripTrailingZeros(dynamic val) {
    if (val == null) return '0';
    final d = double.tryParse(val.toString());
    if (d == null) return val.toString();
    return d == d.truncateToDouble()
        ? d.toInt().toString()
        : d.toString();
  }

  /// "@8" / "@8.5" si hay RPE, "—" si no
  String _formatRpe(dynamic rpe) {
    if (rpe == null) return '—';
    final d = double.tryParse(rpe.toString());
    if (d == null || d == 0) return '—';
    return '@${d == d.truncateToDouble() ? d.toInt() : d}';
  }
}

// ── Columnas de la tabla (proporciones fijas) ──────────────────────────────

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
