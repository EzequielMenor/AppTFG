import '../../../../core/settings/settings_manager.dart';

/// Encapsula operaciones de preferencias locales vía [SettingsManager].
class ProfileLocalDatasource {
  Future<String?> getDisplayName() => SettingsManager.getDisplayName();

  Future<void> setDisplayName(String name) =>
      SettingsManager.setDisplayName(name);

  Future<String> getWeightUnit() => SettingsManager.getWeightUnit();

  Future<void> setWeightUnit(String unit) =>
      SettingsManager.setWeightUnit(unit);
}
