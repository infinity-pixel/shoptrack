import 'package:flutter/material.dart';
import 'package:shoptrack/core/localization/shoptrack_text.dart';

import '../theme/theme_presets.dart';

/// Requires a short, deliberate scroll before changing FAB width.
class FabScrollIntent {
  FabScrollIntent({this.threshold = 96});

  final double threshold;
  double _distance = 0;
  bool? _towardStart;

  bool? update(double delta, {required bool atStart}) {
    if (atStart) {
      reset();
      return null; // Boundary contact/bounce is not a new scroll intent.
    }
    if (!delta.isFinite || delta == 0) return null;
    final towardStart = delta < 0;
    if (_towardStart != towardStart) _distance = 0;
    _towardStart = towardStart;
    _distance += delta.abs();
    if (_distance < threshold) return null;
    _distance = 0;
    return !towardStart;
  }

  void reset() {
    _distance = 0;
    _towardStart = null;
  }
}

/// Lets the button finish widening before its label appears.
class DelayedExtendedFab extends StatefulWidget {
  const DelayedExtendedFab({
    super.key,
    required this.expanded,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.tooltip,
  });

  final bool expanded;
  final VoidCallback onPressed;
  final Widget icon;
  final String label;
  final String? tooltip;

  @override
  State<DelayedExtendedFab> createState() => _DelayedExtendedFabState();
}

class _DelayedExtendedFabState extends State<DelayedExtendedFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 260),
    value: widget.expanded ? 1 : 0,
  );

  @override
  void didUpdateWidget(covariant DelayedExtendedFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded != widget.expanded) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _motion.value = widget.expanded ? 1 : 0;
      } else {
        widget.expanded ? _motion.forward() : _motion.reverse();
      }
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final background =
        theme.floatingActionButtonTheme.backgroundColor ??
        colors.primaryContainer;
    final foreground =
        theme.floatingActionButtonTheme.foregroundColor ??
        colors.onPrimaryContainer;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _motion,
        builder: (context, child) {
          final width = Curves.easeInOutCubic.transform(_motion.value);
          final opacity = const Interval(
            0.55,
            1,
            curve: Curves.easeOut,
          ).transform(_motion.value);
          return Semantics(
            button: true,
            label: shopTr(context, widget.tooltip ?? widget.label),
            child: Tooltip(
              message: shopTr(context, widget.tooltip ?? widget.label),
              child: Material(
                color: background,
                elevation: 6,
                borderRadius: BorderRadius.circular(28),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: widget.onPressed,
                  child: ExcludeSemantics(
                    child: IconTheme(
                      data: IconThemeData(color: foreground),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: Center(child: widget.icon),
                          ),
                          ClipRect(
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              widthFactor: width,
                              heightFactor: 1,
                              child: Opacity(
                                opacity: opacity,
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    end: 14,
                                  ),
                                  child: Text(
                                    widget.label,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: foreground,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A compact calendar glyph with an explicit add affordance.
class CalendarAddIcon extends StatelessWidget {
  const CalendarAddIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = ShopTrackThemeTokens.of(context).palette;
    return SizedBox(
      width: 26,
      height: 26,
      child: Stack(
        children: [
          const Icon(Icons.calendar_month_outlined, size: 24),
          PositionedDirectional(
            end: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.onPrimary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, size: 12, color: palette.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// The Lists FAB keeps adding items primary and reveals one optional action.
class ShoppingSplitFab extends StatefulWidget {
  const ShoppingSplitFab({
    super.key,
    required this.expanded,
    required this.onAddPressed,
    required this.onSharePressed,
  });

  final bool expanded;
  final VoidCallback onAddPressed;
  final VoidCallback onSharePressed;

  @override
  State<ShoppingSplitFab> createState() => _ShoppingSplitFabState();
}

class _ShoppingSplitFabState extends State<ShoppingSplitFab>
    with TickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 170),
  );
  late final AnimationController _expansion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 260),
    value: widget.expanded ? 1 : 0,
  );

  bool _menuOpen = false;

  @override
  void didUpdateWidget(covariant ShoppingSplitFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded == widget.expanded) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _expansion.value = widget.expanded ? 1 : 0;
    } else {
      widget.expanded ? _expansion.forward() : _expansion.reverse();
    }
  }

  void _toggle() {
    final show = !_menuOpen;
    setState(() => _menuOpen = show);
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.value = show ? 1 : 0;
    } else {
      show ? _motion.forward() : _motion.reverse();
    }
  }

  void _close() {
    if (!_menuOpen) return;
    setState(() => _menuOpen = false);
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.value = 0;
    } else {
      _motion.reverse();
    }
  }

  void _add() {
    _close();
    widget.onAddPressed();
  }

  void _share() {
    _close();
    widget.onSharePressed();
  }

  @override
  void dispose() {
    _motion.dispose();
    _expansion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final background =
        theme.floatingActionButtonTheme.backgroundColor ??
        colors.primaryContainer;
    final foreground =
        theme.floatingActionButtonTheme.foregroundColor ??
        colors.onPrimaryContainer;
    final curve = CurvedAnimation(parent: _motion, curve: Curves.easeOutCubic);
    final slide = Tween<Offset>(
      begin: const Offset(0, .22),
      end: Offset.zero,
    ).animate(curve);
    final scale = Tween<double>(begin: .84, end: 1).animate(curve);

    // WillPopScope supports the app's Navigator-based shell as well as the
    // lightweight MaterialApp harnesses used by widget tests.
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (!_menuOpen) return true;
        _close();
        return false;
      },
      child: TapRegion(
        onTapOutside: (_) => _close(),
        child: RepaintBoundary(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizeTransition(
                sizeFactor: curve,
                alignment: AlignmentDirectional.bottomEnd.resolve(
                  Directionality.of(context),
                ),
                child: FadeTransition(
                  opacity: curve,
                  child: SlideTransition(
                    position: slide,
                    child: ScaleTransition(
                      scale: scale,
                      alignment: AlignmentDirectional.bottomEnd.resolve(
                        Directionality.of(context),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Semantics(
                          button: true,
                          label: shopTr(context, 'Share Your List'),
                          child: Material(
                            key: const ValueKey('share-fab-action'),
                            color: colors.surfaceContainerHigh,
                            shadowColor: Colors.black,
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(color: colors.outlineVariant),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: _share,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.ios_share_outlined,
                                      color: colors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: ShopText(
                                        'Share Your List',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              color: colors.onSurface,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Material(
                key: const ValueKey('split-main-fab'),
                color: background,
                elevation: 6,
                borderRadius: BorderRadius.circular(28),
                clipBehavior: Clip.antiAlias,
                child: IconTheme(
                  data: IconThemeData(color: foreground),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: shopTr(context, 'Add item'),
                        child: InkWell(
                          onTap: _add,
                          child: AnimatedBuilder(
                            animation: _expansion,
                            builder: (context, child) {
                              final width = Curves.easeInOutCubic.transform(
                                _expansion.value,
                              );
                              final opacity = const Interval(
                                0.55,
                                1,
                                curve: Curves.easeOut,
                              ).transform(_expansion.value);
                              return SizedBox(
                                height: 56,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 56,
                                      height: 56,
                                      child: Center(child: Icon(Icons.add)),
                                    ),
                                    ClipRect(
                                      child: Align(
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        widthFactor: width,
                                        child: Opacity(
                                          opacity: opacity,
                                          child: Padding(
                                            padding:
                                                const EdgeInsetsDirectional.only(
                                                  end: 14,
                                                ),
                                            child: ShopText(
                                              'Add Item',
                                              maxLines: 1,
                                              style: theme.textTheme.labelLarge
                                                  ?.copyWith(color: foreground),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 32,
                        child: VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: foreground.withValues(alpha: .28),
                        ),
                      ),
                      Tooltip(
                        message: shopTr(context, 'More actions'),
                        child: InkWell(
                          onTap: _toggle,
                          child: SizedBox(
                            width: 46,
                            height: 56,
                            child: Center(
                              child: AnimatedBuilder(
                                animation: _motion,
                                builder: (context, child) => Transform.rotate(
                                  angle: _motion.value * 3.141592653589793,
                                  child: child,
                                ),
                                child: const Icon(
                                  Icons.keyboard_arrow_up_rounded,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
