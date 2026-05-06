import 'package:flutter_test/flutter_test.dart';
import 'package:gym_analytics_mobile/features/profile/domain/entities/import_result.dart';
import 'package:gym_analytics_mobile/features/profile/domain/profile_repository.dart';
import 'package:gym_analytics_mobile/features/profile/presentation/providers/profile_provider.dart';

class _FakeProfileRepository implements IProfileRepository {
  String? displayName;
  String weightUnit;
  ImportResult? importResult;
  bool clearDataCalled = false;

  _FakeProfileRepository({
    this.displayName,
    this.weightUnit = 'kg',
    this.importResult,
  });

  @override
  Future<String?> getDisplayName() async => displayName;

  @override
  Future<void> setDisplayName(String name) async {
    displayName = name;
  }

  @override
  Future<String> getWeightUnit() async => weightUnit;

  @override
  Future<void> setWeightUnit(String unit) async {
    weightUnit = unit;
  }

  @override
  Future<ImportResult> importCsv(String filePath) async {
    return importResult ??
        const ImportResult(
          isSuccess: false,
          successCount: 0,
          failedCount: 0,
          failedRowsCount: 0,
        );
  }

  @override
  Future<void> clearData() async {
    clearDataCalled = true;
  }
}

void main() {
  group('ProfileProvider', () {
    test('loadProfile() → displayName y weightUnit del fake', () async {
      final repo = _FakeProfileRepository(
        displayName: 'John',
        weightUnit: 'lbs',
      );
      final provider = ProfileProvider(repository: repo);

      await provider.loadProfile();

      expect(provider.displayName, 'John');
      expect(provider.weightUnit, 'lbs');
    });

    test('updateDisplayName() → displayName actualizado', () async {
      final repo = _FakeProfileRepository(displayName: 'Old');
      final provider = ProfileProvider(repository: repo);

      await provider.updateDisplayName('New');

      expect(provider.displayName, 'New');
      expect(repo.displayName, 'New');
    });

    test('importCsv() → isImporting true→false, isSuccess según fake',
        () async {
      final repo = _FakeProfileRepository(
        importResult: const ImportResult(
          isSuccess: true,
          successCount: 10,
          failedCount: 0,
          failedRowsCount: 0,
        ),
      );
      final provider = ProfileProvider(repository: repo);

      expect(provider.isImporting, false);

      final future = provider.importCsv('path/to/file.csv');
      expect(provider.isImporting, true);

      await future;

      expect(provider.isImporting, false);
      expect(provider.isSuccess, true);
      expect(provider.statusMessage, contains('10'));
    });

    test('clearData() → isClearing true→false, isSuccess true', () async {
      final repo = _FakeProfileRepository();
      final provider = ProfileProvider(repository: repo);

      expect(provider.isClearing, false);

      final future = provider.clearData();
      expect(provider.isClearing, true);

      await future;

      expect(provider.isClearing, false);
      expect(provider.isSuccess, true);
      expect(repo.clearDataCalled, true);
    });
  });
}
