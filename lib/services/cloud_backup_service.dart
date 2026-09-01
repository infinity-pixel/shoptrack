import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import '../models/cloud_backup_status.dart';
import '../models/app_backup.dart';

abstract class CloudBackupService extends ChangeNotifier {
  CloudBackupStatus get status;
  Future<void> createCloudBackup(AppBackup backup);
  Future<AppBackup?> downloadCloudBackup();
  Future<void> refreshStatus();
}

class GoogleDriveBackupService extends ChangeNotifier implements CloudBackupService {
  static const String _backupFileName = 'shoptrack_backup.json';
  static const List<String> _driveScopes = [drive.DriveApi.driveAppdataScope];

  final GoogleSignIn _googleSignIn;
  GoogleSignInAccount? _currentUser;
  CloudBackupStatus _status = const CloudBackupStatus(state: CloudBackupState.notSignedIn);

  @override
  CloudBackupStatus get status => _status;

  GoogleDriveBackupService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn.instance {
    _googleSignIn.authenticationEvents.listen((event) {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        _currentUser = event.user;
      } else if (event is GoogleSignInAuthenticationEventSignOut) {
        _currentUser = null;
      }
      updateSignInState(_currentUser != null);
    });
    _init();
  }

  Future<void> _init() async {
    try {
      final account = await _googleSignIn.attemptLightweightAuthentication();
      if (account != null) {
        _currentUser = account;
        updateSignInState(true);
      }
    } catch (e) {
      // Ignore errors in environments where Google Sign-In is not available (e.g., tests)
      debugPrint('CloudBackupService _init error: $e');
    }
  }

  @override
  Future<void> createCloudBackup(AppBackup backup) async {
    _status = const CloudBackupStatus(state: CloudBackupState.backupInProgress);
    notifyListeners();

    try {
      final driveApi = await getDriveApi();
      if (driveApi == null) {
        _status = const CloudBackupStatus(
          state: CloudBackupState.error,
          errorMessage: 'Failed to authorize Google Drive access.',
        );
        notifyListeners();
        return;
      }

      final existingFileId = await _findBackupFileId(driveApi);
      final jsonContent = jsonEncode(backup.toJson());
      final bytes = utf8.encode(jsonContent);
      final media = drive.Media(Stream.value(bytes), bytes.length);

      if (existingFileId != null) {
        await driveApi.files.update(
          drive.File(),
          existingFileId,
          uploadMedia: media,
        );
      } else {
        await driveApi.files.create(
          drive.File(
            name: _backupFileName,
            parents: ['appDataFolder'],
          ),
          uploadMedia: media,
        );
      }

      _status = CloudBackupStatus(
        state: CloudBackupState.available,
        lastBackupTime: DateTime.now(),
      );
    } catch (e) {
      _status = CloudBackupStatus(
        state: CloudBackupState.error,
        errorMessage: 'Cloud backup failed: ${e.toString()}',
      );
    }
    notifyListeners();
  }

  @override
  Future<AppBackup?> downloadCloudBackup() async {
    _status = const CloudBackupStatus(state: CloudBackupState.restoreInProgress);
    notifyListeners();

    try {
      final driveApi = await getDriveApi();
      if (driveApi == null) {
        _status = const CloudBackupStatus(
          state: CloudBackupState.error,
          errorMessage: 'Failed to authorize Google Drive access.',
        );
        notifyListeners();
        return null;
      }

      final fileId = await _findBackupFileId(driveApi);
      if (fileId == null) {
        _status = const CloudBackupStatus(state: CloudBackupState.noBackupFound);
        notifyListeners();
        return null;
      }

      final drive.Media response = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> data = await response.stream.expand((x) => x).toList();
      final String jsonStr = utf8.decode(data);
      final Map<String, dynamic> jsonMap = jsonDecode(jsonStr);
      
      final backup = AppBackup.fromJson(jsonMap);
      
      _status = CloudBackupStatus(
        state: CloudBackupState.available,
        lastBackupTime: backup.timestamp,
      );
      notifyListeners();
      return backup;
    } catch (e) {
      _status = CloudBackupStatus(
        state: CloudBackupState.error,
        errorMessage: 'Cloud restore failed: ${e.toString()}',
      );
      notifyListeners();
      return null;
    }
  }

  @override
  Future<void> refreshStatus() async {
    final user = _currentUser;
    if (user == null) {
      _status = const CloudBackupStatus(state: CloudBackupState.notSignedIn);
      notifyListeners();
      return;
    }

    try {
      final driveApi = await getDriveApi(promptIfNecessary: false);
      if (driveApi != null) {
        final file = await _findBackupFile(driveApi);
        if (file != null) {
          _status = CloudBackupStatus(
            state: CloudBackupState.available,
            lastBackupTime: file.modifiedTime,
          );
        } else {
          _status = const CloudBackupStatus(state: CloudBackupState.noBackupFound);
        }
      } else {
        // Needs authorization
        _status = const CloudBackupStatus(state: CloudBackupState.available);
      }
    } catch (_) {
      // Ignore background refresh errors
    }
    notifyListeners();
  }

  void updateSignInState(bool isSignedIn) {
    if (!isSignedIn) {
      _status = const CloudBackupStatus(state: CloudBackupState.notSignedIn);
    } else {
      if (_status.state == CloudBackupState.notSignedIn) {
        _status = const CloudBackupStatus(state: CloudBackupState.available);
        refreshStatus();
      }
    }
    notifyListeners();
  }

  @protected
  Future<drive.DriveApi?> getDriveApi({bool promptIfNecessary = true}) async {
    final user = _currentUser;
    if (user == null) return null;

    final authClient = user.authorizationClient;
    GoogleSignInClientAuthorization? authz;
    
    try {
      if (promptIfNecessary) {
        authz = await authClient.authorizeScopes(_driveScopes);
      } else {
        authz = await authClient.authorizationForScopes(_driveScopes);
      }
    } catch (_) {
      return null;
    }

    if (authz == null) return null;

    final client = authz.authClient(scopes: _driveScopes);
    return drive.DriveApi(client);
  }

  Future<String?> _findBackupFileId(drive.DriveApi driveApi) async {
    final file = await _findBackupFile(driveApi);
    return file?.id;
  }

  Future<drive.File?> _findBackupFile(drive.DriveApi driveApi) async {
    final drive.FileList list = await driveApi.files.list(
      q: "name = '$_backupFileName'",
      spaces: 'appDataFolder',
      $fields: 'files(id, name, modifiedTime)',
    );

    if (list.files == null || list.files!.isEmpty) {
      return null;
    }

    return list.files!.first;
  }
}
