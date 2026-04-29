import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../../../../core/cache/cache_manager.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/settings/settings_manager.dart';

/// ChangeNotifier que centraliza el estado del perfil: preferencias, importación
/// y gestión de datos.
///
/// Sigue el patrón de [AuthProvider]: inyección simple, helpers privados
/// `_setLoading`/`_clearStatus`, `notifyListeners()`.
///
/// Reemplaza el estado local + llamadas directas a [SettingsManager],
/// [ApiClient] y [CacheManager] en [ProfileScreen] y [CsvImportSheet].
class ProfileProvider extends ChangeNotifier {
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

  /// Carga las preferencias guardadas.
  Future<void> loadProfile() async {
    final name = await SettingsManager.getDisplayName();
    final unit = await SettingsManager.getWeightUnit();
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
    await SettingsManager.setDisplayName(name);
    _displayName = name;
    notifyListeners();
  }

  /// Cambia la unidad de peso.
  Future<void> setWeightUnit(String unit) async {
    await SettingsManager.setWeightUnit(unit);
    _weightUnit = unit;
    notifyListeners();
  }

  // ── Importación CSV (Hevy) ──────────────────────────────────────────────

  /// Importa un archivo CSV desde Hevy via multipart upload.
  Future<void> importCsv(String filePath) async {
    _isImporting = true;
    _clearStatus();
    notifyListeners();

    try {
      final response = await ApiClient.postMultipart(
        '/api/import/hevy',
        filePath: filePath,
        fieldName: 'file',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = json.decode(response.body);
        final int success = body['successCount'] ?? 0;
        final int failed = body['failedCount'] ?? 0;
        final List<dynamic> failedRowsRaw = body['failedRows'] ?? [];
        final int failedRowsCount = failedRowsRaw.length;
        final String failedPreview = failedRowsRaw
            .take(3)
            .map((e) => e.toString())
            .join('\n');

        _isSuccess = success > 0;
        _statusMessage = success > 0
            ? 'Importadas $success series correctamente. Fallos: $failed (detalles: $failedRowsCount)'
                '${failedPreview.isNotEmpty ? '\n\nPrimeros fallos:\n$failedPreview' : ''}'
            : 'Nada importado. $failed filas fallaron.';
      } else {
        _isSuccess = false;
        _statusMessage = 'Error del servidor (${response.statusCode}).';
      }
    } catch (e) {
      _isSuccess = false;
      _statusMessage = 'Error: $e';
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  // ── Borrar datos ────────────────────────────────────────────────────────

  /// Borra todos los entrenamientos y la caché local.
  Future<void> clearData() async {
    _isClearing = true;
    _clearStatus();
    notifyListeners();

    try {
      final response = await ApiClient.delete('/api/workouts');
      if (response.statusCode == 200) {
        await CacheManager.clearAllCache();
        _isSuccess = true;
        _statusMessage = 'Todos los entrenamientos han sido borrados.';
      } else {
        _isSuccess = false;
        _statusMessage = 'Error del servidor (${response.statusCode}).';
      }
    } catch (e) {
      _isSuccess = false;
      _statusMessage = 'Error: $e';
    } finally {
      _isClearing = false;
      notifyListeners();
    }
  }
}
