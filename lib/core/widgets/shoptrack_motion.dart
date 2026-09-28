import 'package:flutter/material.dart';

import '../theme/design_system.dart';

export '../theme/design_system.dart' show ShopTrackMotion;

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
