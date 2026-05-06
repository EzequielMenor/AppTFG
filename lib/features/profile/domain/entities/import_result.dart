/// Resultado de una importación CSV.
class ImportResult {
  final bool isSuccess;
  final int successCount;
  final int failedCount;
  final int failedRowsCount;
  final String? failedPreview;

  const ImportResult({
    required this.isSuccess,
    required this.successCount,
    required this.failedCount,
    required this.failedRowsCount,
    this.failedPreview,
  });
}
