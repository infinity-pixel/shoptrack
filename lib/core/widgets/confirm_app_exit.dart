import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../localization/shoptrack_text.dart';

/// Ask at the root only. Never pop the last Flutter route into an empty surface.
Future<void> confirmAppExit(BuildContext context) async {
  if (ModalRoute.of(context)?.isCurrent != true) return;
  if (MediaQuery.viewInsetsOf(context).bottom > 0) {
    FocusManager.instance.primaryFocus?.unfocus();
    return;
  }
  final close = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const ShopText('Close ShopTrack?'),
      content: const ShopText('Do you want to close the app?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const ShopText('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const ShopText('Close'),
        ),
      ],
    ),
  );
  if (close == true && context.mounted) await SystemNavigator.pop();
}
