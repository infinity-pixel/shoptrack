import 'package:flutter/material.dart';
import 'package:shoptrack/core/localization/shoptrack_text.dart';
import 'package:shoptrack/core/calendar/shop_calendar.dart';
import '../../../../core/data/session_merge.dart';
import '../../../../core/theme/theme_presets.dart';
import '../../../../core/utils/number_formatter.dart';
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
        appBar: AppBar(title: const ShopText('Cloud Sync')),
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
                      padding: const EdgeInsets.all(16),
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
                          ShopText(
                            service.statusLabel,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          ShopText(
                            service.explanation,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: p.textSecondary, height: 1.4),
                          ),
                          if (service.lastSaved != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${shopTr(context, 'Last uploaded from this device')}: ${shopDate(context, service.lastSaved!, 'd MMM yyyy, HH:mm')}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: p.textSecondary),
                            ),
                          ],
                          if (service.status == ShoppingSyncState.saving) ...[
                            const SizedBox(height: 16),
                            const LinearProgressIndicator(),
                          ],
                          if (service.status == ShoppingSyncState.attention ||
                              service.status == ShoppingSyncState.deviceOnly)
                            TextButton.icon(
                              onPressed: service.retry,
                              icon: const Icon(Icons.refresh),
                              label: const ShopText('Retry Sync'),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _info(
                            context,
                            Icons.checklist_outlined,
                            'Shopping data in your account',
                            'Lists, items, prices and purchase history sync to your signed-in account while the app is open and online.',
                          ),
                          const SizedBox(height: 16),
                          _info(
                            context,
                            Icons.phone_android_outlined,
                            'Settings kept on this device',
                            'Appearance and your ShopTrack profile stay on this device; automatic sync does not copy them to other devices.',
                          ),
                          const SizedBox(height: 16),
                          _info(
                            context,
                            Icons.devices_outlined,
                            'Continue on another device',
                            'Open ShopTrack and sign in to the same account to load your synced shopping data.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (conflicts.isNotEmpty) ...[
                    ShopText(
                      'Review Changes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const ShopText(
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
                                shopDate(
                                  context,
                                  DateTime.parse(conflict['day'] as String),
                                  'd MMMM yyyy',
                                ),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text((conflict['fields'] as List).join(', ')),
                              if (conflict['batchId'] != null)
                                const ShopText(
                                  'This is part of an item transfer. Your choice applies to both related dates below.',
                                ),
                              const SizedBox(height: 12),
                              ShopText(
                                'This Device',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: p.primary,
                                ),
                              ),
                              Text(
                                _describe(context, conflict['value'] as Json?),
                              ),
                              const SizedBox(height: 12),
                              ShopText(
                                'Saved Version',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: p.primary,
                                ),
                              ),
                              Text(
                                _describe(context, conflict['remote'] as Json?),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton(
                                    onPressed: () =>
                                        _resolve(context, conflict, false),
                                    child: const ShopText('Keep Saved Version'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        _resolve(context, conflict, true),
                                    child: const ShopText('Use My Changes'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: const Icon(Icons.settings_backup_restore),
                      title: const ShopText('Advanced Backup & Restore'),
                      subtitle: const ShopText('File and Google Drive backups'),
                      trailing: Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.chevron_left
                            : Icons.chevron_right,
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BackupRestorePage(),
                        ),
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

  Widget _info(
    BuildContext context,
    IconData icon,
    String title,
    String detail,
  ) {
    final p = ShopTrackThemeTokens.of(context).palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: p.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShopText(
                title,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              ShopText(
                detail,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: p.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _describe(BuildContext context, Json? value) {
    if (value == null) return shopTr(context, 'Date Removed');
    final session = ShoppingSession.fromJson(value);
    final names = session.lists
        .map((list) => shopListName(context, id: list.id, name: list.name))
        .join(', ');
    if (session.items.isEmpty) {
      return '${shopTr(context, 'No Items')} • $names';
    }
    return '${shopTr(context, 'Lists')}: $names\n${session.items.map((item) => '${item.name} • ${shopDigits(context, '${item.quantityValue ?? item.quantity ?? ''}')} ${shopTr(context, item.unitLabel)}'
        ' • ${shopTr(context, item.isPurchased ? 'Purchased' : 'Pending')}'
        ' • ${shopDigits(context, NumberFormatter.formatPrice(item.pricing.totalPrice, currencyCode: item.currencyCode, includeCode: true))}'
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
            content: ShopText('Could not save your choice. Please try again.'),
          ),
        );
      }
    }
  }
}
