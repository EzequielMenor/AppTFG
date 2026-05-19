import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/import_result.dart';

/// Encapsula operaciones HTTP de perfil vía [ApiClient].
class ProfileRemoteDatasource {
  /// Importa un archivo CSV desde Hevy via multipart upload.
  ///
  /// Retorna un [ImportResult] con el conteo de éxito/fallo y preview
  /// de las filas problemáticas.
  Future<ImportResult> importCsv(String filePath) async {
    final response = await ApiClientLegacy.postMultipart(
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

  /// Borra todos los entrenamientos vía API.
  Future<void> clearWorkouts() async {
    final response = await ApiClientLegacy.delete('/api/workouts');
    if (response.statusCode != 200) {
      throw Exception('Error del servidor (${response.statusCode}).');
    }
  }
}
