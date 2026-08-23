import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/models/app_backup.dart';
import 'package:shoptrack/models/app_settings.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/models/shopping_session.dart';

void main() {
  group('Sprint 12: Local Backup & Restore - Serialization Tests', () {
    test('AppBackup toJson/fromJson preserves all data', () {
      final session = ShoppingSession(
        id: 'session-1',
        date: DateTime(2023, 8, 23),
        items: [
          const ShoppingItem(
            id: 'item-1',
            name: 'Milk',
            isPurchased: true,
            quantityValue: 2,
            priceValue: 100,
            pricingMode: PricingMode.total,
          ),
        ],
      );

      final settings = const AppSettings(
        theme: AppTheme.dark,
        currency: 'USD',
      );

      final backup = AppBackup(
        backupVersion: 1,
        appVersion: '1.0.0',
        timestamp: DateTime(2023, 8, 23, 12),
        sessions: [session],
        settings: settings,
      );

      final json = backup.toJson();
      final reconstructed = AppBackup.fromJson(json);

      expect(reconstructed.backupVersion, backup.backupVersion);
      expect(reconstructed.appVersion, backup.appVersion);
      expect(reconstructed.sessions.length, 1);
      expect(reconstructed.sessions[0].id, 'session-1');
      expect(reconstructed.sessions[0].items[0].name, 'Milk');
      expect(reconstructed.settings.theme, AppTheme.dark);
      expect(reconstructed.settings.currency, 'USD');
    });

    test('AppBackup.fromJson throws FormatException for missing backupVersion', () {
      final json = {
        'timestamp': DateTime.now().toIso8601String(),
        'sessions': [],
        'settings': const AppSettings().toJson(),
      };
      
      expect(() => AppBackup.fromJson(json), throwsFormatException);
    });

    test('AppBackup.fromJson throws FormatException for unsupported version', () {
      final json = {
        'backupVersion': 99,
        'timestamp': DateTime.now().toIso8601String(),
        'sessions': [],
        'settings': const AppSettings().toJson(),
      };
      
      expect(() => AppBackup.fromJson(json), throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('Unsupported backup version'))));
    });

    test('AppBackup.fromJson handles valid JSON correctly', () {
       final json = {
        'backupVersion': 1,
        'appVersion': '1.0.0',
        'timestamp': '2023-08-23T12:00:00Z',
        'sessions': [],
        'settings': {
          'theme': 'light',
          'currency': 'EUR',
          'language': 'English'
        },
      };

      final backup = AppBackup.fromJson(json);
      expect(backup.backupVersion, 1);
      expect(backup.settings.theme, AppTheme.light);
      expect(backup.settings.currency, 'EUR');
    });
  });
}
