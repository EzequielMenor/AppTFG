import '../../domain/profile_repository.dart';
import '../../domain/entities/import_result.dart';
import '../datasources/profile_local_datasource.dart';
import '../datasources/profile_remote_datasource.dart';
import '../../../../core/cache/cache_manager.dart';

/// Implementación de [IProfileRepository] que coordina fuentes locales
/// y remotas, además de la invalidación de caché.
class ProfileRepositoryImpl implements IProfileRepository {
  final ProfileLocalDatasource _local;
  final ProfileRemoteDatasource _remote;

  ProfileRepositoryImpl({
    required ProfileLocalDatasource local,
    required ProfileRemoteDatasource remote,
  })  : _local = local,
        _remote = remote;

  // ── Preferencias locales ────────────────────────────────────────────────

  @override
  Future<String?> getDisplayName() => _local.getDisplayName();

  @override
  Future<void> setDisplayName(String name) => _local.setDisplayName(name);

  @override
  Future<String> getWeightUnit() => _local.getWeightUnit();

  @override
  Future<void> setWeightUnit(String unit) => _local.setWeightUnit(unit);

  // ── Operaciones remotas ─────────────────────────────────────────────────

  @override
  Future<ImportResult> importCsv(String filePath) =>
      _remote.importCsv(filePath);

  @override
  Future<void> clearData() async {
    await _remote.clearWorkouts();
    await CacheManager.clearAllCache();
  }
}
