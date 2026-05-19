import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;

import '../../../../core/cache/cache_manager.dart';
import '../../../../core/network/cancel_token.dart';
import '../../data/datasources/workout_datasource.dart';
import '../../data/models/workout_models.dart';

/// ChangeNotifier que centraliza el estado de workouts (historial + detalle).
///
/// Implementa el patrón SWR (Stale-While-Revalidate):
/// - Muestra datos cacheados inmediatamente si existen
/// - Refresca en background sin bloquear la UI
/// - Mantiene datos stale cuando el backend falla
/// - NO limpia caché al hacer refresh (mantiene snapshot disponible)
class WorkoutProvider extends ChangeNotifier {
  final WorkoutDatasource _datasource;
  CancelToken? _cancelToken;

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

  // ── SWR Cache Load ────────────────────────────────────────────────────────

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

    // 1. Intentar cache primero (stale tolerance)
    final stale = await CacheManager.getStale<List<dynamic>>('workouts');
    if (stale != null && stale.data != null) {
      final cachedList = stale.data as List;
      _workouts = cachedList
          .map((e) => WorkoutModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _isLoading = false;
      _hasLoadedOnce = true;
      _isUsingStaleData = stale.isExpired;
      notifyListeners();
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

      await CacheManager.setCache(
        'workouts',
        freshList.map((w) => w.toJson()).toList(),
      );
    } catch (e) {
      _handleFetchError(e);
    }
  }

  void _handleFetchError(dynamic e) {
    debugPrint('[WorkoutProvider] Fetch error: $e');
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
  /// NO limpia caché - mantiene stale visible mientras revalida.
  Future<void> loadHistory() async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
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

  /// Elimina un workout. Remueve de la lista local y persiste en caché.
  Future<void> deleteWorkout(int id) async {
    try {
      await _datasource.deleteWorkout(id);
      _workouts.removeWhere((w) => w.id == id);
      _selectedWorkout = null;
      notifyListeners();

      await CacheManager.setCache(
        'workouts',
        _workouts.map((w) => w.toJson()).toList(),
      );
    } catch (e) {
      debugPrint('[WorkoutProvider] Error deleting workout $id: $e');
      _errorMessage = 'Error al eliminar el entrenamiento';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }
}
