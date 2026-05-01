import 'package:flutter/material.dart';

import '../../data/datasources/profile_datasource.dart';

/// ChangeNotifier que centraliza el estado del perfil: preferencias, importación
/// y gestión de datos.
///
/// Sigue el patrón de [AuthProvider]: inyección simple, helpers privados
/// `_setLoading`/`_clearStatus`, `notifyListeners()`.
///
/// Delega el acceso a datos en [ProfileDatasource], que encapsula
/// [SettingsManager], [ApiClient] y [CacheManager].
class ProfileProvider extends ChangeNotifier {
  final ProfileDatasource _datasource;

  ProfileProvider({ProfileDatasource? datasource})
    : _datasource = datasource ?? ProfileDatasource();

  // ── Estado ───────────────────────────────────────────────────────────────

  String? _displayName;
  String _weightUnit = 'kg';

  bool _isImporting = false;
  bool _isClearing = false;
  String? _statusMessage;
  bool? _isSuccess;

  String? get displayName => _displayName;
  String get weightUnit => _weightUnit;

  bool get isImporting => _isImporting;
  bool get isClearing => _isClearing;
  String? get statusMessage => _statusMessage;
  bool? get isSuccess => _isSuccess;

  // ── Inicialización ──────────────────────────────────────────────────────

  /// Carga las preferencias guardadas desde el datasource.
  Future<void> loadProfile() async {
    final name = await _datasource.getDisplayName();
    final unit = await _datasource.getWeightUnit();
    _displayName = name;
    _weightUnit = unit;
    notifyListeners();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _clearStatus() {
    _statusMessage = null;
    _isSuccess = null;
    notifyListeners();
  }

  // ── Acciones de perfil ─────────────────────────────────────────────────

  /// Actualiza el nombre de usuario.
  Future<void> updateDisplayName(String name) async {
    await _datasource.setDisplayName(name);
    _displayName = name;
    notifyListeners();
  }

  /// Cambia la unidad de peso.
  Future<void> setWeightUnit(String unit) async {
    await _datasource.setWeightUnit(unit);
    _weightUnit = unit;
    notifyListeners();
  }

  // ── Importación CSV (Hevy) ──────────────────────────────────────────────

  /// Importa un archivo CSV desde Hevy via el datasource.
  Future<void> importCsv(String filePath) async {
    _isImporting = true;
    _clearStatus();
    notifyListeners();

    try {
      final result = await _datasource.importCsv(filePath);

      _isSuccess = result.isSuccess;
      _statusMessage = result.isSuccess
          ? 'Importadas ${result.successCount} series correctamente. '
                'Fallos: ${result.failedCount} '
                '(detalles: ${result.failedRowsCount})'
                '${result.failedPreview != null && result.failedPreview!.isNotEmpty ? '\n\nPrimeros fallos:\n${result.failedPreview}' : ''}'
          : 'Nada importado. ${result.failedCount} filas fallaron.';
    } catch (e) {
      _isSuccess = false;
      _statusMessage = 'Error: $e';
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  // ── Borrar datos ────────────────────────────────────────────────────────

  /// Borra todos los entrenamientos y la caché local via el datasource.
  Future<void> clearData() async {
    _isClearing = true;
    _clearStatus();
    notifyListeners();

    try {
      await _datasource.clearData();
      _isSuccess = true;
      _statusMessage = 'Todos los entrenamientos han sido borrados.';
    } catch (e) {
      _isSuccess = false;
      _statusMessage = 'Error: $e';
    } finally {
      _isClearing = false;
      notifyListeners();
    }
  }
}
