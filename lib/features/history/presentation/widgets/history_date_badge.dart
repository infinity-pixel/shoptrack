import 'package:flutter/material.dart';
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
    final palette = ShopTrackThemeTokens.of(context).palette;
    return SizedBox(
      width: 44,
      height: 48,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          border: Border.all(color: palette.secondary, width: 1.5),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Column(
          children: [
            Container(
              height: 7,
              decoration: BoxDecoration(
                color: palette.secondary,
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
                    '${date.day}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isFuture ? palette.planned : palette.onBackground,
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
    );
  }
}
