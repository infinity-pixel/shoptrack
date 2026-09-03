import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/animation/rolling_digit.dart';
import '../../../../core/theme/theme_presets.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../models/shopping_session.dart';

class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.session,
    required this.onTap,
    this.onDelete,
    this.onEdit,
    this.glowAnimation,
  });

  final ShoppingSession session;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final Animation<double>? glowAnimation;

  @override
  Widget build(BuildContext context) {
    final palette = ShopTrackThemeTokens.of(context).palette;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final animation = reduceMotion
        ? const AlwaysStoppedAnimation(0.35)
        : glowAnimation ?? const AlwaysStoppedAnimation(0.35);

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
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              SizedBox(
                width: 42,
                child: Text(
                  DateFormat('d').format(session.date),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: session.isFuture
                        ? palette.planned
                        : palette.onBackground,
                    fontSize: 30,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 52,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: palette.border,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEE, MMM').format(session.date),
                      style: TextStyle(
                        color: palette.onBackground,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: _buildStatuses(context, animation),
                    ),
                  ],
                ),
              ),
              if (!session.isFuture)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Purchased',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      RollingDigitText(
                        text: NumberFormatter.formatPrice(
                          session.totalPurchasedAmount,
                        ),
                        style: TextStyle(
                          color: palette.purchased,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              _buildMenu(context),
            ],
          ),
        ),
      ),
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
              '${session.plannedCount} planned ${session.plannedCount == 1 ? 'item' : 'items'}',
        ),
      ];
    }
    return [
      if (session.purchasedCount > 0)
        _GlowingStatus(
          animation: animation,
          color: palette.purchased,
          text: '${session.purchasedCount} purchased',
        ),
      if (session.pendingCount > 0)
        _GlowingStatus(
          animation: animation,
          color: palette.pending,
          text: '${session.pendingCount} pending',
        ),
    ];
  }

  Widget _buildMenu(BuildContext context) {
    if (onDelete == null && onEdit == null) {
      return const Icon(Icons.chevron_right, size: 20);
    }
    final palette = ShopTrackThemeTokens.of(context).palette;
    return PopupMenuButton<String>(
      tooltip: 'Date options',
      onSelected: (value) {
        if (value == 'edit') onEdit?.call();
        if (value == 'delete') onDelete?.call();
      },
      itemBuilder: (context) => [
        if (onEdit != null)
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_calendar_outlined),
                SizedBox(width: 8),
                Text('Edit Date'),
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
                Text('Delete', style: TextStyle(color: palette.pending)),
              ],
            ),
          ),
      ],
      icon: Icon(Icons.more_vert, size: 20, color: palette.textSecondary),
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
    return AnimatedBuilder(
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
                    blurRadius: 4 + (animation.value * 4),
                    spreadRadius: animation.value,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(
                    color: color.withValues(alpha: strength),
                    blurRadius: 3 + (animation.value * 4),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
