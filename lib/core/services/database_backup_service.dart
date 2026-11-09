import 'dart:developer' as developer;
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../datasources/database_backup_config.dart';
import '../datasources/database_backup_remote_datasource.dart';

class DatabaseBackupService {
  DatabaseBackupService({
    required DatabaseBackupRemoteDataSource remoteDataSource,
    required DatabaseBackupConfig config,
    required SharedPreferences preferences,
    required SupabaseClient supabaseClient,
  }) : _remoteDataSource = remoteDataSource,
       _config = config,
       _preferences = preferences,
       _supabaseClient = supabaseClient;

  final DatabaseBackupRemoteDataSource _remoteDataSource;
  final DatabaseBackupConfig _config;
  final SharedPreferences _preferences;
  final SupabaseClient _supabaseClient;

  /// Günde bir kez tam yedek alır. Aynı gün ikinci kez çağrılırsa atlar.
  Future<String?> runDailyBackupIfNeeded() async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return null;

    final today = _dateStamp(DateTime.now());
    final preferenceKey = '${_config.lastRunPreferenceKey}:$userId';
    if (_preferences.getString(preferenceKey) == today) return null;

    return _saveBackup(
      userId: userId,
      date: today,
      preferenceKey: preferenceKey,
    );
  }

  /// Günlük sınırı beklemeden yedek alır.
  Future<String?> createBackup() async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('Yedek almak için oturum açık olmalı');
    }

    return _saveBackup(userId: userId, date: _dateStamp(DateTime.now()));
  }

  Future<String?> _saveBackup({
    required String userId,
    required String date,
    String? preferenceKey,
  }) async {
    try {
      final json = await _remoteDataSource.buildBackupJson();
      final directory = await _userDirectory(userId);
      final file = File(
        '${directory.path}${Platform.pathSeparator}'
        '${_config.filePrefix}$date.json',
      );
      final tempFile = File('${file.path}.tmp');

      await tempFile.writeAsString(json, flush: true);
      if (await file.exists()) await file.delete();
      await tempFile.rename(file.path);

      await _pruneOldBackups(directory);
      if (preferenceKey != null) {
        await _preferences.setString(preferenceKey, date);
      }

      return file.path;
    } catch (error, stackTrace) {
      developer.log(
        'Veritabanı yedeği alınamadı',
        name: 'DatabaseBackupService',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Uygulama özel (sandbox) dizininde kullanıcıya ayrı klasör.
  Future<Directory> _userDirectory(String userId) async {
    final base = await getApplicationSupportDirectory();
    final directory = Directory(
      '${base.path}${Platform.pathSeparator}'
      '${_config.backupDirectoryName}${Platform.pathSeparator}$userId',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<void> _pruneOldBackups(Directory directory) async {
    if (_config.retentionDays <= 0) return;

    final cutoff = DateTime.now().subtract(
      Duration(days: _config.retentionDays),
    );

    await for (final entity in directory.list()) {
      if (entity is! File) continue;
      final name = entity.path.split(Platform.pathSeparator).last;
      if (!name.startsWith(_config.filePrefix)) continue;

      final modified = (await entity.stat()).modified;
      if (modified.isBefore(cutoff)) await entity.delete();
    }
  }

  String _dateStamp(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
