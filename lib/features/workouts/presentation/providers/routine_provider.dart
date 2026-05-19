import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;

import '../../../../core/cache/cache_manager.dart';
import '../../../../core/network/cancel_token.dart';
import '../../data/datasources/routine_datasource.dart';
import '../../data/models/routine_models.dart';

/// ChangeNotifier que centraliza el estado y CRUD de rutinas.
///
/// Implementa el patrón SWR (Stale-While-Revalidate):
/// - Muestra datos cacheados inmediatamente si existen
/// - Refresca en background sin bloquear la UI
/// - Mantiene datos stale cuando el backend falla
class RoutineProvider extends ChangeNotifier {
  final RoutineDatasource _datasource;
  CancelToken? _cancelToken;

  RoutineProvider({RoutineDatasource? datasource})
    : _datasource = datasource ?? RoutineDatasource();

  // ── Estado ───────────────────────────────────────────────────────────────

  List<RoutineModel> _routines = [];
  bool _isLoading = false;
  bool _hasLoadedOnce = false;
  bool _isUsingStaleData = false;
  String? _errorMessage;

  List<RoutineModel> get routines => _routines;
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
    final stale = await CacheManager.getStale<List<dynamic>>('routines');
    if (stale != null && stale.data != null) {
      final cachedList = stale.data as List;
      _routines = cachedList
          .map((e) => RoutineModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _isLoading = false;
      _hasLoadedOnce = true;
      _isUsingStaleData = stale.isExpired;
      notifyListeners();
    }

    // 2. Fetch en background
    try {
      final freshList = await _datasource.getRoutines();
      _routines = freshList;
      _isLoading = false;
      _isUsingStaleData = false;
      _hasLoadedOnce = true;
      _errorMessage = null;
      notifyListeners();

      await CacheManager.setCache(
        'routines',
        freshList.map((r) => r.toJson()).toList(),
      );
    } catch (e) {
      _handleFetchError(e);
    }
  }

  void _handleFetchError(dynamic e) {
    debugPrint('[RoutineProvider] Fetch error: $e');
    if (_hasLoadedOnce) {
      _isUsingStaleData = true;
      _isLoading = false;
      notifyListeners();
    } else if (_routines.isEmpty) {
      _errorMessage =
          '❌ Error de conexión: Verifica que el backend esté encendido.\n($e)';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Eventos públicos ─────────────────────────────────────────────────────

  /// Recarga forzada (pull-to-refresh).
  Future<void> refresh() async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    await _loadWithCache();
  }

  /// Carga la lista de rutinas (para uso externo).
  Future<void> loadRoutines() async {
    await _loadWithCache();
  }

  // ── CRUD con caché local ─────────────────────────────────────────────────

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

      await _persistCache();
      return routine;
    } catch (e) {
      debugPrint('[RoutineProvider] Error creating routine: $e');
      _errorMessage = e.toString();
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

      await _persistCache();
      return routine;
    } catch (e) {
      debugPrint('[RoutineProvider] Error updating routine $id: $e');
      _errorMessage = e.toString();
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

      await _persistCache();
      return true;
    } catch (e) {
      debugPrint('[RoutineProvider] Error deleting routine $id: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _persistCache() async {
    await CacheManager.setCache(
      'routines',
      _routines.map((r) => r.toJson()).toList(),
    );
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }
}
