import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../../../../core/cache/cache_manager.dart';
import '../../data/datasources/workout_datasource.dart';
import '../../data/models/workout_models.dart';

/// ChangeNotifier que centraliza el estado de workouts (historial + detalle).
///
/// Sigue el patrón de SWR cache de [workout_history_screen]:
/// muestra datos cacheados inmediatamente y refresca en background.
class WorkoutProvider extends ChangeNotifier {
  final WorkoutDatasource _datasource;

  WorkoutProvider({WorkoutDatasource? datasource})
      : _datasource = datasource ?? WorkoutDatasource();

  // ── Estado ───────────────────────────────────────────────────────────────

  List<WorkoutModel> _workouts = [];
  WorkoutModel? _selectedWorkout;
  bool _isLoading = false;
  bool _hasLoadedOnce = false;
  bool _isUsingStaleData = false;
  String? _errorMessage;

  List<WorkoutModel> get workouts => _workouts;
  WorkoutModel? get selectedWorkout => _selectedWorkout;
  bool get isLoading => _isLoading;
  bool get hasLoadedOnce => _hasLoadedOnce;
  bool get isUsingStaleData => _isUsingStaleData;
  String? get errorMessage => _errorMessage;

  // ── Inicialización ──────────────────────────────────────────────────────

  /// Carga inicial con SWR cache.
  void loadInitial() {
    _loadWithCache();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Carga con SWR cache ─────────────────────────────────────────────────

  Future<void> _loadWithCache() async {
    final hadData = _hasLoadedOnce;

    if (hadData) {
      _errorMessage = null;
      _isUsingStaleData = true;
      notifyListeners();
    } else {
      _setLoading(true);
      _clearError();
    }

    // 1. Intentar cache primero
    final cached = await CacheManager.getCache('workouts');
    if (cached != null) {
      final cachedList = cached is List ? cached : [];
      if (!hadData) {
        _workouts = cachedList
            .map((e) => WorkoutModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
        _hasLoadedOnce = true;
        notifyListeners();
      } else {
        _workouts = cachedList
            .map((e) => WorkoutModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    // 2. Fetch en background
    try {
      final freshList = await _datasource.getWorkouts();
      _workouts = freshList;
      _isLoading = false;
      _isUsingStaleData = false;
      _hasLoadedOnce = true;
      _errorMessage = null;
      notifyListeners();

      // Cachear la respuesta como listas de mapas
      await CacheManager.setCache(
        'workouts',
        freshList.map((w) => w.toJson()).toList(),
      );
    } catch (e) {
      _handleFetchError(e);
    }
  }

  void _handleFetchError(dynamic e) {
    if (_hasLoadedOnce) {
      _isUsingStaleData = true;
      _isLoading = false;
      notifyListeners();
    } else if (_workouts.isEmpty) {
      _errorMessage =
          '❌ Error de conexión: Verifica que el backend esté encendido y en la misma WiFi.\n($e)';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Eventos públicos ─────────────────────────────────────────────────────

  /// Recarga forzada (pull-to-refresh).
  Future<void> loadHistory() async {
    await CacheManager.clearCache('workouts');
    _hasLoadedOnce = false;
    await _loadWithCache();
  }

  /// Carga detalle de un workout por ID.
  Future<void> loadWorkoutDetail(int id) async {
    _setLoading(true);
    _clearError();
    try {
      _selectedWorkout = await _datasource.getWorkout(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[WorkoutProvider] Error loading detail $id: $e');
      _errorMessage = 'Error al cargar el entrenamiento';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Elimina un workout. Remueve de la lista local y del backend.
  Future<void> deleteWorkout(int id) async {
    try {
      await _datasource.deleteWorkout(id);
      _workouts.removeWhere((w) => w.id == id);
      _selectedWorkout = null;
      notifyListeners();
    } catch (e) {
      debugPrint('[WorkoutProvider] Error deleting workout $id: $e');
      _errorMessage = 'Error al eliminar el entrenamiento';
      notifyListeners();
    }
  }
}
