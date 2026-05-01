import 'package:flutter/material.dart';

import '../../data/datasources/routine_datasource.dart';
import '../../data/models/routine_models.dart';

/// ChangeNotifier que centraliza el estado y CRUD de rutinas.
///
/// Sigue el patrón de [AuthProvider]: inyección de datasource,
/// helpers `_setLoading`/`_clearError`, `notifyListeners()`.
///
/// Reemplaza el estado local + llamadas directas a [RoutineDatasource]
/// en [RoutinesScreen], [PreWorkoutScreen], [CreateRoutineScreen],
/// [RoutineDetailScreen].
class RoutineProvider extends ChangeNotifier {
  final RoutineDatasource _datasource;

  RoutineProvider({RoutineDatasource? datasource})
      : _datasource = datasource ?? RoutineDatasource();

  // ── Estado ───────────────────────────────────────────────────────────────

  List<RoutineModel> _routines = [];
  bool _isLoading = false;
  String? _error;

  List<RoutineModel> get routines => _routines;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Inicialización ──────────────────────────────────────────────────────

  void loadInitial() {
    loadRoutines();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────

  /// Carga la lista de rutinas desde el backend.
  Future<void> loadRoutines() async {
    _setLoading(true);
    _clearError();
    try {
      _routines = await _datasource.getRoutines();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[RoutineProvider] Error loading routines: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crea una nueva rutina y la agrega a la lista local.
  Future<RoutineModel?> createRoutine({
    required String name,
    String? description,
    required List<Map<String, dynamic>> exercises,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final routine = await _datasource.createRoutine(
        name: name,
        description: description,
        exercises: exercises,
      );
      _routines.add(routine);
      _isLoading = false;
      notifyListeners();
      return routine;
    } catch (e) {
      debugPrint('[RoutineProvider] Error creating routine: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Actualiza una rutina existente y reemplaza en la lista local.
  Future<RoutineModel?> updateRoutine({
    required int id,
    required String name,
    String? description,
    required List<Map<String, dynamic>> exercises,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final routine = await _datasource.updateRoutine(
        id: id,
        name: name,
        description: description,
        exercises: exercises,
      );
      final index = _routines.indexWhere((r) => r.id == id);
      if (index >= 0) {
        _routines[index] = routine;
      }
      _isLoading = false;
      notifyListeners();
      return routine;
    } catch (e) {
      debugPrint('[RoutineProvider] Error updating routine $id: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Elimina una rutina y la remueve de la lista local.
  Future<bool> deleteRoutine(int id) async {
    _setLoading(true);
    _clearError();
    try {
      await _datasource.deleteRoutine(id);
      _routines.removeWhere((r) => r.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[RoutineProvider] Error deleting routine $id: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
