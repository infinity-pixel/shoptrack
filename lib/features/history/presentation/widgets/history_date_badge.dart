import 'package:flutter/material.dart';
import 'package:shoptrack/core/calendar/shop_calendar.dart';
import '../../../../core/theme/theme_presets.dart';

/// The same date marker is used in History and its search results.
class HistoryDateBadge extends StatelessWidget {
  const HistoryDateBadge({
    super.key,
    required this.date,
    this.isFuture = false,
  });
  final DateTime date;
  final bool isFuture;
  @override
  Widget build(BuildContext context) {
    final tokens = ShopTrackThemeTokens.of(context);
    final palette = tokens.palette;
    final calendarAccent = tokens.calendarAccent ?? palette.secondary;
    return SizedBox(
      width: 44,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: 5,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: calendarAccent, width: 1.5),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Column(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: calendarAccent,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(5),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          shopDate(context, date, 'd'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isFuture
                                ? palette.planned
                                : palette.onBackground,
                            fontSize: 24,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final alignment in [Alignment.topLeft, Alignment.topRight])
            Align(
              alignment: alignment,
              child: Container(
                key: ValueKey(
                  alignment == Alignment.topLeft
                      ? 'calendar-binding-left'
                      : 'calendar-binding-right',
                ),
                width: 4,
                height: 11,
                margin: EdgeInsets.only(
                  left: alignment == Alignment.topLeft ? 9 : 0,
                  right: alignment == Alignment.topRight ? 9 : 0,
                ),
                decoration: BoxDecoration(
                  color: calendarAccent,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: palette.surface, width: .7),
                ),
              ),
            ),
          Positioned(
            left: 14,
            right: 14,
            top: 5,
            height: 10,
            child: ExcludeSemantics(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  shopDate(context, date, 'MMM').toUpperCase(),
                  style: TextStyle(
                    fontSize: 7,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: palette.onSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
