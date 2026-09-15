import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/data/session_merge.dart';
import '../../../../core/theme/theme_presets.dart';
import '../../../../models/shopping_session.dart';
import '../../../../services/shopping_sync_service.dart';
import 'backup_restore_page.dart';

class CloudSyncPage extends StatelessWidget {
  const CloudSyncPage({super.key, required this.service});
  final ShoppingSyncService service;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: service,
    builder: (context, _) {
      final p = ShopTrackThemeTokens.of(context).palette;
      final conflicts = service.store?.conflicts ?? <Json>[];
      return Scaffold(
        appBar: AppBar(title: const Text('Cloud Sync')),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            service.status == ShoppingSyncState.saved
                                ? Icons.cloud_done_outlined
                                : Icons.cloud_sync_outlined,
                            color: p.primary,
                            size: 34,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            service.statusLabel,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(service.explanation),
                          if (service.lastSaved != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Last Saved: ${DateFormat.yMMMd().add_jm().format(service.lastSaved!)}',
                            ),
                          ],
                          if (service.status == ShoppingSyncState.saving) ...[
                            const SizedBox(height: 16),
                            const LinearProgressIndicator(),
                          ],
                          if (service.status != ShoppingSyncState.saved)
                            TextButton.icon(
                              onPressed: service.retry,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry Sync'),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Shopping lists, items, quantities, prices and purchase history are included. '
                      'Appearance preferences and profile photos remain on this device. '
                      'Open ShopTrack on your other device and sign in to the same account to load your history.',
                    ),
                  ),
                  if (conflicts.isNotEmpty) ...[
                    Text(
                      'Review Changes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The same record changed in two places. Review both versions before choosing. Other edits can continue syncing.',
                    ),
                    for (final conflict in conflicts)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                conflict['day'] as String,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text((conflict['fields'] as List).join(', ')),
                              if (conflict['batchId'] != null)
                                const Text(
                                  'This is part of an item transfer. Your choice applies to both related dates below.',
                                ),
                              const SizedBox(height: 12),
                              Text(
                                'This Device',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: p.primary,
                                ),
                              ),
                              Text(_describe(conflict['value'] as Json?)),
                              const SizedBox(height: 12),
                              Text(
                                'Saved Version',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: p.primary,
                                ),
                              ),
                              Text(_describe(conflict['remote'] as Json?)),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton(
                                    onPressed: () =>
                                        _resolve(context, conflict, false),
                                    child: const Text('Keep Saved Version'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        _resolve(context, conflict, true),
                                    child: const Text('Use My Changes'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.settings_backup_restore),
                    title: const Text('Advanced Backup & Restore'),
                    subtitle: const Text(
                      'Export a file or access your existing Google Drive backup',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BackupRestorePage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  String _describe(Json? value) {
    if (value == null) return 'Date Removed';
    final session = ShoppingSession.fromJson(value);
    if (session.items.isEmpty) {
      return 'No Items • ${session.lists.map((l) => l.name).join(', ')}';
    }
    return 'Lists: ${session.lists.map((l) => l.name).join(', ')}\n${session.items.map((item) => '${item.name} • ${item.quantityValue ?? item.quantity ?? ''} ${item.unitLabel}'
        ' • ${item.isPurchased ? 'Purchased' : 'Pending'}'
        ' • ${item.pricing.totalPrice}'
        '${item.notes?.isNotEmpty == true ? ' • ${item.notes}' : ''}').join('\n')}';
  }

  Future<void> _resolve(
    BuildContext context,
    Json conflict,
    bool useLocal,
  ) async {
    try {
      await service.store!.resolve(
        conflict['id'] as String,
        useLocal: useLocal,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save your choice. Please try again.'),
          ),
        );
      }
    }
  }
}
