import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/routine_datasource.dart';
import '../../data/models/routine_models.dart';
import 'create_routine_screen.dart';
import 'csv_import_sheet.dart';

class PreWorkoutScreen extends StatefulWidget {
  const PreWorkoutScreen({super.key});

  @override
  State<PreWorkoutScreen> createState() => _PreWorkoutScreenState();
}

class _PreWorkoutScreenState extends State<PreWorkoutScreen> {
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
      final routines = await RoutineDatasource().getRoutines();
      setState(() {
        _routines = routines;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _startRoutine(RoutineModel routine) {
    final data = WorkoutStartData.fromRoutine(routine);
    context.push('/tracker', extra: data);
  }

  void _startFree() {
    context.push('/tracker', extra: WorkoutStartData.empty());
  }

  Future<void> _deleteRoutine(RoutineModel routine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Borrar rutina',
            style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Seguro que quieres borrar "${routine.name}"?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.neonGreen)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await RoutineDatasource().deleteRoutine(routine.id);
      _loadRoutines();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null || result.files.single.bytes == null) return;

      final content = String.fromCharCodes(result.files.single.bytes!);

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CsvImportSheet(
          csvContent: content,
          onImported: _loadRoutines,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al leer el archivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _goToCreate() async {
    final result = await Navigator.of(context).push<RoutineModel>(
      MaterialPageRoute(
          builder: (_) => const CreateRoutineScreen()),
    );
    if (result != null) _loadRoutines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: const Text('Nuevo Entrenamiento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: 'Importar CSV (Hevy)',
            onPressed: _importCsv,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildRoutineList(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: OutlinedButton.icon(
              onPressed: _startFree,
              icon: const Icon(Icons.bolt, color: AppTheme.neonGreen),
              label: const Text(
                'Entrenamiento libre',
                style: TextStyle(
                    color: AppTheme.neonGreen, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.neonGreen),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineList() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.neonGreen));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadRoutines,
              child: const Text('Reintentar',
                  style: TextStyle(color: AppTheme.neonGreen)),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        const Text(
          'MIS RUTINAS',
          style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        if (_routines.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No tienes rutinas guardadas.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ..._routines.map((r) => _RoutineCard(
              routine: r,
              onTap: () => _startRoutine(r),
              onLongPress: () => _deleteRoutine(r),
            )),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _goToCreate,
          icon: const Icon(Icons.add, color: AppTheme.neonGreen),
          label: const Text('Crear nueva rutina',
              style: TextStyle(color: AppTheme.neonGreen)),
        ),
      ],
    );
  }
}

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
    final count = routine.exercises.length;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    routine.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count ejercicio${count != 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
