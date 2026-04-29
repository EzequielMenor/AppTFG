import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/routine_provider.dart';
import '../../data/models/routine_models.dart';
import 'routine_detail_screen.dart';

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key});

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutineProvider>().loadInitial();
    });
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

    final success =
        await context.read<RoutineProvider>().deleteRoutine(routine.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '"${routine.name}" eliminada'
              : 'Error al eliminar la rutina',
        ),
        backgroundColor:
            success ? AppTheme.cardBackground : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutineProvider>();

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: const Text('RUTINAS'),
        backgroundColor: AppTheme.appBackground,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.neonGreen),
            onPressed: () => context.push('/create-routine'),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.neonGreen),
            )
          : provider.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<RoutineProvider>().loadRoutines(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : provider.routines.isEmpty
          ? const Center(
              child: Text(
                'No hay rutinas creadas aún.\n¡Creá una nueva!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textGrey),
              ),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  context.read<RoutineProvider>().loadRoutines(),
              color: AppTheme.neonGreen,
              backgroundColor: AppTheme.cardBackground,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.routines.length,
                itemBuilder: (_, i) {
                  final routine = provider.routines[i];
                  final exerciseCount = routine.exercises.length;

                  return Card(
                    color: AppTheme.cardBackground,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        routine.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '$exerciseCount ejercicio${exerciseCount != 1 ? 's' : ''}',
                        style: const TextStyle(color: AppTheme.textGrey),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _deleteRoutine(routine),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppTheme.textGrey,
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RoutineDetailScreen(
                              routine: routine,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
