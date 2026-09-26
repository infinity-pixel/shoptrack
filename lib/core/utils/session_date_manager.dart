import 'package:flutter/material.dart';
import '../calendar/shop_calendar.dart';
import '../calendar/calendar_date_dialog.dart';
import 'package:uuid/uuid.dart';
import '../data/shopping_repository.dart';
import '../../models/shopping_session.dart';
import '../../models/shopping_item.dart';
import '../localization/shoptrack_text.dart';

class SessionDateManager {
  static Future<void> editSessionDate({
    required BuildContext context,
    required ShoppingSession session,
    required ShoppingRepository repository,
    required VoidCallback onUpdated,
  }) async {
    final newDate = await showPreferredDatePicker(
      context: context,
      initialDate: session.date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: shopTr(context, 'Edit Shopping Date'),
    );

    if (newDate == null || !context.mounted) return;

    // Check if the date is actually different
    if (newDate.year == session.date.year &&
        newDate.month == session.date.month &&
        newDate.day == session.date.day) {
      return;
    }

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(newDate.year, newDate.month, newDate.day);
    final isMovingToFuture = targetDate.isAfter(todayDate);
    final isSourceToday =
        session.date.year == todayDate.year &&
        session.date.month == todayDate.month &&
        session.date.day == todayDate.day;

    // 1. Target Collision Check
    final existingAtTarget = await repository.getSessionByDate(targetDate);
    if (existingAtTarget.items.isNotEmpty) {
      if (!context.mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const ShopText('Date Already Exists'),
          content: Text(
            shopTr(
              context,
              'A shopping session already exists for {date}. Delete that session first to move this record there.',
            ).replaceAll(
              '{date}',
              shopDate(context, targetDate, 'd MMMM yyyy'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const ShopText('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final purchasedItems = session.items.where((i) => i.isPurchased).toList();
    final pendingItems = session.items.where((i) => !i.isPurchased).toList();

    if (isMovingToFuture && purchasedItems.isNotEmpty) {
      // MIXED or ALL-PURCHASED session moving to future
      if (!context.mounted) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const ShopText('Purchased items detected'),
          content: Text(
            shopTr(
              context,
              '{count} purchased items will be moved to Today’s list. Remaining items will be planned for the new date.',
            ).replaceAll('{count}', shopNumber(context, purchasedItems.length)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const ShopText('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const ShopText('Continue'),
            ),
          ],
        ),
      );

      if (confirm != true || !context.mounted) return;

      if (isSourceToday) {
        // Today -> Future
        if (pendingItems.isNotEmpty) {
          // Create new Future session for pending items
          final futureSession = ShoppingSession(
            id: const Uuid().v4(),
            date: targetDate,
            items: pendingItems,
            lists: session.lists,
          );
          await repository.saveSession(futureSession);

          // Update current Today session to keep ONLY purchased items
          await repository.saveSession(session.copyWith(items: purchasedItems));
        } else {
          // All items are purchased. Moving to future results in everything staying in Today.
          // In this case, we don't create a future session, and the user is informed.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: ShopText(
                'Purchased items stay in Today. No future session created.',
              ),
            ),
          );
          return;
        }
      } else {
        // Past -> Future
        // Move purchased to Today (Merge)
        final todaySession = await repository.getSessionByDate(todayDate);
        final mergedItems = List<ShoppingItem>.from(todaySession.items);
        final mergedLists = [...todaySession.orderedLists];
        for (final list in session.orderedLists) {
          if (!mergedLists.any((candidate) => candidate.id == list.id)) {
            mergedLists.add(list.copyWith(position: mergedLists.length));
          }
        }
        for (var item in purchasedItems) {
          if (!mergedItems.any((it) => it.id == item.id)) {
            mergedItems.add(item.copyWith(position: mergedItems.length));
          }
        }
        await repository.saveSession(
          todaySession.copyWith(items: mergedItems, lists: mergedLists),
        );

        // Handle Future part
        if (pendingItems.isNotEmpty) {
          final futureSession = ShoppingSession(
            id: const Uuid().v4(),
            date: targetDate,
            items: pendingItems,
            lists: session.lists,
          );
          await repository.saveSession(futureSession);
        }

        // Delete old Past session
        await repository.deleteSession(session.id);
      }

      onUpdated();

      if (context.mounted) {
        final msg = pendingItems.isNotEmpty
            ? shopTr(
                context,
                'Items moved to Today and {date}',
              ).replaceAll('{date}', shopDate(context, targetDate, 'd MMMM'))
            : shopTr(context, 'All items moved to Today');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } else {
      // STANDARD MOVE (Past/Today target, or Future target with NO purchased items)
      if (!context.mounted) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const ShopText('Change Shopping Date?'),
          content: Text(
            shopTr(context, 'Move this session from {from} to {to}?')
                .replaceAll('{from}', shopDate(context, session.date, 'd MMMM'))
                .replaceAll(
                  '{to}',
                  shopDate(context, targetDate, 'd MMMM yyyy'),
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const ShopText('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const ShopText('Move Date'),
            ),
          ],
        ),
      );

      if (confirm == true && context.mounted) {
        final updatedSession = session.copyWith(date: targetDate);

        // We delete first to avoid any ID vs Date confusion in repository.saveSession
        await repository.deleteSession(session.id);
        await repository.saveSession(updatedSession);

        onUpdated();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                shopTr(
                  context,
                  'Moved to {date}',
                ).replaceAll('{date}', shopDate(context, targetDate, 'd MMMM')),
              ),
            ),
          );
        }
      }
    }
  }
}
