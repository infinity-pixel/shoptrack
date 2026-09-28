import 'package:flutter/material.dart';

import 'shoptrack_motion.dart';

/// Crossfades scenery without changing the surrounding hero's layout or text.
class ShopTrackHeroArtwork extends StatelessWidget {
  const ShopTrackHeroArtwork({
    super.key,
    required this.path,
    required this.alignment,
  });

  final String? path;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : ShopTrackMotion.sheet;
    return RepaintBoundary(
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        child: SizedBox.expand(
          key: ValueKey((path, Directionality.of(context))),
          child: path == null
              ? const SizedBox.expand()
              : Image.asset(
                  path!,
                  fit: BoxFit.cover,
                  alignment: alignment,
                  matchTextDirection: true,
                ),
        ),
      ),
    );
  }
}
