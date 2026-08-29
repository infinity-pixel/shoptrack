enum CloudBackupState {
  notSignedIn,
  noBackupFound,
  available,
  backupInProgress,
  restoreInProgress,
  error,
}

class CloudBackupStatus {
  final CloudBackupState state;
  final DateTime? lastBackupTime;
  final String? errorMessage;

  const CloudBackupStatus({
    required this.state,
    this.lastBackupTime,
    this.errorMessage,
  });

  const CloudBackupStatus.initial() : state = CloudBackupState.noBackupFound, lastBackupTime = null, errorMessage = null;
}
