import 'package:flutter/material.dart';
import '../../../../core/theme/theme_presets.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/widgets/compact_amount_text.dart';
import '../../../../models/app_settings.dart';
import '../../../../models/shopping_item.dart';

class ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final int index;
  final bool? visualPurchased;
  final VoidCallback? onLongPress;
  final bool selectionMode;
  final bool selected;
  final NumberFormatPreference numberFormat;

  const ShoppingItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
    required this.index,
    this.visualPurchased,
    this.onLongPress,
    this.selectionMode = false,
    this.selected = false,
    this.numberFormat = NumberFormatPreference.automatic,
  });

  @override
  Widget build(BuildContext context) {
    final isPurchased = visualPurchased ?? item.isPurchased;
    final pricing = item.pricing;
    final palette = ShopTrackThemeTokens.of(context).palette;
    final checked = selectionMode ? selected : isPurchased;
    final checkColor = selectionMode ? palette.primary : palette.purchased;

    // Use resolved values from the pricing engine for display
    final displayQty = pricing.resolvedQuantity;
    final displayUnit = pricing.resolvedUnitSymbol;
    final rawNote = item.notes?.trim();
    final displayNote = rawNote == null || rawNote.isEmpty
        ? null
        : rawNote.replaceAll(RegExp(r'\s+'), ' ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Dismissible(
          key: ValueKey(item.id),
          direction: selectionMode
              ? DismissDirection.none
              : DismissDirection.endToStart,
          onDismissed: (_) => onDelete(),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          child: Container(
            key: ValueKey('shopping-item-tile-${item.id}'),
            decoration: BoxDecoration(
              color: selected
                  ? Color.alphaBlend(
                      palette.primary.withValues(alpha: .12),
                      isPurchased
                          ? palette.surfacePurchased
                          : palette.surfaceToBuy,
                    )
                  : isPurchased
                  ? palette.surfacePurchased
                  : palette.surfaceToBuy,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? palette.primary : palette.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  2,
                  4,
                  14,
                  displayNote == null ? 4 : 9,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Drag Handle
                    SizedBox(
                      width: 30,
                      child: selectionMode
                          ? null
                          : ReorderableDragStartListener(
                              index: index,
                              // Hit-test the whole padded handle, not just the icon glyph.
                              child: ColoredBox(
                                color: Colors.transparent,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Icon(
                                    Icons.drag_indicator,
                                    color: palette.textSecondary.withValues(
                                      alpha: 0.55,
                                    ),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                    ),

                    // Checkbox
                    Semantics(
                      label: selectionMode
                          ? 'Select ${item.name}'
                          : 'Mark ${item.name} Purchased',
                      checked: checked,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onToggle,
                        child: SizedBox(
                          width: 40,
                          height: 48,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 280),
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: checked
                                        ? checkColor
                                        : Theme.of(context).brightness ==
                                              Brightness.dark
                                        ? palette.textSecondary
                                        : palette.border,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    selectionMode ? 20 : 8,
                                  ),
                                  color: checked
                                      ? checkColor
                                      : Colors.transparent,
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 240),
                                  transitionBuilder: (child, animation) {
                                    return ScaleTransition(
                                      scale: animation,
                                      child: FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: checked
                                      ? Icon(
                                          Icons.check,
                                          key: const ValueKey('checked'),
                                          size: 18,
                                          color: selectionMode
                                              ? palette.onPrimary
                                              : palette.onStatus,
                                        )
                                      : const SizedBox(
                                          key: ValueKey('unchecked'),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),

                    // Item Info: Name + Qty
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isPurchased
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                              color: isPurchased
                                  ? palette.textSecondary
                                  : palette.onSurface,
                              decoration: isPurchased
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          if (displayQty != null || displayUnit != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 0),
                              child: Text(
                                '${NumberFormatter.formatQuantity(displayQty ?? 0, enteredText: item.quantity)} ${displayUnit ?? ''}'
                                    .trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: palette.textSecondary,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          if (displayNote != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                displayNote,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: palette.textSecondary.withValues(
                                    alpha: .88,
                                  ),
                                  height: 1.15,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ), // Breathing room between qty and price
                    // RIGHT: Price Column
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (pricing.totalPrice > 0)
                            CompactAmountText(
                              value: pricing.totalPrice,
                              currencyCode: item.currencyCode,
                              preference: numberFormat,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isPurchased
                                    ? palette.purchased
                                    : palette.secondary,
                              ),
                            ),
                          if (pricing.unitPrice > 0)
                            CompactAmountText(
                              value: pricing.unitPrice,
                              currencyCode: item.currencyCode,
                              preference: numberFormat,
                              suffix: '/${pricing.priceBasisSymbol}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: palette.textSecondary,
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
        ),
      ),
    );
  }
}
