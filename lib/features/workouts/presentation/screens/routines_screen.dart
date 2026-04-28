import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/routine_datasource.dart';
import '../../data/models/routine_models.dart';

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key});

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  final _ds = RoutineDatasource();
  List<RoutineModel> _routines = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final routines = await _ds.getRoutines();
      if (!mounted) return;
      setState(() {
        _routines = routines;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _deleteRoutine(RoutineModel routine) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text(
          'Eliminar rutina',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Seguro que querés borrar "${routine.name}"? Esta acción no se puede deshacer.',
          style: const TextStyle(color: AppTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await _ds.deleteRoutine(routine.id);
      if (!mounted) return;
      setState(() {
        _routines.removeWhere((r) => r.id == routine.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${routine.name}" eliminada'),
          backgroundColor: AppTheme.cardBackground,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createRoutine() async {
    final result = await context.push<RoutineModel>('/create-routine');
    if (result != null && mounted) {
      _loadRoutines();
    }
  }

  Future<void> _editRoutine(RoutineModel routine) async {
    final result = await context.push<bool>(
      '/routine/${routine.id}',
      extra: routine,
    );
    if (result == true && mounted) {
      _loadRoutines();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MIS RUTINAS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.neonGreen, size: 28),
            onPressed: _createRoutine,
            tooltip: 'Crear rutina',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.neonGreen),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    if (_routines.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      color: AppTheme.neonGreen,
      onRefresh: _loadRoutines,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _routines.length,
        itemBuilder: (context, index) {
          final routine = _routines[index];
          return _RoutineCard(
            routine: routine,
            onTap: () => _editRoutine(routine),
            onLongPress: () => _deleteRoutine(routine),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            const Text(
              'No tenés rutinas todavía',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Creá tu primera rutina para\norganizar tus entrenamientos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createRoutine,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'Crear rutina',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar rutinas',
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadRoutines,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonGreen,
                foregroundColor: Colors.black,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Routine Card ───────────────────────────────────────────────────────────────

class _RoutineCard extends StatelessWidget {
  final RoutineModel routine;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _RoutineCard({
    required this.routine,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final exerciseCount = routine.exercises.length;
    final muscleGroups = _extractMuscleGroups();

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Icono
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.neonGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.format_list_bulleted,
                color: AppTheme.neonGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routine.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$exerciseCount ejercicio${exerciseCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 13,
                    ),
                  ),
                  if (muscleGroups.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: muscleGroups
                            .take(3)
                            .map(
                              (g) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.neonGreen.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  g,
                                  style: const TextStyle(
                                    color: AppTheme.neonGreen,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
            // Flecha
            const Icon(Icons.chevron_right, color: Colors.grey, size: 24),
          ],
        ),
      ),
    );
  }

  List<String> _extractMuscleGroups() {
    return routine.exercises
        .where((e) => e.muscleGroup != null && e.muscleGroup!.isNotEmpty)
        .map((e) => e.muscleGroup!)
        .toSet()
        .toList();
  }
}
