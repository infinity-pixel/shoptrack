import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app.dart';
import '../../../../core/data/settings_repository.dart';
import '../../../../core/data/shopping_repository.dart';
import '../../../../models/cloud_backup_status.dart';
import '../../../../services/backup_service.dart';

class BackupRestorePage extends StatefulWidget {
  final int initialTab;
  const BackupRestorePage({super.key, this.initialTab = 0});

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  late final BackupService _localBackupService;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _localBackupService = BackupService(
      LocalShoppingRepository(),
      LocalSettingsRepository(),
    );
  }

  Future<void> _createLocalBackup() async {
    setState(() => _isProcessing = true);
    try {
      await _localBackupService.createBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Local backup created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create local backup: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _restoreLocalBackup() async {
    try {
      final backup = await _localBackupService.pickAndValidateBackup();
      if (backup == null) return;

      if (!mounted) return;

      final confirmed = await _showRestoreConfirmation();
      if (confirmed == true && mounted) {
        setState(() => _isProcessing = true);
        await _localBackupService.restoreBackup(backup);
        await _refreshAfterRestore();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to restore local backup: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _createCloudBackup() async {
    setState(() => _isProcessing = true);
    try {
      final cloudService = ShopTrackApp.cloudBackupOf(context);
      final appBackup = await _localBackupService.createBackupObject();
      await cloudService.createCloudBackup(appBackup);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cloud backup failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _restoreCloudBackup() async {
    final cloudService = ShopTrackApp.cloudBackupOf(context);
    try {
      final backup = await cloudService.downloadCloudBackup();
      if (backup == null) return;

      if (!mounted) return;
      final confirmed = await _showRestoreConfirmation();
      if (confirmed == true && mounted) {
        setState(() => _isProcessing = true);
        await _localBackupService.restoreBackup(backup);
        await _refreshAfterRestore();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cloud restore failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<bool?> _showRestoreConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup?'),
        content: const Text(
          'Restoring this backup will replace your current local ShopTrack data. '
          'This action cannot be undone unless you have another backup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshAfterRestore() async {
    if (mounted) {
      final service = ShopTrackApp.of(context);
      await service.loadSettings();
      if (mounted) {
        service.notifyDataRestored();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data restored successfully')),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Backup & Restore'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Local'),
              Tab(text: 'Cloud'),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                _buildLocalTab(),
                _buildCloudTab(),
              ],
            ),
            if (_isProcessing)
              Container(
                color: Colors.black.withValues(alpha: 0.1),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('LOCAL BACKUP'),
        _buildTile(
          icon: Icons.upload_file_outlined,
          title: 'Create Local Backup',
          subtitle: 'Export your data to a JSON file',
          onTap: _isProcessing ? null : _createLocalBackup,
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('LOCAL RESTORE'),
        _buildTile(
          icon: Icons.file_download_outlined,
          title: 'Restore from Local File',
          subtitle: 'Select a previously saved JSON backup',
          onTap: _isProcessing ? null : _restoreLocalBackup,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildCloudTab() {
    final cloudService = ShopTrackApp.cloudBackupOf(context);
    
    return ListenableBuilder(
      listenable: cloudService,
      builder: (context, _) {
        final status = cloudService.status;
        final bool isNotSignedIn = status.state == CloudBackupState.notSignedIn;
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (isNotSignedIn)
              _buildSignInNotice()
            else ...[
              _buildSectionHeader('CLOUD BACKUP'),
              _buildTile(
                icon: Icons.cloud_upload_outlined,
                title: 'Back up to Cloud',
                subtitle: 'Sync your data to Google Drive App Data',
                onTap: _isProcessing ? null : _createCloudBackup,
              ),
              if (status.lastBackupTime != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    'Last backup: ${DateFormat('d MMM yyyy, HH:mm').format(status.lastBackupTime!)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              const SizedBox(height: 24),
              _buildSectionHeader('CLOUD RESTORE'),
              _buildTile(
                icon: Icons.cloud_download_outlined,
                title: 'Restore from Cloud',
                subtitle: 'Download your latest cloud backup',
                onTap: _isProcessing || status.state == CloudBackupState.noBackupFound ? null : _restoreCloudBackup,
                isDestructive: true,
              ),
              if (status.state == CloudBackupState.noBackupFound)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('No backup found in your cloud storage.', style: TextStyle(color: Colors.orange, fontSize: 12)),
                ),
            ],
            if (status.errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(status.errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSignInNotice() {
    return Card(
      color: Colors.blue[50],
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            const Text('Sign in Required', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'You need to sign in with your Google account to use cloud backup features.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (mounted) {
                  ShopTrackApp.authOf(context).signIn();
                }
              },
              child: const Text('Sign In with Google'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? Colors.red : Colors.blue),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDestructive ? Colors.red : null)),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}
