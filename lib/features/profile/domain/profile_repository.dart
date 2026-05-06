import 'entities/import_result.dart';

abstract class IProfileRepository {
  Future<String?> getDisplayName();
  Future<void> setDisplayName(String name);
  Future<String> getWeightUnit();
  Future<void> setWeightUnit(String unit);
  Future<ImportResult> importCsv(String filePath);
  Future<void> clearData();
}
