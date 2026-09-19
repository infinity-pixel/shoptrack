import 'package:flutter/material.dart';

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
            label: widget.tooltip ?? widget.label,
            child: Tooltip(
              message: widget.tooltip ?? widget.label,
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
                              alignment: Alignment.centerLeft,
                              widthFactor: width,
                              heightFactor: 1,
                              child: Opacity(
                                opacity: opacity,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 14),
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
  const CalendarAddIcon({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.calendar_today_outlined, size: size - 2),
          Positioned(
            right: -3,
            bottom: -3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: IconTheme.of(context).color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                size: size * .48,
                color: Theme.of(context).colorScheme.surface,
              ),
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
    required this.onAddPressed,
    required this.onSharePressed,
  });

  final VoidCallback onAddPressed;
  final VoidCallback onSharePressed;

  @override
  State<ShoppingSplitFab> createState() => _ShoppingSplitFabState();
}

class _ShoppingSplitFabState extends State<ShoppingSplitFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 170),
  );

  bool get _open => _motion.value > .5;

  void _toggle() {
    final show = !_open;
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.value = show ? 1 : 0;
      setState(() {});
    } else {
      show ? _motion.forward() : _motion.reverse();
    }
  }

  void _share() {
    _motion.value = 0;
    widget.onSharePressed();
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
    final curve = CurvedAnimation(parent: _motion, curve: Curves.easeOutCubic);

    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizeTransition(
            sizeFactor: curve,
            alignment: Alignment.bottomCenter,
            child: FadeTransition(
              opacity: curve,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Semantics(
                  button: true,
                  label: 'Share Your List',
                  child: Material(
                    color: background,
                    elevation: 5,
                    borderRadius: BorderRadius.circular(24),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _share,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.ios_share_outlined,
                              color: foreground,
                              size: 20,
                            ),
                            const SizedBox(width: 9),
                            Flexible(
                              child: Text(
                                'Share Your List',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: foreground,
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
          Material(
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
                    message: 'Add item',
                    child: InkWell(
                      onTap: widget.onAddPressed,
                      child: SizedBox(
                        height: 56,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add),
                              const SizedBox(width: 8),
                              Text(
                                'Add Item',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: foreground,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                    message: 'More actions',
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
                            child: const Icon(Icons.keyboard_arrow_up_rounded),
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
    );
  }
}
