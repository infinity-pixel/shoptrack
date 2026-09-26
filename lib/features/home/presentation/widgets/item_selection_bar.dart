import 'package:flutter/material.dart';
import 'package:shoptrack/core/localization/shoptrack_text.dart';

class ItemSelectionBar extends StatelessWidget {
  const ItemSelectionBar({
    super.key,
    required this.count,
    required this.allSelected,
    required this.busy,
    required this.onClose,
    required this.onSelectAll,
    required this.onShare,
    required this.onMove,
    required this.onDelete,
  });
  final int count;
  final bool allSelected, busy;
  final VoidCallback onClose, onSelectAll, onShare, onMove, onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final width = (MediaQuery.sizeOf(context).width - 24).clamp(0.0, 480.0);
    final compact =
        width < 440 || MediaQuery.textScalerOf(context).scale(1) > 1.2;
    return SizedBox(
      width: width,
      child: Material(
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: .32),
        color: colors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              IconButton(
                tooltip: shopTr(context, 'Cancel Selection'),
                onPressed: busy ? null : onClose,
                icon: const Icon(Icons.close),
              ),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    '${shopNumber(context, count)} ${shopTr(context, 'Selected')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  tooltip: shopTr(
                    context,
                    allSelected ? 'Deselect All' : 'Select All',
                  ),
                  onPressed: onSelectAll,
                  icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
                ),
              if (compact) ...[
                IconButton(
                  tooltip: shopTr(context, 'Copy or Share Selected Items'),
                  onPressed: busy || count == 0 ? null : onShare,
                  icon: const Icon(Icons.ios_share_outlined, size: 21),
                ),
                IconButton(
                  tooltip: shopTr(context, 'Move'),
                  onPressed: busy || count == 0 ? null : onMove,
                  icon: const Icon(Icons.drive_file_move_outline, size: 21),
                ),
                IconButton(
                  tooltip: shopTr(context, 'Delete'),
                  color: colors.error,
                  onPressed: busy || count == 0 ? null : onDelete,
                  icon: const Icon(Icons.delete_outline, size: 21),
                ),
              ] else ...[
                Tooltip(
                  message: shopTr(context, 'Copy or Share Selected Items'),
                  child: TextButton.icon(
                    onPressed: busy || count == 0 ? null : onShare,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.ios_share_outlined, size: 19),
                    label: const ShopText('Share'),
                  ),
                ),
                Tooltip(
                  message: shopTr(context, 'Move'),
                  child: TextButton.icon(
                    onPressed: busy || count == 0 ? null : onMove,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.drive_file_move_outline, size: 19),
                    label: const ShopText('Move'),
                  ),
                ),
                Tooltip(
                  message: shopTr(context, 'Delete'),
                  child: TextButton.icon(
                    onPressed: busy || count == 0 ? null : onDelete,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.error,
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        6,
                        0,
                        10,
                        0,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.delete_outline, size: 19),
                    label: const ShopText('Delete'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
