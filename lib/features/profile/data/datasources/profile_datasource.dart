import 'dart:convert';
import '../../../../core/cache/cache_manager.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/settings/settings_manager.dart';
import '../../domain/entities/import_result.dart';

/// Centraliza el acceso a datos del perfil: preferencias locales,
/// importación de CSV desde Hevy y limpieza de datos.
///
/// Encapsula [SettingsManager], [ApiClient] y [CacheManager] para que
/// [ProfileProvider] no dependa directamente de infraestructura.
///
/// Sigue el mismo patrón que [AnalyticsDatasource] y [WorkoutDatasource].
@Deprecated('Use IProfileRepository + ProfileRepositoryImpl')
class ProfileDatasource {
  // ── Preferencias locales (SharedPreferences vía SettingsManager) ────────

  Future<String?> getDisplayName() => SettingsManager.getDisplayName();

  Future<void> setDisplayName(String name) =>
      SettingsManager.setDisplayName(name);

  Future<String> getWeightUnit() => SettingsManager.getWeightUnit();

  Future<void> setWeightUnit(String unit) =>
      SettingsManager.setWeightUnit(unit);

  // ── Importación CSV (Hevy) ──────────────────────────────────────────────

  /// Importa un archivo CSV desde Hevy via multipart upload.
  ///
  /// Retorna un [ImportResult] con el conteo de éxito/fallo y preview
  /// de las filas problemáticas.
  Future<ImportResult> importCsv(String filePath) async {
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
      final String failedPreview =
          failedRowsRaw.take(3).map((e) => e.toString()).join('\n');

      return ImportResult(
        isSuccess: success > 0,
        successCount: success,
        failedCount: failed,
        failedRowsCount: failedRowsCount,
        failedPreview: failedPreview,
      );
    }

    throw Exception('Error del servidor (${response.statusCode}).');
  }

  // ── Limpieza de datos ───────────────────────────────────────────────────

  /// Borra todos los entrenamientos via API y limpia la caché local.
  Future<void> clearData() async {
    final response = await ApiClient.delete('/api/workouts');
    if (response.statusCode == 200) {
      await CacheManager.clearAllCache();
    } else {
      throw Exception('Error del servidor (${response.statusCode}).');
    }
  }
}


