import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/design_system.dart';

export '../theme/design_system.dart' show ShopTrackMotion;

/// Gives an editor's keyboard a moment after its modal finishes entering.
/// The owning State must attach after its first frame and dispose this helper.
class ShopTrackEntranceFocus {
  ModalRoute<dynamic>? _route;
  Animation<double>? _animation;
  FocusNode? _node;
  Timer? _timer;
  bool _disposed = false;

  void attach(BuildContext context, FocusNode node) {
    if (_disposed) return;
    final route = ModalRoute.of(context);
    if (route == null) return;
    _route = route;
    _node = node;
    final animation = route.animation;
    if (MediaQuery.disableAnimationsOf(context)) {
      _requestFocus();
    } else if (animation == null ||
        animation.status == AnimationStatus.completed) {
      _scheduleFocus();
    } else {
      _animation = animation;
      animation.addStatusListener(_onAnimationStatus);
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _animation?.removeStatusListener(_onAnimationStatus);
    _animation = null;
    _scheduleFocus();
  }

  void _scheduleFocus() {
    _timer?.cancel();
    _timer = Timer(ShopTrackMotion.focusPause, _requestFocus);
  }

  void _requestFocus() {
    final activeFocus = FocusManager.instance.primaryFocus;
    if (activeFocus != _node && activeFocus?.context?.widget is EditableText) {
      return;
    }
    if (!_disposed &&
        _route?.isCurrent == true &&
        _node?.canRequestFocus == true) {
      _node?.requestFocus();
    }
  }

  void dispose() {
    _disposed = true;
    _animation?.removeStatusListener(_onAnimationStatus);
    _timer?.cancel();
  }
}

/// Keeps iOS's native back gesture while making Android page arrivals coherent.
class ShopTrackPageTransitionsBuilder extends PageTransitionsBuilder {
  const ShopTrackPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context) || route.isFirst) return child;
    final direction = Directionality.of(context) == TextDirection.rtl
        ? -1.0
        : 1.0;
    final curved = animation.drive(CurveTween(curve: Curves.easeInOutCubic));
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(.045 * direction, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

Future<T?> showShopDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) => showDialog<T>(
  context: context,
  builder: builder,
  barrierDismissible: barrierDismissible,
  useRootNavigator: useRootNavigator,
  animationStyle: ShopTrackMotion.dialogStyle(context),
);

Future<T?> showShopBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool? showDragHandle,
  Color? backgroundColor,
  bool? requestFocus,
}) => showModalBottomSheet<T>(
  context: context,
  builder: builder,
  isScrollControlled: isScrollControlled,
  showDragHandle: showDragHandle,
  backgroundColor: backgroundColor,
  sheetAnimationStyle: ShopTrackMotion.sheetStyle(context),
  requestFocus: requestFocus,
);
