import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme_presets.dart';

class RecordHero extends StatelessWidget {
  const RecordHero({super.key, required this.date, required this.onBack});
  final DateTime date;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) {
    final tokens = ShopTrackThemeTokens.of(context);
    final p = tokens.palette;
    return SizedBox(
      width: double.infinity,
      height:
          112 + (MediaQuery.textScalerOf(context).scale(24) - 24).clamp(0, 70),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (tokens.headerArtworkPath != null)
            Image.asset(tokens.headerArtworkPath!, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  p.surface.withValues(alpha: .85),
                  p.surface.withValues(alpha: .1),
                ],
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: 2,
            child: IconButton(
              tooltip: 'Back to History',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              style: IconButton.styleFrom(
                backgroundColor: p.surface.withValues(alpha: .85),
                foregroundColor: p.onBackground,
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 10,
            right: 16,
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
                        DateFormat.EEEE().format(date).toUpperCase(),
                        style: TextStyle(
                          color: p.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('d MMM').format(date),
                        style: TextStyle(
                          color: p.onBackground,
                          fontSize: 24,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${date.year}',
                        style: TextStyle(color: p.textSecondary, fontSize: 12),
                      ),
                    ],
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
