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
    _settleTimer?.cancel();
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

class _DelayedExtendedFabState extends State<DelayedExtendedFab> {
  Timer? _labelTimer;
  late bool _showLabel;

  @override
  void initState() {
    super.initState();
    _showLabel = widget.expanded;
  }

  @override
  void didUpdateWidget(covariant DelayedExtendedFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded == widget.expanded) return;
    _labelTimer?.cancel();
    if (!widget.expanded) {
      _showLabel = false;
    } else {
      _labelTimer = Timer(const Duration(milliseconds: 135), () {
        if (mounted) setState(() => _showLabel = true);
      });
    }
  }

  @override
  void dispose() {
    _labelTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: widget.onPressed,
      isExtended: widget.expanded,
      tooltip: widget.tooltip,
      clipBehavior: Clip.hardEdge,
      icon: widget.icon,
      label: AnimatedSwitcher(
        duration: const Duration(milliseconds: 120),
        child: _showLabel
            ? Text(widget.label, key: const ValueKey('fab-label'))
            : const SizedBox.shrink(key: ValueKey('fab-label-hidden')),
      ),
    );
  }
}
