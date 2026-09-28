import 'package:flutter/material.dart';
import '../widgets/shoptrack_motion.dart';
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
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : ShopTrackMotion.sheet;
    Alignment directionAware(Alignment alignment) =>
        isRtl ? Alignment(-alignment.x, alignment.y) : alignment;
    // Keep the child in the same tree position when switching brightness.
    // Replacing Stack with another wrapper would reset the active tab/editor.
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeInOutCubic,
            color: config.baseColor ?? Theme.of(context).colorScheme.surface,
          ),
        ),
        Positioned.fill(
          child: AnimatedOpacity(
            duration: duration,
            curve: Curves.easeInOutCubic,
            opacity: dark ? 1 : config.opacity,
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeInOutCubic,
              decoration: BoxDecoration(
                gradient: dark
                    ? darkEdgeGradient(context)
                    : LinearGradient(
                        colors: config.gradientColors,
                        begin: directionAware(config.begin),
                        end: directionAware(config.end),
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
