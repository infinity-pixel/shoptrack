import 'package:flutter/material.dart';

/// Scalable version of the supplied list/scroll artwork. Uses the navigation
/// bar's IconTheme so every theme controls both selected and unselected colors.
class ListsNavigationIcon extends StatelessWidget {
  const ListsNavigationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    return SizedBox.square(
      dimension: theme.size ?? 24,
      child: CustomPaint(
        painter: ListsNavigationPainter(theme.color ?? Colors.black),
      ),
    );
  }
}

class ListsNavigationPainter extends CustomPainter {
  const ListsNavigationPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 512, size.height / 512);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Keep the rolled right edge and interrupted lines of the reference.
    final outline = Path()
      ..moveTo(410, 12)
      ..lineTo(104, 12)
      ..cubicTo(76, 12, 59, 34, 59, 62)
      ..lineTo(59, 482)
      ..quadraticBezierTo(59, 500, 78, 500)
      ..lineTo(374, 500)
      ..lineTo(374, 54)
      ..cubicTo(374, 30, 387, 12, 410, 12)
      ..cubicTo(438, 12, 453, 31, 453, 56)
      ..lineTo(453, 213)
      ..moveTo(453, 245)
      ..lineTo(453, 324)
      ..quadraticBezierTo(453, 347, 431, 347)
      ..lineTo(374, 347);
    canvas.drawPath(outline, stroke);

    for (final y in [89.0, 173.0, 257.0, 341.0, 425.0]) {
      canvas.drawCircle(Offset(123, y), 18, stroke);
    }
    final lines = Path()
      ..moveTo(183, 89)
      ..lineTo(197, 89)
      ..moveTo(228, 89)
      ..lineTo(330, 89)
      ..moveTo(183, 173)
      ..lineTo(330, 173)
      ..moveTo(183, 257)
      ..lineTo(285, 257)
      ..moveTo(315, 257)
      ..lineTo(330, 257)
      ..moveTo(183, 341)
      ..lineTo(330, 341)
      ..moveTo(183, 425)
      ..lineTo(330, 425);
    canvas.drawPath(lines, stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(ListsNavigationPainter oldDelegate) =>
      oldDelegate.color != color;
}
