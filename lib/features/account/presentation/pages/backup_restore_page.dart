import 'package:flutter/material.dart';
import '../../../../app.dart';
import '../../../../core/data/settings_repository.dart';
import '../../../../core/data/shopping_repository.dart';
import '../../../../services/backup_service.dart';

class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({super.key});

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  late final BackupService _backupService;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _backupService = BackupService(
      LocalShoppingRepository(),
      LocalSettingsRepository(),
    );
  }

  Future<void> _createBackup() async {
    setState(() => _isProcessing = true);
    try {
      await _backupService.createBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create backup: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _restoreBackup() async {
    try {
      final backup = await _backupService.pickAndValidateBackup();
      if (backup == null) return;

      if (!mounted) return;

      final confirmed = await showDialog<bool>(
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

      if (confirmed == true && mounted) {
        setState(() => _isProcessing = true);
        await _backupService.restoreBackup(backup);
        
        // Refresh app state
        if (mounted) {
          final service = ShopTrackApp.of(context);
          await service.loadSettings();
          service.notifyDataRestored();
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data restored successfully')),
          );
          // Return true to parent to trigger data reload if needed
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to restore backup: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader('BACKUP'),
              _buildTile(
                icon: Icons.upload_file_outlined,
                title: 'Create Backup',
                subtitle: 'Export your shopping data and settings to a JSON file',
                onTap: _isProcessing ? null : _createBackup,
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('RESTORE'),
              _buildTile(
                icon: Icons.file_download_outlined,
                title: 'Restore from Backup',
                subtitle: 'Select a previously saved ShopTrack backup file',
                onTap: _isProcessing ? null : _restoreBackup,
                isDestructive: true,
              ),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
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
