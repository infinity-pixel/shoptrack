import 'package:flutter/material.dart';
import '../../../../core/localization/shoptrack_text.dart';
import 'package:flutter/services.dart';
import 'package:shoptrack/core/calendar/shop_calendar.dart';
import '../../../../core/theme/theme_presets.dart';

class RecordHero extends StatelessWidget {
  const RecordHero({super.key, required this.date, required this.onBack});
  final DateTime date;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) {
    final tokens = ShopTrackThemeTokens.of(context);
    final p = tokens.palette;
    final topInset = MediaQuery.paddingOf(context).top;
    final darkIcons = p.surface.computeLuminance() > 0.5;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: darkIcons ? Brightness.dark : Brightness.light,
        statusBarBrightness: darkIcons ? Brightness.light : Brightness.dark,
      ),
      child: SizedBox(
        width: double.infinity,
        height:
            topInset +
            112 +
            (MediaQuery.textScalerOf(context).scale(24) - 24).clamp(0, 70),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (tokens.headerArtworkPath != null)
              Image.asset(
                tokens.headerArtworkPath!,
                fit: BoxFit.cover,
                matchTextDirection: true,
                // Keep Midnight's moon and right-hand branches in short heroes.
                alignment: darkIcons
                    ? Alignment.center
                    : const Alignment(0, -0.5),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                  colors: [
                    p.surface.withValues(alpha: darkIcons ? .85 : .45),
                    p.surface.withValues(alpha: darkIcons ? .1 : 0),
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              start: 8,
              top: topInset + 2,
              child: IconButton(
                tooltip: shopTr(context, 'Back to History'),
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: p.surface.withValues(alpha: .85),
                  foregroundColor: p.onBackground,
                ),
              ),
            ),
            PositionedDirectional(
              start: 20,
              bottom: 10,
              end: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(Icons.event_note_outlined, color: p.secondary, size: 28),
                  const SizedBox(width: 10),
                  Container(width: 2, height: 54, color: p.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shopDate(context, date, 'EEEE').toUpperCase(),
                          style: TextStyle(
                            color: p.secondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          shopDate(context, date, 'd MMM'),
                          style: TextStyle(
                            color: p.onBackground,
                            fontSize: 24,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          shopDate(context, date, 'yyyy'),
                          style: TextStyle(
                            color: p.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
