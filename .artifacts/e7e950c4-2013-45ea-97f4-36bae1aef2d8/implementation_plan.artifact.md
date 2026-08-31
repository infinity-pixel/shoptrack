# Sprint 14.3: Real Google Drive Cloud Backup & Restore

This sprint implements the actual Google Drive integration for cloud backup and restore using the `appDataFolder`.

## Proposed Changes

### [Component Name]

#### [MODIFY] [cloud_backup_service.dart](file:///C:/Users/UseR/develop/Projects/shoptrack/lib/services/cloud_backup_service.dart)
- Replace placeholder logic with real Google Drive API implementation.
- Implement scope management for `drive.appdata`.
- Implement backup creation (upload/update) to `appDataFolder`.
- Implement backup download and parsing.
- Implement status refreshing to detect existing backups.

## Verification Plan

### Automated Tests
- Create `test/sprint_14_3_test.dart` to verify `GoogleDriveBackupService` logic using mocks.
- Run all existing tests to ensure no regressions.

### Manual Verification
1. Sign in with Google on an Android device/emulator.
2. Go to Account > Cloud Backup.
3. Perform a backup. Verify Drive permission request and successful backup status.
4. Add a dummy session locally.
5. Perform a restore. Verify confirmation dialog and data restoration.
6. Verify that cancelling the restore preserves local data.
7. Verify error handling by disabling internet during the process.
