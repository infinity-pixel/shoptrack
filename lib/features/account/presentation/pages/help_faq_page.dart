import 'package:flutter/material.dart';

import '../../../../core/localization/shoptrack_text.dart';
import '../../../../core/widgets/shoptrack_motion.dart';

class HelpFaqPage extends StatelessWidget {
  const HelpFaqPage({super.key});

  static const _topics = [
    (
      'Create dates and lists',
      Icons.event_note_outlined,
      [
        'Use New Date in History to plan a shopping day.',
        'On Lists, use the add-list control to create a separate named list.',
      ],
    ),
    (
      'Add and price an item',
      Icons.add_shopping_cart_outlined,
      [
        'Open a shopping date and tap Add Item.',
        'Enter a name and quantity. Use More Options for currency and total or per-unit price.',
        'Tap Save. Different currencies stay separate; ShopTrack does not convert them.',
      ],
    ),
    (
      'Mark purchased and reorder',
      Icons.check_circle_outline,
      [
        'Tap the checkbox on an item to mark it purchased.',
        'Drag its handle to reorder it within the same currency section.',
      ],
    ),
    (
      'Find and share a list',
      Icons.share_outlined,
      [
        'Use History to open shopping dates or search by status, no price, or date range.',
        'On Lists, open the Add Item arrow and choose Share Your List.',
      ],
    ),
    (
      'Move, delete, and undo',
      Icons.drive_file_move_outline,
      [
        'Long-press an item to select it for moving or deleting.',
        'Swipe an item to delete it. Tap Undo promptly if that was a mistake.',
      ],
    ),
    (
      'Personalize ShopTrack',
      Icons.tune_outlined,
      [
        'In Profile, choose your appearance, language, default currency, and number format.',
        'Choose Gregorian or Hijri calendar labels; your saved shopping dates remain unchanged.',
      ],
    ),
    (
      'Offline and cloud sync',
      Icons.cloud_outlined,
      [
        'Your shopping records remain available on this device while offline.',
        'If signed in, pending changes sync when the connection returns. Check Cloud Sync for their status.',
      ],
    ),
    (
      'Backup and restore',
      Icons.backup_outlined,
      [
        'In Profile, open Cloud Sync, then Advanced Backup & Restore.',
        'Export a file or Drive backup before restoring. Restore can replace current data.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const ShopText('Help & FAQ')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ShopText(
                    'A quick guide to everyday shopping in ShopTrack.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                for (final (title, icon, steps) in _topics)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      color: colors.surface,
                      child: ExpansionTile(
                        key: PageStorageKey(title),
                        shape: const RoundedRectangleBorder(
                          side: BorderSide.none,
                        ),
                        collapsedShape: const RoundedRectangleBorder(
                          side: BorderSide.none,
                        ),
                        expansionAnimationStyle: ShopTrackMotion.dialogStyle(
                          context,
                        ),
                        leading: Icon(icon, color: colors.primary),
                        title: ShopText(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          18,
                          0,
                          18,
                          18,
                        ),
                        children: [
                          for (var i = 0; i < steps.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 30,
                                    child: Text(
                                      '${shopNumber(context, i + 1)}.',
                                      style: TextStyle(
                                        color: colors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: ShopText(steps[i])),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
