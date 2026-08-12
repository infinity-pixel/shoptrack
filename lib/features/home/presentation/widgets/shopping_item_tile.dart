import 'package:flutter/material.dart';
import '../../../../models/shopping_item.dart';

class ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;
  final VoidCallback onToggle;

  const ShoppingItemTile({
    super.key,
    required this.item,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isPurchased = item.isPurchased;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
          const SizedBox(width: 16),

          // Item Info (Name + Quantity/Unit)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    decoration: isPurchased ? TextDecoration.lineThrough : null,
                    color: isPurchased ? Colors.grey[500] : Colors.black87,
                  ),
                ),
                if (item.quantity != null || item.unit != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${item.quantity ?? ''} ${item.unit ?? ''}'.trim(),
                    style: TextStyle(
                      fontSize: 13,
                      color: isPurchased ? Colors.grey[400] : Colors.grey[600],
                      decoration: isPurchased ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Price (Prominently displayed on the RIGHT)
          if (item.price != null && item.price!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Text(
                '৳${item.price}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isPurchased ? Colors.blue.withValues(alpha: 0.5) : Colors.blue,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
