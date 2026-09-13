import 'dart:async';

import 'package:flutter/material.dart';

/// Keeps FAB reactions intentional: tiny scroll reversals are ignored and
/// programmatic scrolling does not reshape the button.
class ScrollAwareFabController extends ChangeNotifier {
  ScrollAwareFabController({
    this.travelThreshold = 32,
    this.settleDelay = const Duration(milliseconds: 110),
  });

  final double travelThreshold;
  final Duration settleDelay;

  bool _isExpanded = true;
  bool _isUserDragging = false;
  double _travel = 0;
  int _direction = 0;
  Timer? _settleTimer;

  bool get isExpanded => _isExpanded;

  bool handleNotification(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification is ScrollStartNotification) {
      _isUserDragging = notification.dragDetails != null;
      _travel = 0;
      _direction = 0;
      _settleTimer?.cancel();
    } else if (notification is ScrollUpdateNotification &&
        _isUserDragging &&
        notification.dragDetails != null) {
      final delta = notification.scrollDelta ?? 0;
      if (delta.abs() < 0.5) return false;
      final direction = delta > 0 ? 1 : -1;
      if (_direction != direction) {
        _direction = direction;
        _travel = 0;
        _settleTimer?.cancel();
      }
      _travel += delta.abs();
      if (_travel >= travelThreshold) {
        _scheduleState(direction < 0);
        _travel = 0;
      }
    } else if (notification is ScrollEndNotification) {
      _isUserDragging = false;
      _travel = 0;
      _direction = 0;
    }
    return false;
  }

  void _scheduleState(bool expanded) {
    if (_isExpanded == expanded) return;
    if (_settleTimer?.isActive ?? false) return;
    _settleTimer = Timer(settleDelay, () {
      if (_isExpanded == expanded) return;
      _isExpanded = expanded;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    super.dispose();
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
                                  padding: const EdgeInsets.only(right: 20),
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
