class DatabaseBackupConfig {
  const DatabaseBackupConfig({
    this.rowsPerRequest = 1000,
    this.invoiceIdChunkSize = 100,
    this.backupDirectoryName = 'database_backups',
    this.filePrefix = 'erad_backup_',
    this.retentionDays = 7,
    this.lastRunPreferenceKey = 'database_backup_last_run',
  });

  /// PostgREST tek istekte en fazla `max_rows` satır döndürür; tam veri için
  /// sayfa döngüsü bu boyutta ilerler.
  final int rowsPerRequest;

  /// Kalem tabloları, ait oldukları faturaların kimlikleriyle parçalar halinde
  /// çekilir; URL uzunluğu sınırını aşmamak için kullanılır.
  final int invoiceIdChunkSize;

  final String backupDirectoryName;
  final String filePrefix;
  final int retentionDays;
  final String lastRunPreferenceKey;
}
