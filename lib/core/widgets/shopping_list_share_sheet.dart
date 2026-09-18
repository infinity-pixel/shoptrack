import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/shopping_session.dart';
import '../utils/shopping_list_text_formatter.dart';
import 'shoptrack_modal.dart';

Future<void> showShoppingListShareSheet(
  BuildContext context,
  ShoppingSession session,
) async {
  if (session.items.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add an item before sharing this list.')),
    );
    return;
  }

  final action = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * .85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShopTrackSheetHeader(
                title: 'Share Shopping List',
                subtitle: DateFormat('EEEE, d MMMM yyyy').format(session.date),
                onClose: () => Navigator.pop(sheetContext),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.copy_outlined),
                title: const Text('Copy as Text'),
                subtitle: const Text('Paste it into any conversation'),
                onTap: () => Navigator.pop(sheetContext, 'copy'),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.ios_share_outlined),
                title: const Text('Share'),
                subtitle: const Text('Choose an app on this device'),
                onTap: () => Navigator.pop(sheetContext, 'share'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (!context.mounted || action == null) return;

  final text = ShoppingListTextFormatter.format(session);
  try {
    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Shopping list copied.')));
      }
    } else if (action == 'share') {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject:
              'ShopTrack — ${DateFormat('d MMMM yyyy').format(session.date)}',
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not share this list. Please try again.'),
        ),
      );
    }
  }
}
