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
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: config.baseColor ?? Theme.of(context).colorScheme.surface,
          ),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: config.opacity,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
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
