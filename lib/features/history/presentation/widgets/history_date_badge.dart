import 'package:flutter/material.dart';
import 'package:shoptrack/core/calendar/shop_calendar.dart';
import 'package:shoptrack/core/localization/shoptrack_text.dart';
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
    // A trailing literal space selects an explicit date pattern: intl treats
    // bare MMM as a skeleton and may substitute a longer standalone name.
    final month = shopDate(context, date, 'MMM ').trim().toUpperCase();
    // Arabic has no generally useful abbreviated month names. Long Hijri
    // names in other languages also belong above the rings, never as numbers.
    final aboveRings = shopIsArabic(context) || month.characters.length > 4;
    final monthLabel = aboveRings ? shopDate(context, date, 'MMMM') : month;
    return Tooltip(
      message: shopDate(context, date, 'd MMMM y'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (aboveRings) ...[
            SizedBox(
              width: 64,
              child: Text(
                monthLabel,
                key: const ValueKey('calendar-month-above'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: calendarAccent,
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 2),
          ],
          SizedBox(
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
                                shopNumber(
                                  context,
                                  ShopCalendarScope.of(context).parts(date).day,
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isFuture
                                      ? palette.planned
                                      : palette.onBackground,
                                  fontSize: 24,
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
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
                if (!aboveRings)
                  Positioned(
                    left: 14,
                    right: 14,
                    top: 5,
                    height: 10,
                    child: ExcludeSemantics(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          monthLabel,
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
          ),
        ],
      ),
    );
  }
}
