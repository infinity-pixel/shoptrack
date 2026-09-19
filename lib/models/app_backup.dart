import 'app_settings.dart';
import 'shopping_session.dart';

class AppBackup {
  // Version 2 adds per-item currency. Older builds reject this version instead
  // of silently stripping currency codes from a restored multi-currency file.
  static const int currentVersion = 2;

  final int backupVersion;
  final String appVersion;
  final DateTime timestamp;
  final List<ShoppingSession> sessions;
  final AppSettings settings;

  AppBackup({
    required this.backupVersion,
    required this.appVersion,
    required this.timestamp,
    required this.sessions,
    required this.settings,
  });

  Map<String, dynamic> toJson() {
    return {
      'backupVersion': backupVersion,
      'appVersion': appVersion,
      'timestamp': timestamp.toIso8601String(),
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'settings': settings.toJson(),
    };
  }

  factory AppBackup.fromJson(Map<String, dynamic> json) {
    // Basic validation
    if (!json.containsKey('backupVersion')) {
      throw const FormatException('Missing backupVersion');
    }

    final int version = json['backupVersion'] as int;
    if (version > currentVersion) {
      throw FormatException('Unsupported backup version: $version');
    }

    return AppBackup(
      backupVersion: version,
      appVersion: json['appVersion'] as String? ?? 'Unknown',
      timestamp: DateTime.parse(json['timestamp'] as String),
      sessions: (json['sessions'] as List)
          .map((s) => ShoppingSession.fromJson(s as Map<String, dynamic>))
          .toList(),
      settings: AppSettings.fromJson(json['settings'] as Map<String, dynamic>),
    );
  }
}
