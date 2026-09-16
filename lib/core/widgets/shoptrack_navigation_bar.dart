import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'lists_navigation_icon.dart';

/// Shared by the main tabs and History Search, including interaction states.
class ShopTrackNavigationBar extends StatelessWidget {
  const ShopTrackNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });
  final int currentIndex;
  final ValueChanged<int> onTap;
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
        for (var i = 0; i < 3; i++)
          BottomNavigationBarItem(
            label: const ['Lists', 'History', 'Profile'][i],
            icon: _NavigationArtwork(index: i, selected: i == currentIndex),
          ),
      ],
    ),
  );
}

class _NavigationArtwork extends StatelessWidget {
  const _NavigationArtwork({required this.index, required this.selected});
  final int index;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: selected ? 1 : 0),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Transform.translate(
        offset: Offset(0, reduceMotion ? 0 : -value),
        child: Transform.scale(
          scale: reduceMotion ? 1 : .96 + .04 * value,
          child: index == 0
              ? ListsNavigationIcon(fill: value)
              : SizedBox.square(
                  dimension: IconTheme.of(context).size ?? 24,
                  child: CustomPaint(
                    painter: _TabPainter(
                      index,
                      IconTheme.of(context).color ??
                          Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.surface,
                      value,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Vector interpretations of the supplied account-settings and history artwork.
/// Inactive states outline the shapes; active states fill the same geometry.
class _TabPainter extends CustomPainter {
  const _TabPainter(this.index, this.ink, this.surface, this.fill);
  final int index;
  final Color ink, surface;
  final double fill;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 512, size.height / 512);
    final pen = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 27
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final body = Paint()..color = ink.withValues(alpha: fill);
    if (index == 2) {
      final gear = Path();
      for (var i = 0; i < 64; i++) {
        final radius = const [
          196.0,
          196.0,
          238.0,
          238.0,
          238.0,
          238.0,
          196.0,
          196.0,
        ][i % 8];
        final angle = i * math.pi / 32 - math.pi / 2;
        final x = 256 + radius * math.cos(angle),
            y = 256 + radius * math.sin(angle);
        if (i == 0) {
          gear.moveTo(x, y);
        } else {
          gear.lineTo(x, y);
        }
      }
      gear.close();
      canvas.drawPath(gear, body);
      canvas.drawPath(gear, pen);
      canvas.drawCircle(const Offset(256, 256), 152, Paint()..color = surface);
      canvas.drawCircle(const Offset(256, 256), 152, pen);
      canvas.drawCircle(const Offset(256, 213), 47, body);
      canvas.drawCircle(const Offset(256, 213), 47, pen);
      final shoulders = Path()
        ..moveTo(161, 354)
        ..cubicTo(177, 264, 335, 264, 351, 354)
        ..quadraticBezierTo(256, 421, 161, 354)
        ..close();
      canvas.drawPath(shoulders, body);
      canvas.drawPath(shoulders, pen);
    } else {
      canvas.drawCircle(const Offset(228, 231), 176, body);
      canvas.drawArc(
        const Rect.fromLTWH(26, 30, 408, 408),
        -2.15,
        4.95,
        false,
        pen,
      );
      final arrow = Path()
        ..moveTo(151, 28)
        ..lineTo(97, 112)
        ..lineTo(200, 112)
        ..close();
      canvas.drawPath(arrow, Paint()..color = surface);
      canvas.drawPath(arrow, body);
      canvas.drawPath(arrow, pen);
      pen.color = Color.lerp(ink, surface, fill)!;
      canvas.drawPath(
        Path()
          ..moveTo(228, 127)
          ..lineTo(228, 240)
          ..lineTo(138, 240),
        pen,
      );
      pen.color = ink;
      canvas.drawCircle(const Offset(350, 350), 126, Paint()..color = surface);
      canvas.drawCircle(const Offset(350, 350), 126, body);
      canvas.drawCircle(const Offset(350, 350), 126, pen);
      pen.color = Color.lerp(ink, surface, fill)!;
      canvas.drawCircle(const Offset(350, 350), 88, pen);
      pen.color = ink;
      canvas.drawLine(
        const Offset(443, 443),
        const Offset(490, 490),
        pen..strokeWidth = 35,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TabPainter old) =>
      old.index != index ||
      old.ink != ink ||
      old.surface != surface ||
      old.fill != fill;
}
