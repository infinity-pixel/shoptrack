import 'package:flutter/material.dart';

class ItemSelectionBar extends StatelessWidget {
  const ItemSelectionBar({
    super.key,
    required this.count,
    required this.allSelected,
    required this.busy,
    required this.onClose,
    required this.onSelectAll,
    required this.onMove,
    required this.onDelete,
  });
  final int count;
  final bool allSelected, busy;
  final VoidCallback onClose, onSelectAll, onMove, onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: colors.primary.withValues(alpha: .08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 2,
            children: [
              IconButton(
                tooltip: 'Cancel Selection',
                onPressed: busy ? null : onClose,
                icon: const Icon(Icons.close),
              ),
              Semantics(
                liveRegion: true,
                child: Text(
                  '$count Selected',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              IconButton(
                tooltip: allSelected ? 'Deselect All' : 'Select All',
                onPressed: busy ? null : onSelectAll,
                icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
              ),
              TextButton.icon(
                onPressed: busy || count == 0 ? null : onMove,
                icon: const Icon(Icons.drive_file_move_outline, size: 20),
                label: const Text('Move'),
              ),
              TextButton.icon(
                onPressed: busy || count == 0 ? null : onDelete,
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text('Delete'),
              ),
              if (busy)
                const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
