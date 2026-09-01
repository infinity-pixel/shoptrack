import 'package:flutter/material.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../models/shopping_item.dart';

class ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final int index;

  const ShoppingItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isPurchased = item.isPurchased;
    final pricing = item.pricing;

    // Use resolved values from the pricing engine for display
    final displayQty = pricing.resolvedQuantity;
    final displayUnit = pricing.resolvedUnitSymbol;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24.0),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          color: isPurchased ? Colors.blue.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPurchased ? Colors.blue.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Drag Handle
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.drag_indicator,
                      color: Colors.grey[300],
                      size: 20,
                    ),
                  ),
                ),

                // Checkbox
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isPurchased ? Colors.blue : Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isPurchased ? Colors.blue : Colors.transparent,
                    ),
                    child: isPurchased
                        ? const Icon(
                            Icons.check,
                            size: 18,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),

                // Item Info: Name + Qty
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isPurchased ? Colors.grey[400] : Colors.black87,
                          decoration: isPurchased ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (displayQty != null || displayUnit != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '${NumberFormatter.format(displayQty ?? 0)} ${displayUnit ?? ''}'.trim(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 12), // Breathing room between qty and price

                // RIGHT: Price Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pricing.totalPrice > 0)
                      Text(
                        NumberFormatter.formatPrice(pricing.totalPrice),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isPurchased
                              ? Colors.blue.withValues(alpha: 0.4)
                              : Colors.blue[700],
                        ),
                      ),
                    if (pricing.unitPrice > 0)
                      Text(
                        '${NumberFormatter.formatPrice(pricing.unitPrice)}/${pricing.priceBasisSymbol}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isPurchased ? Colors.grey[300] : Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
