import 'package:flutter/material.dart';
import 'theme_presets.dart';

/// A widget that renders a subtle atmospheric background based on the current theme.
class AtmosphericBackground extends StatelessWidget {
  final Widget child;
  final AtmosphericConfig config;

  const AtmosphericBackground({
    super.key,
    required this.child,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Keep the child in the same tree position when switching brightness.
    // Replacing Stack with another wrapper would reset the active tab/editor.
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: config.baseColor ?? Theme.of(context).colorScheme.surface,
          ),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: dark ? 1 : config.opacity,
            child: Container(
              decoration: BoxDecoration(
                gradient: dark
                    ? darkEdgeGradient(context)
                    : LinearGradient(
                        colors: config.gradientColors,
                        begin: config.begin,
                        end: config.end,
                      ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// A quiet edge tint: the central 96 percent stays a single dark surface.
LinearGradient darkEdgeGradient(BuildContext context) {
  final p = ShopTrackThemeTokens.of(context).palette;
  final edge = Color.lerp(p.background, p.primary, .035)!;
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [edge, p.background, p.background, edge],
    stops: const [0, .02, .98, 1],
  );
}
