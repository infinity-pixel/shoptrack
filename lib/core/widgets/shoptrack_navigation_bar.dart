import 'package:flutter/material.dart';

/// Shared by the main tabs and History Search, including interaction states.
class ShopTrackNavigationBar extends StatelessWidget {
  const ShopTrackNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _labels = ['Lists', 'History', 'Profile'];
  static const _outlinedIcons = [
    Icons.list_alt_outlined,
    Icons.watch_later_outlined,
    Icons.person_outlined,
  ];
  static const _filledIcons = [
    Icons.list_alt_rounded,
    Icons.watch_later_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
    ),
    child: BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: [
        for (var i = 0; i < _labels.length; i++)
          BottomNavigationBarItem(
            label: _labels[i],
            icon: _NavigationIcon(
              index: i,
              selected: i == currentIndex,
              outlinedIcon: _outlinedIcons[i],
              filledIcon: _filledIcons[i],
            ),
          ),
      ],
    ),
  );
}

class _NavigationIcon extends StatelessWidget {
  const _NavigationIcon({
    required this.index,
    required this.selected,
    required this.outlinedIcon,
    required this.filledIcon,
  });

  final int index;
  final bool selected;
  final IconData outlinedIcon;
  final IconData filledIcon;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 180);

    return AnimatedSlide(
      offset: selected && !reduceMotion ? const Offset(0, -0.04) : Offset.zero,
      duration: duration,
      curve: Curves.easeOutCubic,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(animation),
            child: child,
          ),
        ),
        child: Icon(
          selected ? filledIcon : outlinedIcon,
          key: ValueKey(
            'navigation-icon-$index-${selected ? 'filled' : 'outline'}',
          ),
          size: 25,
        ),
      ),
    );
  }
}
