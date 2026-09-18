import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';

Future<void> confirmSignOut(BuildContext context, AuthService auth) async {
  bool busy = false;
  String? error;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, update) => PopScope(
        canPop: !busy,
        child: AlertDialog(
          title: const Text('Sign Out?'),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your lists stay accessible on this device. Cloud sync pauses until you sign back into the same account.\n\nCloud data and backups are kept. Other accounts have separate history.',
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      update(() {
                        busy = true;
                        error = null;
                      });
                      try {
                        await auth.signOut();
                        if (!context.mounted) return;
                        update(() => busy = false);
                        await WidgetsBinding.instance.endOfFrame;
                        if (context.mounted) Navigator.pop(context);
                      } catch (_) {
                        if (context.mounted) {
                          update(() {
                            busy = false;
                            error = 'Could not sign out. Please try again.';
                          });
                        }
                      }
                    },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    ),
  );
}
