import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:shoptrack/models/app_backup.dart';
import 'package:shoptrack/models/app_settings.dart';
import 'package:shoptrack/models/cloud_backup_status.dart';
import 'package:shoptrack/services/cloud_backup_service.dart';

class MockGoogleSignIn extends Fake implements GoogleSignIn {
  final Stream<GoogleSignInAuthenticationEvent> _events = const Stream.empty();
  
  @override
  Stream<GoogleSignInAuthenticationEvent> get authenticationEvents => _events;

  @override
  Future<GoogleSignInAccount?> attemptLightweightAuthentication({bool reportAllExceptions = false}) async => null;
}

class MockGoogleSignInAccount extends Fake implements GoogleSignInAccount {
  @override
  final String id = 'test_id';
  @override
  final String email = 'test@example.com';
}

class TestGoogleDriveBackupService extends GoogleDriveBackupService {
  final drive.DriveApi? mockDriveApi;
  TestGoogleDriveBackupService({this.mockDriveApi, super.googleSignIn});

  @override
  Future<drive.DriveApi?> getDriveApi({bool promptIfNecessary = true}) async {
    if (mockDriveApi != null) return mockDriveApi;
    return super.getDriveApi(promptIfNecessary: promptIfNecessary);
  }
}

class MockDriveApi extends Fake implements drive.DriveApi {
  final MockFilesResource filesResource = MockFilesResource();
  @override
  drive.FilesResource get files => filesResource;
}

class MockFilesResource extends Fake implements drive.FilesResource {
  drive.FileList? listResult;
  drive.File? createResult;
  drive.File? updateResult;
  Object? getResult;

  @override
  Future<drive.FileList> list({
    String? q,
    String? spaces,
    String? corpora,
    String? corpus,
    String? driveId,
    bool? includeItemsFromAllDrives,
    String? includeLabels,
    String? includePermissionsForView,
    bool? includeTeamDriveItems,
    String? orderBy,
    int? pageSize,
    String? pageToken,
    String? teamDriveId,
    bool? supportsAllDrives,
    bool? supportsTeamDrives,
    String? $fields,
  }) async => listResult ?? drive.FileList(files: []);

  @override
  Future<drive.File> create(
    drive.File request, {
    bool? enforceSingleParent,
    bool? ignoreDefaultVisibility,
    String? includeLabels,
    String? includePermissionsForView,
    bool? keepRevisionForever,
    String? ocrLanguage,
    bool? useContentAsIndexableText,
    bool? supportsAllDrives,
    bool? supportsTeamDrives,
    drive.Media? uploadMedia,
    dynamic uploadOptions,
    String? $fields,
  }) async => createResult ?? drive.File();

  @override
  Future<drive.File> update(
    drive.File request,
    String fileId, {
    String? addParents,
    bool? enforceSingleParent,
    String? includeLabels,
    String? includePermissionsForView,
    bool? keepRevisionForever,
    String? ocrLanguage,
    String? removeParents,
    bool? useContentAsIndexableText,
    bool? supportsAllDrives,
    bool? supportsTeamDrives,
    drive.Media? uploadMedia,
    dynamic uploadOptions,
    String? $fields,
  }) async => updateResult ?? drive.File();

  @override
  Future<Object> get(
    String fileId, {
    bool? acknowledgeAbuse,
    String? includeLabels,
    String? includePermissionsForView,
    bool? supportsAllDrives,
    bool? supportsTeamDrives,
    drive.DownloadOptions downloadOptions = drive.DownloadOptions.metadata,
    String? $fields,
  }) async => getResult ?? drive.File();
}

void main() {
  group('Sprint 14.3: Google Drive Cloud Backup Service', () {
    late MockGoogleSignIn mockGoogleSignIn;
    late MockDriveApi mockDriveApi;
    late TestGoogleDriveBackupService service;

    setUp(() {
      mockGoogleSignIn = MockGoogleSignIn();
      mockDriveApi = MockDriveApi();
      service = TestGoogleDriveBackupService(
        mockDriveApi: mockDriveApi,
        googleSignIn: mockGoogleSignIn,
      );
    });

    test('Initial state is notSignedIn', () {
      expect(service.status.state, CloudBackupState.notSignedIn);
    });

    test('createCloudBackup fails when getDriveApi returns null', () async {
      final serviceNoAuth = TestGoogleDriveBackupService(
        mockDriveApi: null,
        googleSignIn: mockGoogleSignIn,
      );

      final backup = AppBackup(
        backupVersion: 1,
        appVersion: '1.0.0',
        timestamp: DateTime.now(),
        sessions: [],
        settings: const AppSettings(),
      );

      await serviceNoAuth.createCloudBackup(backup);
      
      expect(serviceNoAuth.status.state, CloudBackupState.error);
      expect(serviceNoAuth.status.errorMessage, contains('authorize'));
    });

    test('createCloudBackup performs create when no file exists', () async {
      mockDriveApi.filesResource.listResult = drive.FileList(files: []);
      mockDriveApi.filesResource.createResult = drive.File(id: 'new_id');

      final backup = AppBackup(
        backupVersion: 1,
        appVersion: '1.0.0',
        timestamp: DateTime.now(),
        sessions: [],
        settings: const AppSettings(),
      );

      await service.createCloudBackup(backup);
      
      expect(service.status.state, CloudBackupState.available);
      expect(service.status.lastBackupTime, isNotNull);
    });

    test('createCloudBackup performs update when file exists', () async {
      mockDriveApi.filesResource.listResult = drive.FileList(files: [
        drive.File(id: 'existing_id', name: 'shoptrack_backup.json'),
      ]);
      mockDriveApi.filesResource.updateResult = drive.File(id: 'existing_id');

      final backup = AppBackup(
        backupVersion: 1,
        appVersion: '1.0.0',
        timestamp: DateTime.now(),
        sessions: [],
        settings: const AppSettings(),
      );

      await service.createCloudBackup(backup);
      
      expect(service.status.state, CloudBackupState.available);
    });

    test('downloadCloudBackup fails when no file exists', () async {
      mockDriveApi.filesResource.listResult = drive.FileList(files: []);

      final result = await service.downloadCloudBackup();
      
      expect(result, isNull);
      expect(service.status.state, CloudBackupState.noBackupFound);
    });

    test('downloadCloudBackup succeeds and returns backup', () async {
      final backup = AppBackup(
        backupVersion: 1,
        appVersion: '1.0.0',
        timestamp: DateTime.now(),
        sessions: [],
        settings: const AppSettings(),
      );
      final jsonStr = jsonEncode(backup.toJson());
      final bytes = utf8.encode(jsonStr);

      mockDriveApi.filesResource.listResult = drive.FileList(files: [
        drive.File(id: 'existing_id', name: 'shoptrack_backup.json'),
      ]);
      mockDriveApi.filesResource.getResult = drive.Media(
        Stream.value(bytes),
        bytes.length,
      );

      final result = await service.downloadCloudBackup();
      
      expect(result, isNotNull);
      expect(result!.appVersion, '1.0.0');
      expect(service.status.state, CloudBackupState.available);
    });
  });
}
