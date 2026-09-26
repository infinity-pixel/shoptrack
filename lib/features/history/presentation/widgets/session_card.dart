import 'package:flutter/material.dart';
import 'package:shoptrack/core/localization/shoptrack_text.dart';
import 'package:shoptrack/core/calendar/shop_calendar.dart';

import '../../../../core/currency/currency_catalog.dart';
import '../../../../core/theme/theme_presets.dart';
import '../../../../core/widgets/compact_amount_text.dart';
import '../../../../models/app_settings.dart';
import '../../../../models/shopping_session.dart';
import 'history_date_badge.dart';

class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.session,
    required this.onTap,
    this.onDelete,
    this.onEdit,
    this.onShare,
    this.glowAnimation,
    this.numberFormat = NumberFormatPreference.automatic,
  });

  final ShoppingSession session;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final Animation<double>? glowAnimation;
  final NumberFormatPreference numberFormat;

  @override
  Widget build(BuildContext context) {
    final palette = ShopTrackThemeTokens.of(context).palette;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final animation = reduceMotion
        ? const AlwaysStoppedAnimation(0.35)
        : glowAnimation ?? const AlwaysStoppedAnimation(0.35);

    return LayoutBuilder(
      builder: (context, _) {
        final purchasedTotals = session.purchasedTotalsByCurrency;
        final totals = purchasedTotals.ordered();
        final amount = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ShopText(
              'Total Purchased',
              style: TextStyle(color: palette.textSecondary, fontSize: 10),
            ),
            const SizedBox(height: 2),
            if (totals.isEmpty)
              _HistoryAmount(
                currencyCode: CurrencyCatalog.defaultCode,
                value: 0,
                color: palette.purchased,
                numberFormat: numberFormat,
              )
            else
              for (final total in totals)
                _HistoryAmount(
                  currencyCode: total.currencyCode,
                  value: total.value,
                  color: palette.purchased,
                  numberFormat: numberFormat,
                ),
          ],
        );
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: palette.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 8, 12),
              child: Row(
                children: [
                  HistoryDateBadge(
                    date: session.date,
                    isFuture: session.isFuture,
                  ),
                  Container(
                    width: 1,
                    height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 9),
                    color: palette.border,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shopDate(
                            context,
                            session.date,
                            session.isToday || session.isFuture
                                ? 'EEEE, MMMM'
                                : 'EEEE',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.onBackground,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 10,
                          runSpacing: 2,
                          children: _buildStatuses(context, animation),
                        ),
                        if (!session.isFuture) ...[
                          const SizedBox(height: 6),
                          amount,
                        ],
                      ],
                    ),
                  ),
                  _buildMenu(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildStatuses(
    BuildContext context,
    Animation<double> animation,
  ) {
    final palette = ShopTrackThemeTokens.of(context).palette;
    if (session.isFuture) {
      return [
        _GlowingStatus(
          animation: animation,
          color: palette.planned,
          text:
              '${shopNumber(context, session.plannedCount)} ${shopTr(context, 'Planned')} ${shopTr(context, session.plannedCount == 1 ? 'Item' : 'Items')}',
        ),
      ];
    }
    return [
      if (session.purchasedCount > 0)
        _GlowingStatus(
          animation: animation,
          color: palette.purchasedStatus,
          text:
              '${shopNumber(context, session.purchasedCount)} ${shopTr(context, 'Purchased')}',
        ),
      if (session.pendingCount > 0)
        _GlowingStatus(
          animation: animation,
          color: palette.pending,
          text:
              '${shopNumber(context, session.pendingCount)} ${shopTr(context, 'Pending')}',
        ),
    ];
  }

  Widget _buildMenu(BuildContext context) {
    if (onDelete == null && onEdit == null && onShare == null) {
      return const Icon(Icons.chevron_right, size: 20);
    }
    final tokens = ShopTrackThemeTokens.of(context);
    final palette = tokens.palette;
    final calendarAccent = tokens.calendarAccent ?? palette.onSurface;
    return PopupMenuButton<String>(
      tooltip: shopTr(context, 'Date options'),
      onSelected: (value) {
        if (value == 'share') onShare?.call();
        if (value == 'edit') onEdit?.call();
        if (value == 'delete') onDelete?.call();
      },
      itemBuilder: (context) => [
        if (onShare != null)
          PopupMenuItem(
            value: 'share',
            child: Row(
              children: [
                Icon(Icons.ios_share_outlined, color: palette.secondary),
                const SizedBox(width: 8),
                const ShopText('Copy or Share'),
              ],
            ),
          ),
        if (onEdit != null)
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_calendar_outlined, color: calendarAccent),
                const SizedBox(width: 8),
                const ShopText('Edit Date'),
              ],
            ),
          ),
        if (onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: palette.pending),
                const SizedBox(width: 8),
                ShopText('Delete', style: TextStyle(color: palette.pending)),
              ],
            ),
          ),
      ],
      icon: Icon(Icons.more_vert, size: 20, color: palette.textSecondary),
    );
  }
}

class _HistoryAmount extends StatelessWidget {
  const _HistoryAmount({
    required this.currencyCode,
    required this.value,
    required this.color,
    required this.numberFormat,
  });

  final String currencyCode;
  final double value;
  final Color color;
  final NumberFormatPreference numberFormat;

  @override
  Widget build(BuildContext context) {
    final isArabic = RegExp(
      r'[\u0600-\u06ff]',
    ).hasMatch(CurrencyCatalog.resolve(currencyCode).symbol);
    return Row(
      key: ValueKey('history_currency_$currencyCode'),
      children: [
        Text(
          currencyCode,
          key: ValueKey('history_currency_code_$currencyCode'),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CompactAmountText(
            value: value,
            currencyCode: currencyCode,
            preference: numberFormat,
            textAlign: isArabic && !shopIsArabic(context)
                ? TextAlign.end
                : TextAlign.start,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowingStatus extends StatelessWidget {
  const _GlowingStatus({
    required this.animation,
    required this.color,
    required this.text,
  });

  final Animation<double> animation;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final strength = 0.12 + (animation.value * 0.20);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: strength),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        color: color.withValues(alpha: strength),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
