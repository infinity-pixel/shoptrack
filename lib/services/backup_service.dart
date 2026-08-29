import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/data/shopping_repository.dart';
import '../core/data/settings_repository.dart';
import '../models/app_backup.dart';

class BackupService {
  final ShoppingRepository _shoppingRepository;
  final SettingsRepository _settingsRepository;

  BackupService(this._shoppingRepository, this._settingsRepository);

  Future<AppBackup> createBackupObject() async {
    final sessions = await _shoppingRepository.getAllSessions(includeEmpty: true);
    final settings = await _settingsRepository.getSettings();

    return AppBackup(
      backupVersion: AppBackup.currentVersion,
      appVersion: '1.0.0+1',
      timestamp: DateTime.now(),
      sessions: sessions,
      settings: settings,
    );
  }

  Future<void> createBackup() async {
    try {
      // 1. Create backup object
      final backup = await createBackupObject();

      // 2. Convert to JSON
      final jsonStr = jsonEncode(backup.toJson());

      // 4. Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final timestampStr = DateFormat('yyyy-MM-dd_HH-mm-ss').format(backup.timestamp);
      final fileName = 'shoptrack_backup_$timestampStr.json';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonStr);

      // 5. Share/Export
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)], subject: 'ShopTrack Backup');
    } catch (e) {
      rethrow;
    }
  }

  Future<AppBackup?> pickAndValidateBackup() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result.isEmpty || result.first.path == null) return null;

      final file = File(result.first.path!);
      final jsonStr = await file.readAsString();
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;

      return AppBackup.fromJson(jsonMap);
    } catch (e) {
      if (e is FormatException) {
        throw FormatException('Invalid backup file format: ${e.message}');
      }
      rethrow;
    }
  }

  Future<void> restoreBackup(AppBackup backup) async {
    try {
      // Safely replace data
      await _shoppingRepository.replaceSessions(backup.sessions);
      await _settingsRepository.saveSettings(backup.settings);
    } catch (e) {
      rethrow;
    }
  }
}
