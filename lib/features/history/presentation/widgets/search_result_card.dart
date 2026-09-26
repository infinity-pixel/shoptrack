import 'package:flutter/material.dart';
import '../../../../core/localization/shoptrack_text.dart';
import '../../../../core/theme/theme_presets.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/widgets/compact_amount_text.dart';
import '../../../../models/shopping_search_result.dart';
import 'history_date_badge.dart';

class SearchResultCard extends StatelessWidget {
  const SearchResultCard({
    super.key,
    required this.result,
    required this.onTap,
  });
  final ShoppingSearchResult result;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final p = ShopTrackThemeTokens.of(context).palette;
    final color = switch (result.status) {
      SearchItemStatus.purchased => p.purchasedStatus,
      SearchItemStatus.pending => p.pending,
      SearchItemStatus.planned => p.planned,
    };
    final item = result.item;
    final quantity =
        item.quantity ??
        (item.quantityValue == null
            ? ''
            : NumberFormatter.format(item.quantityValue!));
    final unit = item.shoppingUnit?.symbol ?? item.unit ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              HistoryDateBadge(
                date: result.session.date,
                isFuture: result.session.isFuture,
              ),
              Container(
                width: 1,
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: 9),
                color: p.border,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: p.onBackground,
                      ),
                    ),
                    if ('$quantity $unit'.trim().isNotEmpty)
                      Text(
                        '${shopDigitsLanguage(Localizations.localeOf(context).languageCode, quantity)} ${shopTr(context, unit)}'
                            .trim(),
                        style: TextStyle(color: p.textSecondary),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '● ${shopTr(context, result.statusLabel)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  heightFactor: 1,
                  child:
                      result.status == SearchItemStatus.purchased &&
                          item.priceValue != null
                      ? CompactAmountText(
                          value: item.pricing.totalPrice,
                          currencyCode: item.currencyCode,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: result.status == SearchItemStatus.purchased
                                ? p.purchased
                                : p.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : Text('—', style: TextStyle(color: p.textSecondary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
