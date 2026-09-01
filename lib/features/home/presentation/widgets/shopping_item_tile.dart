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
        padding: const EdgeInsets.only(right: 20.0),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isPurchased ? Colors.grey[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Drag Handle
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(
                      Icons.drag_indicator,
                      color: isPurchased ? Colors.grey[300] : Colors.grey[400],
                      size: 20,
                    ),
                  ),
                ),

                // Checkbox
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isPurchased ? Colors.blue : Colors.grey[400]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      color: isPurchased ? Colors.blue : Colors.transparent,
                    ),
                    child: isPurchased
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),

                // LEFT: Item Name (Flexible)
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isPurchased ? Colors.grey[500] : Colors.black87,
                    ),
                  ),
                ),

                // MIDDLE: Quantity + Unit
                if (displayQty != null || displayUnit != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      '${NumberFormatter.format(displayQty ?? 0)} ${displayUnit ?? ''}'
                          .trim(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isPurchased ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ),

                // RIGHT: Price Area (Protected)
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (pricing.totalPrice > 0)
                        Text(
                          NumberFormatter.formatPrice(pricing.totalPrice),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isPurchased
                                ? Colors.blue.withValues(alpha: 0.5)
                                : Colors.blue,
                          ),
                        ),
                      if (pricing.unitPrice > 0)
                        Text(
                          '${NumberFormatter.formatPrice(pricing.unitPrice)}/${pricing.priceBasisSymbol}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isPurchased ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                    ],
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
