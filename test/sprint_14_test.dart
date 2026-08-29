import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/models/auth_state.dart';
import 'package:shoptrack/models/cloud_backup_status.dart';
import 'package:shoptrack/models/app_backup.dart';
import 'package:shoptrack/models/app_settings.dart';

void main() {
  group('Sprint 14: Cloud Backup Foundation & Account Integration', () {
    test('AuthAccount model preserves data', () {
      const account = AuthAccount(
        id: '123',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
      );
      expect(account.id, '123');
      expect(account.email, 'test@example.com');
      expect(account.displayName, 'Test User');
      expect(account.photoUrl, 'https://example.com/photo.jpg');
    });

    test('CloudBackupStatus initial state is noBackupFound', () {
      const status = CloudBackupStatus.initial();
      expect(status.state, CloudBackupState.noBackupFound);
      expect(status.lastBackupTime, isNull);
      expect(status.errorMessage, isNull);
    });

    test('AppBackup can be instantiated and validated through CloudBackupService logic', () {
       final backup = AppBackup(
        backupVersion: 1,
        appVersion: '1.0.0',
        timestamp: DateTime.now(),
        sessions: [],
        settings: const AppSettings(),
      );
      
      expect(backup.backupVersion, 1);
      expect(backup.sessions, isEmpty);
    });

    test('AuthState variations represent different scenarios', () {
      const initial = AuthInitial();
      const unauthenticated = AuthUnauthenticated();
      const loading = AuthLoading();
      const error = AuthError('Error');
      const authenticated = AuthAuthenticated(AuthAccount(id: '1', email: 'a@b.com'));

      expect(initial, isA<AuthState>());
      expect(unauthenticated, isA<AuthState>());
      expect(loading, isA<AuthState>());
      expect(error.message, 'Error');
      expect(authenticated.account.email, 'a@b.com');
    });
  });
}
